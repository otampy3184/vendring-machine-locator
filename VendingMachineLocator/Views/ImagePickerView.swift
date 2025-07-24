//
//  ImagePickerView.swift
//  VendingMachineLocator
//
//  Created by Claude on 2025/01/23.
//

import SwiftUI
import UIKit
import PhotosUI

/// 画像選択UI - カメラ・フォトライブラリ対応
struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    let sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = false // Exif情報保持のため編集無効
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // 更新処理は不要
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView
        
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

/// iOS 16+ PhotosPicker対応版
@available(iOS 16.0, *)
struct ModernImagePickerView: View {
    @Binding var selectedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    var body: some View {
        PhotosPicker(
            selection: $selectedPhotoItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            HStack {
                Image(systemName: "photo.on.rectangle")
                Text("フォトライブラリから選択")
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(8)
        }
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                if let newItem = newItem,
                   let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        selectedImage = image
                    }
                }
            }
        }
    }
}

/// 画像選択オプション表示シート
struct ImageSelectionSheet: View {
    @Binding var selectedImage: UIImage?
    let onImageSelected: (UIImage) -> Void
    let onCancel: () -> Void
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    
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
                    // カメラボタン
                    Button(action: {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            showingCamera = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text("カメラで撮影")
                                    .font(.headline)
                                Text("新しい写真を撮影します")
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
                    .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                    
                    // フォトライブラリボタン
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
        .sheet(isPresented: $showingCamera) {
            ImagePickerView(
                selectedImage: $selectedImage,
                isPresented: $showingCamera,
                sourceType: .camera
            )
            .onDisappear {
                if let image = selectedImage {
                    onImageSelected(image)
                }
            }
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
    ImageSelectionSheet(
        selectedImage: .constant(nil),
        onImageSelected: { _ in },
        onCancel: { }
    )
}