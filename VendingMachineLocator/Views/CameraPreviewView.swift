//
//  CameraPreviewView.swift
//  VendingMachineLocator
//
//  Created by Claude on 2025/01/23.
//

import SwiftUI
import AVFoundation
import Vision
import UIKit

/// リアルタイム自動販売機検出機能付きカメラプレビュー
struct CameraPreviewView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    @Binding var detectedBounds: CGRect?
    @Binding var isDetecting: Bool
    let onCapture: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        uiViewController.isDetectionEnabled = isDetecting
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CameraViewControllerDelegate {
        let parent: CameraPreviewView
        
        init(_ parent: CameraPreviewView) {
            self.parent = parent
        }
        
        func cameraViewController(_ controller: CameraViewController, didDetectBounds bounds: CGRect?) {
            parent.detectedBounds = bounds
        }
        
        func cameraViewController(_ controller: CameraViewController, didCaptureImage image: UIImage) {
            parent.selectedImage = image
            parent.onCapture(image)
            parent.isPresented = false
        }
        
        func cameraViewControllerDidCancel(_ controller: CameraViewController) {
            parent.isPresented = false
        }
    }
}

// MARK: - CameraViewController

protocol CameraViewControllerDelegate: AnyObject {
    func cameraViewController(_ controller: CameraViewController, didDetectBounds bounds: CGRect?)
    func cameraViewController(_ controller: CameraViewController, didCaptureImage image: UIImage)
    func cameraViewControllerDidCancel(_ controller: CameraViewController)
}

class CameraViewController: UIViewController {
    weak var delegate: CameraViewControllerDelegate?
    
    var isDetectionEnabled = true {
        didSet {
            if isDetectionEnabled != oldValue {
                updateDetectionState()
            }
        }
    }
    
    // MARK: - Camera Components
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var videoOutput: AVCaptureVideoDataOutput!
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    // MARK: - Vision Components
    private var visionRequests = [VNRequest]()
    private let visionQueue = DispatchQueue(label: "vision.processing.queue")
    
    // MARK: - UI Components
    private let captureButton = UIButton(type: .custom)
    private let cancelButton = UIButton(type: .system)
    private let detectionOverlay = CAShapeLayer()
    private let detectionToggle = UISwitch()
    private let detectionLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
        setupVision()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sessionQueue.async {
            self.captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sessionQueue.async {
            self.captureSession.stopRunning()
        }
    }
    
    // MARK: - Setup Methods
    
    private func setupCamera() {
        captureSession.sessionPreset = .photo
        
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: backCamera) else {
            print("Failed to setup camera input")
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        // Preview layer setup
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        // Video output for Vision processing
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: visionQueue)
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        // Photo output for capture
        let photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
    }
    
    private func setupUI() {
        // Detection overlay
        detectionOverlay.fillColor = UIColor.clear.cgColor
        detectionOverlay.strokeColor = UIColor.purple.cgColor
        detectionOverlay.lineWidth = 3.0
        detectionOverlay.cornerRadius = 8.0
        previewLayer.addSublayer(detectionOverlay)
        
        // Capture button
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = 35
        captureButton.layer.borderWidth = 5
        captureButton.layer.borderColor = UIColor.systemBlue.cgColor
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
        view.addSubview(captureButton)
        
        // Cancel button
        cancelButton.setTitle("キャンセル", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        cancelButton.layer.cornerRadius = 8
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        view.addSubview(cancelButton)
        
        // Detection toggle
        detectionToggle.isOn = isDetectionEnabled
        detectionToggle.onTintColor = .purple
        detectionToggle.translatesAutoresizingMaskIntoConstraints = false
        detectionToggle.addTarget(self, action: #selector(detectionToggleChanged), for: .valueChanged)
        view.addSubview(detectionToggle)
        
        // Detection label
        detectionLabel.text = "自動検出"
        detectionLabel.textColor = .white
        detectionLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        detectionLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        detectionLabel.layer.cornerRadius = 6
        detectionLabel.textAlignment = .center
        detectionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(detectionLabel)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Capture button
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70),
            
            // Cancel button
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            cancelButton.widthAnchor.constraint(equalToConstant: 80),
            cancelButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Detection toggle
            detectionToggle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            detectionToggle.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            
            // Detection label
            detectionLabel.trailingAnchor.constraint(equalTo: detectionToggle.leadingAnchor, constant: -8),
            detectionLabel.centerYAnchor.constraint(equalTo: detectionToggle.centerYAnchor),
            detectionLabel.widthAnchor.constraint(equalToConstant: 60),
            detectionLabel.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    private func setupVision() {
        // Rectangle detection request for vending machines
        let rectangleRequest = VNDetectRectanglesRequest { [weak self] request, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.processVisionResults(request.results)
            }
        }
        
        rectangleRequest.minimumAspectRatio = 0.3
        rectangleRequest.maximumAspectRatio = 0.8
        rectangleRequest.minimumSize = 0.1
        rectangleRequest.minimumConfidence = 0.4
        
        visionRequests = [rectangleRequest]
    }
    
    // MARK: - Action Methods
    
    @objc private func captureButtonTapped() {
        guard let photoOutput = captureSession.outputs.compactMap({ $0 as? AVCapturePhotoOutput }).first else {
            return
        }
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @objc private func cancelButtonTapped() {
        delegate?.cameraViewControllerDidCancel(self)
    }
    
    @objc private func detectionToggleChanged() {
        isDetectionEnabled = detectionToggle.isOn
    }
    
    private func updateDetectionState() {
        detectionToggle.isOn = isDetectionEnabled
        if !isDetectionEnabled {
            DispatchQueue.main.async {
                self.clearDetectionOverlay()
            }
        }
    }
    
    // MARK: - Vision Processing
    
    private func processVisionResults(_ results: [Any]?) {
        clearDetectionOverlay()
        
        guard isDetectionEnabled,
              let rectangles = results as? [VNRectangleObservation],
              !rectangles.isEmpty else {
            delegate?.cameraViewController(self, didDetectBounds: nil)
            return
        }
        
        // Find the best detection (highest confidence)
        let bestRectangle = rectangles.max { $0.confidence < $1.confidence }!
        
        // Convert to layer coordinates
        let layerRect = previewLayer.layerRectConverted(fromMetadataOutputRect: bestRectangle.boundingBox)
        
        // Update overlay
        updateDetectionOverlay(with: layerRect)
        delegate?.cameraViewController(self, didDetectBounds: bestRectangle.boundingBox)
    }
    
    private func updateDetectionOverlay(with rect: CGRect) {
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 8.0)
        detectionOverlay.path = path.cgPath
        
        // Add pulsing animation
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.3
        animation.toValue = 0.8
        animation.duration = 1.0
        animation.autoreverses = true
        animation.repeatCount = .infinity
        detectionOverlay.add(animation, forKey: "pulse")
    }
    
    private func clearDetectionOverlay() {
        detectionOverlay.path = nil
        detectionOverlay.removeAllAnimations()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isDetectionEnabled else { return }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        do {
            try imageRequestHandler.perform(visionRequests)
        } catch {
            print("Vision processing error: \(error)")
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("Failed to capture photo: \(error?.localizedDescription ?? "Unknown error")")
            return
        }
        
        delegate?.cameraViewController(self, didCaptureImage: image)
    }
}

// MARK: - Enhanced ImageSelectionSheet with Camera Preview

struct EnhancedImageSelectionSheet: View {
    @Binding var selectedImage: UIImage?
    let onImageSelected: (UIImage) -> Void
    let onCancel: () -> Void
    @State private var showingCameraPreview = false
    @State private var showingPhotoLibrary = false
    @State private var detectedBounds: CGRect?
    @State private var isDetecting = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("画像を選択")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                Text("自動販売機の写真を選択してください")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 16) {
                    // Enhanced camera button with AI detection
                    Button(action: {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            showingCameraPreview = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "camera.viewfinder")
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text("AI検出カメラ")
                                    .font(.headline)
                                Text("自動販売機を自動検出して撮影")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.purple)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.purple, lineWidth: 1)
                        )
                    }
                    .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                    
                    // Photo library button
                    Button(action: {
                        showingPhotoLibrary = true
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text("フォトライブラリから選択")
                                    .font(.headline)
                                Text("既存の写真を選択します")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("画像選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("キャンセル") {
                        onCancel()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingCameraPreview) {
            CameraPreviewView(
                selectedImage: $selectedImage,
                isPresented: $showingCameraPreview,
                detectedBounds: $detectedBounds,
                isDetecting: $isDetecting,
                onCapture: onImageSelected
            )
        }
        .sheet(isPresented: $showingPhotoLibrary) {
            ImagePickerView(
                selectedImage: $selectedImage,
                isPresented: $showingPhotoLibrary,
                sourceType: .photoLibrary
            )
            .onDisappear {
                if let image = selectedImage {
                    onImageSelected(image)
                }
            }
        }
    }
}

#Preview {
    EnhancedImageSelectionSheet(
        selectedImage: .constant(nil),
        onImageSelected: { _ in },
        onCancel: { }
    )
}