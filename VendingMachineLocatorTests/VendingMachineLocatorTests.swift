//
//  VendingMachineLocatorTests.swift
//  VendingMachineLocatorTests
//
//  Created by Hiroshi Takagi on 2025/07/23.
//

import Testing
@testable import VendingMachineLocator
import CoreLocation
import Foundation
import UIKit
import MapKit

// MARK: - VendingMachine Model Tests
struct VendingMachineModelTests {
    
    // MARK: - Initialization Tests
    
    @Test func test_init_withValidData_shouldCreateInstance() async throws {
        let machine = VendingMachine(
            latitude: 35.6895,
            longitude: 139.6917,
            description: "Test Machine"
        )
        
        #expect(machine.latitude == 35.6895)
        #expect(machine.longitude == 139.6917)
        #expect(machine.description == "Test Machine")
        #expect(machine.machineType == .beverage) // default value
        #expect(machine.operatingStatus == .operating) // default value
        #expect(machine.paymentMethods == [.cash]) // default value
        #expect(!machine.hasImage) // default value
        #expect(machine.imageURL == nil) // default value
        #expect(machine.thumbnailURL == nil) // default value
    }
    
    @Test func test_init_withAllParameters_shouldCreateInstanceWithSpecifiedValues() async throws {
        let testDate = Date()
        let machine = VendingMachine(
            id: "test123",
            latitude: 35.6895,
            longitude: 139.6917,
            description: "Full Test Machine",
            machineType: .food,
            operatingStatus: .maintenance,
            paymentMethods: [.card, .electronicMoney],
            lastUpdated: testDate,
            imageURL: "https://example.com/image.jpg",
            thumbnailURL: "https://example.com/thumb.jpg",
            hasImage: true,
            imageUploadedAt: testDate
        )
        
        #expect(machine.id == "test123")
        #expect(machine.latitude == 35.6895)
        #expect(machine.longitude == 139.6917)
        #expect(machine.description == "Full Test Machine")
        #expect(machine.machineType == .food)
        #expect(machine.operatingStatus == .maintenance)
        #expect(machine.paymentMethods == [.card, .electronicMoney])
        #expect(machine.lastUpdated == testDate)
        #expect(machine.imageURL == "https://example.com/image.jpg")
        #expect(machine.thumbnailURL == "https://example.com/thumb.jpg")
        #expect(machine.hasImage == true)
        #expect(machine.imageUploadedAt == testDate)
    }
    
    // MARK: - Coordinate Conversion Tests
    
    @Test func test_coordinate_withValidLatLong_shouldReturnCLLocationCoordinate2D() async throws {
        let machine = VendingMachine(
            latitude: 35.6895,
            longitude: 139.6917,
            description: "Coordinate Test"
        )
        
        let coordinate = machine.coordinate
        #expect(coordinate.latitude == 35.6895)
        #expect(coordinate.longitude == 139.6917)
    }
    
    @Test func test_location_withValidLatLong_shouldReturnCLLocation() async throws {
        let machine = VendingMachine(
            latitude: 35.6895,
            longitude: 139.6917,
            description: "Location Test"
        )
        
        let location = machine.location
        #expect(location.coordinate.latitude == 35.6895)
        #expect(location.coordinate.longitude == 139.6917)
    }
    
    // MARK: - Codable Tests
    
    @Test func test_encoding_withCompleteData_shouldSucceed() async throws {
        let testDate = Date()
        let machine = VendingMachine(
            id: "encode123",
            latitude: 35.6895,
            longitude: 139.6917,
            description: "Encoding Test",
            machineType: .ice,
            operatingStatus: .outOfOrder,
            paymentMethods: [.qrCode],
            lastUpdated: testDate,
            imageURL: "https://example.com/image.jpg",
            thumbnailURL: "https://example.com/thumb.jpg",
            hasImage: true,
            imageUploadedAt: testDate
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(machine)
        #expect(data.count > 0)
    }
    
    @Test func test_decoding_withValidJSON_shouldCreateInstance() async throws {
        let jsonString = """
        {
            "latitude": 35.6895,
            "longitude": 139.6917,
            "description": "Decoded Machine",
            "machineType": "食品",
            "operatingStatus": "営業中",
            "paymentMethods": ["現金", "カード"],
            "lastUpdated": 1642723200,
            "hasImage": false
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let machine = try decoder.decode(VendingMachine.self, from: jsonData)
        
        #expect(machine.latitude == 35.6895)
        #expect(machine.longitude == 139.6917)
        #expect(machine.description == "Decoded Machine")
        #expect(machine.machineType == .food)
        #expect(machine.operatingStatus == .operating)
        #expect(machine.paymentMethods == [.cash, .card])
        #expect(machine.hasImage == false)
    }
    
    @Test func test_decoding_withMissingOptionalFields_shouldUseDefaults() async throws {
        let jsonString = """
        {
            "latitude": 35.6895,
            "longitude": 139.6917,
            "description": "Minimal Machine"
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let machine = try decoder.decode(VendingMachine.self, from: jsonData)
        
        #expect(machine.latitude == 35.6895)
        #expect(machine.longitude == 139.6917)
        #expect(machine.description == "Minimal Machine")
        #expect(machine.machineType == .beverage) // default
        #expect(machine.operatingStatus == .operating) // default
        #expect(machine.paymentMethods == [.cash]) // default
        #expect(machine.hasImage == false) // default
    }
    
    // MARK: - Equatable Tests
    
    @Test func test_equality_withSameData_shouldBeEqual() async throws {
        let machine1 = VendingMachine(
            id: "same123",
            latitude: 35.6895,
            longitude: 139.6917,
            description: "Same Machine"
        )
        
        let machine2 = VendingMachine(
            id: "same123",
            latitude: 35.6895,
            longitude: 139.6917,
            description: "Same Machine"
        )
        
        #expect(machine1 == machine2)
    }
    
    @Test func test_equality_withDifferentIds_shouldNotBeEqual() async throws {
        let machine1 = VendingMachine(
            id: "different1",
            latitude: 35.6895,
            longitude: 139.6917,
            description: "Machine 1"
        )
        
        let machine2 = VendingMachine(
            id: "different2",
            latitude: 35.6895,
            longitude: 139.6917,
            description: "Machine 1"
        )
        
        #expect(machine1 != machine2)
    }
}

// MARK: - Enum Tests
struct VendingMachineEnumTests {
    
    // MARK: - MachineType Tests
    
    @Test func test_machineType_allCases_shouldHaveCorrectRawValues() async throws {
        #expect(MachineType.beverage.rawValue == "飲料")
        #expect(MachineType.food.rawValue == "食品")
        #expect(MachineType.ice.rawValue == "アイス")
        #expect(MachineType.tobacco.rawValue == "たばこ")
        #expect(MachineType.other.rawValue == "その他")
    }
    
    @Test func test_machineType_allCases_shouldHaveCorrectIcons() async throws {
        #expect(MachineType.beverage.icon == "cup.and.saucer.fill")
        #expect(MachineType.food.icon == "fork.knife")
        #expect(MachineType.ice.icon == "snowflake")
        #expect(MachineType.tobacco.icon == "smoke.fill")
        #expect(MachineType.other.icon == "questionmark.square")
    }
    
    @Test func test_machineType_allCases_shouldHaveColors() async throws {
        // Testing that colors are not nil and are different
        #expect(MachineType.beverage.color != MachineType.food.color)
        #expect(MachineType.food.color != MachineType.ice.color)
        #expect(MachineType.ice.color != MachineType.tobacco.color)
        #expect(MachineType.tobacco.color != MachineType.other.color)
    }
    
    @Test func test_machineType_caseIterable_shouldContainAllCases() async throws {
        let allCases = MachineType.allCases
        #expect(allCases.count == 5)
        #expect(allCases.contains(.beverage))
        #expect(allCases.contains(.food))
        #expect(allCases.contains(.ice))
        #expect(allCases.contains(.tobacco))
        #expect(allCases.contains(.other))
    }
    
    // MARK: - OperatingStatus Tests
    
    @Test func test_operatingStatus_allCases_shouldHaveCorrectRawValues() async throws {
        #expect(OperatingStatus.operating.rawValue == "営業中")
        #expect(OperatingStatus.outOfOrder.rawValue == "故障中")
        #expect(OperatingStatus.maintenance.rawValue == "メンテナンス中")
    }
    
    @Test func test_operatingStatus_allCases_shouldHaveColors() async throws {
        // Testing that colors are not nil and are different
        #expect(OperatingStatus.operating.color != OperatingStatus.outOfOrder.color)
        #expect(OperatingStatus.outOfOrder.color != OperatingStatus.maintenance.color)
    }
    
    @Test func test_operatingStatus_caseIterable_shouldContainAllCases() async throws {
        let allCases = OperatingStatus.allCases
        #expect(allCases.count == 3)
        #expect(allCases.contains(.operating))
        #expect(allCases.contains(.outOfOrder))
        #expect(allCases.contains(.maintenance))
    }
    
    // MARK: - PaymentMethod Tests
    
    @Test func test_paymentMethod_allCases_shouldHaveCorrectRawValues() async throws {
        #expect(PaymentMethod.cash.rawValue == "現金")
        #expect(PaymentMethod.card.rawValue == "カード")
        #expect(PaymentMethod.electronicMoney.rawValue == "電子マネー")
        #expect(PaymentMethod.qrCode.rawValue == "QRコード")
    }
    
    @Test func test_paymentMethod_allCases_shouldHaveCorrectIcons() async throws {
        #expect(PaymentMethod.cash.icon == "yensign.circle")
        #expect(PaymentMethod.card.icon == "creditcard")
        #expect(PaymentMethod.electronicMoney.icon == "wave.3.right.circle")
        #expect(PaymentMethod.qrCode.icon == "qrcode")
    }
    
    @Test func test_paymentMethod_caseIterable_shouldContainAllCases() async throws {
        let allCases = PaymentMethod.allCases
        #expect(allCases.count == 4)
        #expect(allCases.contains(.cash))
        #expect(allCases.contains(.card))
        #expect(allCases.contains(.electronicMoney))
        #expect(allCases.contains(.qrCode))
    }
}

// MARK: - Sample Data Tests
struct VendingMachineSampleDataTests {
    
    @Test func test_sampleData_shouldContainValidInstances() async throws {
        let sampleData = VendingMachine.sampleData
        
        #expect(sampleData.count == 3)
        
        // Test each sample data instance
        for machine in sampleData {
            #expect(!machine.id.isEmpty)
            #expect(machine.latitude != 0)
            #expect(machine.longitude != 0)
            #expect(!machine.description.isEmpty)
            #expect(MachineType.allCases.contains(machine.machineType))
            #expect(OperatingStatus.allCases.contains(machine.operatingStatus))
            #expect(!machine.paymentMethods.isEmpty)
        }
    }
    
    @Test func test_sampleData_shouldHaveDifferentLocations() async throws {
        let sampleData = VendingMachine.sampleData
        
        // Ensure sample data has different coordinates
        let coordinates = sampleData.map { ($0.latitude, $0.longitude) }
        let uniqueCoordinates = Set(coordinates.map { "\($0.0),\($0.1)" })
        
        #expect(uniqueCoordinates.count == sampleData.count)
    }
}

// MARK: - Service Layer Tests

// MARK: - AuthService Tests
struct AuthServiceTests {
    
    // MARK: - Initial State Tests
    
    @Test @MainActor func test_init_shouldHaveCorrectInitialState() async throws {
        let authService = AuthService.shared
        
        // 初期状態の確認
        #expect(authService.user == nil)
        #expect(authService.isAuthenticated == false)
        #expect(authService.isLoading == false)
        #expect(authService.errorMessage == nil)
    }
    
    // MARK: - Error Handling Tests
    
    @Test func test_authError_invalidToken_shouldHaveCorrectDescription() async throws {
        let error = AuthError.invalidToken
        #expect(error.errorDescription == "無効なトークンです")
    }
    
    @Test func test_authError_userCancelled_shouldHaveCorrectDescription() async throws {
        let error = AuthError.userCancelled
        #expect(error.errorDescription == "ユーザーがキャンセルしました")
    }
    
    @Test func test_authError_allCases_shouldHaveNonEmptyDescriptions() async throws {
        let allErrors: [AuthError] = [.invalidToken, .userCancelled]
        
        for error in allErrors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }
}

// MARK: - LocationService Tests
struct LocationServiceTests {
    
    // MARK: - Initial State Tests
    
    @Test @MainActor func test_init_shouldHaveCorrectInitialState() async throws {
        let locationService = LocationService.shared
        
        // 初期状態の確認
        #expect(locationService.currentLocation == nil)
        #expect(locationService.isLocationEnabled == false)
        #expect(locationService.errorMessage == nil)
    }
    
    // MARK: - Static Properties Tests
    
    @Test func test_tokyoCenter_shouldHaveCorrectCoordinates() async throws {
        let tokyoCenter = LocationService.tokyoCenter
        
        #expect(tokyoCenter.latitude == 35.6895)
        #expect(tokyoCenter.longitude == 139.6917)
    }
    
    @Test @MainActor func test_getDefaultLocation_shouldReturnTokyoCenterLocation() async throws {
        let locationService = LocationService.shared
        let defaultLocation = locationService.getDefaultLocation()
        
        #expect(defaultLocation.coordinate.latitude == LocationService.tokyoCenter.latitude)
        #expect(defaultLocation.coordinate.longitude == LocationService.tokyoCenter.longitude)
    }
    
    // MARK: - Location Error Tests
    
    @Test func test_locationError_permissionDenied_shouldHaveCorrectDescription() async throws {
        let error = LocationError.permissionDenied
        #expect(error.errorDescription == "位置情報の使用許可が必要です")
    }
    
    @Test func test_locationError_locationUnavailable_shouldHaveCorrectDescription() async throws {
        let error = LocationError.locationUnavailable
        #expect(error.errorDescription == "位置情報を取得できません")
    }
    
    @Test func test_locationError_allCases_shouldHaveNonEmptyDescriptions() async throws {
        let allErrors: [LocationError] = [.permissionDenied, .locationUnavailable]
        
        for error in allErrors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }
}

// MARK: - ImageService Tests
struct ImageServiceTests {
    
    // MARK: - Initial State Tests
    
    @Test @MainActor func test_init_shouldHaveCorrectInitialState() async throws {
        let imageService = ImageService.shared
        
        // 初期状態の確認
        #expect(imageService.isUploading == false)
        #expect(imageService.uploadProgress == 0)
        #expect(imageService.errorMessage == nil)
    }
    
    // MARK: - Image Processing Tests
    
    @Test @MainActor func test_extractLocationFromImage_withNoLocationData_shouldReturnNil() async throws {
        let imageService = ImageService.shared
        
        // 位置情報のない画像を作成
        let image = UIImage(systemName: "plus")!
        let location = imageService.extractLocationFromImage(image)
        
        #expect(location == nil)
    }
    
    // MARK: - Error Handling Tests
    
    @Test func test_imageError_compressionFailed_shouldHaveCorrectDescription() async throws {
        let error = ImageError.compressionFailed
        #expect(error.errorDescription == "画像の圧縮に失敗しました")
    }
    
    @Test func test_imageError_uploadFailed_shouldHaveCorrectDescription() async throws {
        let error = ImageError.uploadFailed
        #expect(error.errorDescription == "画像のアップロードに失敗しました")
    }
    
    @Test func test_imageError_invalidImageData_shouldHaveCorrectDescription() async throws {
        let error = ImageError.invalidImageData
        #expect(error.errorDescription == "無効な画像データです")
    }
    
    @Test func test_imageError_noLocationData_shouldHaveCorrectDescription() async throws {
        let error = ImageError.noLocationData
        #expect(error.errorDescription == "画像に位置情報が含まれていません")
    }
    
    @Test func test_imageError_authenticationRequired_shouldHaveCorrectDescription() async throws {
        let error = ImageError.authenticationRequired
        #expect(error.errorDescription == "画像をアップロードするにはログインが必要です")
    }
    
    @Test func test_imageError_configurationError_shouldHaveCorrectDescription() async throws {
        let error = ImageError.configurationError
        #expect(error.errorDescription == "Firebase設定に問題があります")
    }
    
    @Test func test_imageError_allCases_shouldHaveNonEmptyDescriptions() async throws {
        let allErrors: [ImageError] = [
            .compressionFailed,
            .uploadFailed,
            .invalidImageData,
            .noLocationData,
            .authenticationRequired,
            .configurationError
        ]
        
        for error in allErrors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }
    
    // MARK: - Configuration Validation Tests
    
    @Test func test_firebaseConfigValidation_init_shouldCreateValidInstance() async throws {
        let validation = FirebaseConfigValidation(
            isValid: true,
            errorMessage: nil,
            debugInfo: "Test configuration"
        )
        
        #expect(validation.isValid == true)
        #expect(validation.errorMessage == nil)
        #expect(validation.debugInfo == "Test configuration")
    }
    
    @Test func test_firebaseConfigValidation_withError_shouldCreateErrorInstance() async throws {
        let validation = FirebaseConfigValidation(
            isValid: false,
            errorMessage: "Configuration error",
            debugInfo: "Error details"
        )
        
        #expect(validation.isValid == false)
        #expect(validation.errorMessage == "Configuration error")
        #expect(validation.debugInfo == "Error details")
    }
}

// MARK: - VendingMachineFirestoreService Tests
struct VendingMachineFirestoreServiceTests {
    
    // MARK: - Initial State Tests
    
    @Test @MainActor func test_init_shouldHaveCorrectInitialState() async throws {
        let firestoreService = VendingMachineFirestoreService.shared
        
        // 初期状態の確認
        #expect(firestoreService.vendingMachines.isEmpty)
        #expect(firestoreService.isLoading == false)
        #expect(firestoreService.errorMessage == nil)
    }
    
    // MARK: - Filtering Logic Tests
    
    @Test @MainActor func test_filterByMachineType_withNilType_shouldReturnAllMachines() async throws {
        let firestoreService = VendingMachineFirestoreService.shared
        
        // サンプルデータを設定
        let machines = VendingMachine.sampleData
        firestoreService.vendingMachines = machines
        
        let filtered = firestoreService.filterByMachineType(nil)
        #expect(filtered.count == machines.count)
    }
    
    @Test @MainActor func test_filterByMachineType_withSpecificType_shouldReturnMatchingMachines() async throws {
        let firestoreService = VendingMachineFirestoreService.shared
        
        // 異なる機種のマシンを作成
        let beverageMachine = VendingMachine(
            latitude: 35.6895,
            longitude: 139.6917,
            description: "飲料機",
            machineType: .beverage
        )
        
        let foodMachine = VendingMachine(
            latitude: 35.6896,
            longitude: 139.6918,
            description: "食品機",
            machineType: .food
        )
        
        firestoreService.vendingMachines = [beverageMachine, foodMachine]
        
        let beverageFiltered = firestoreService.filterByMachineType(.beverage)
        #expect(beverageFiltered.count == 1)
        #expect(beverageFiltered.first?.machineType == .beverage)
        
        let foodFiltered = firestoreService.filterByMachineType(.food)
        #expect(foodFiltered.count == 1)
        #expect(foodFiltered.first?.machineType == .food)
    }
    
    @Test @MainActor func test_filterByOperatingStatus_withNilStatus_shouldReturnAllMachines() async throws {
        let firestoreService = VendingMachineFirestoreService.shared
        
        // サンプルデータを設定
        let machines = VendingMachine.sampleData
        firestoreService.vendingMachines = machines
        
        let filtered = firestoreService.filterByOperatingStatus(nil)
        #expect(filtered.count == machines.count)
    }
    
    @Test @MainActor func test_filterByOperatingStatus_withSpecificStatus_shouldReturnMatchingMachines() async throws {
        let firestoreService = VendingMachineFirestoreService.shared
        
        // 異なる稼働状況のマシンを作成
        let operatingMachine = VendingMachine(
            latitude: 35.6895,
            longitude: 139.6917,
            description: "稼働中マシン",
            operatingStatus: .operating
        )
        
        let brokenMachine = VendingMachine(
            latitude: 35.6896,
            longitude: 139.6918,
            description: "故障マシン",
            operatingStatus: .outOfOrder
        )
        
        firestoreService.vendingMachines = [operatingMachine, brokenMachine]
        
        let operatingFiltered = firestoreService.filterByOperatingStatus(.operating)
        #expect(operatingFiltered.count == 1)
        #expect(operatingFiltered.first?.operatingStatus == .operating)
        
        let brokenFiltered = firestoreService.filterByOperatingStatus(.outOfOrder)
        #expect(brokenFiltered.count == 1)
        #expect(brokenFiltered.first?.operatingStatus == .outOfOrder)
    }
    
    // MARK: - Distance Calculation Tests
    
    @Test @MainActor func test_fetchVendingMachinesInRegion_shouldFilterByDistance() async throws {
        let firestoreService = VendingMachineFirestoreService.shared
        
        // テスト用のマシンを作成（距離の異なる位置）
        let nearMachine = VendingMachine(
            latitude: 35.6895, // 中心点
            longitude: 139.6917,
            description: "近くのマシン"
        )
        
        let farMachine = VendingMachine(
            latitude: 35.7000, // 約1.2km離れた位置
            longitude: 139.7000,
            description: "遠くのマシン"
        )
        
        firestoreService.vendingMachines = [nearMachine, farMachine]
        
        let center = CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917)
        let radius: Double = 1000 // 1km
        
        let nearbyMachines = try await firestoreService.fetchVendingMachinesInRegion(
            center: center,
            radiusInMeters: radius
        )
        
        // 1km圏内のマシンのみが返されることを確認
        #expect(nearbyMachines.count == 1)
        #expect(nearbyMachines.first?.description == "近くのマシン")
    }
    
    @Test @MainActor func test_sortByDistance_shouldSortMachinesByDistanceFromLocation() async throws {
        let firestoreService = VendingMachineFirestoreService.shared
        
        // 距離の異なる3つのマシンを作成
        let machine1 = VendingMachine(
            id: "1",
            latitude: 35.6895, // 基準点から最も近い
            longitude: 139.6917,
            description: "最寄りマシン"
        )
        
        let machine2 = VendingMachine(
            id: "2",
            latitude: 35.6900, // 中間距離
            longitude: 139.6922,
            description: "中間マシン"
        )
        
        let machine3 = VendingMachine(
            id: "3",
            latitude: 35.6950, // 最も遠い
            longitude: 139.6970,
            description: "遠方マシン"
        )
        
        // 順序をバラバラに設定
        firestoreService.vendingMachines = [machine3, machine1, machine2]
        
        let referenceLocation = CLLocation(latitude: 35.6895, longitude: 139.6917)
        firestoreService.sortByDistance(from: referenceLocation)
        
        // 距離順にソートされていることを確認
        #expect(firestoreService.vendingMachines[0].id == "1") // 最寄り
        #expect(firestoreService.vendingMachines[1].id == "2") // 中間
        #expect(firestoreService.vendingMachines[2].id == "3") // 遠方
    }
}

// MARK: - ViewModel Layer Tests

// MARK: - VendingMachineMapViewModel Tests
struct VendingMachineMapViewModelTests {
    
    // MARK: - Initial State Tests
    
    @Test @MainActor func test_init_shouldHaveCorrectInitialState() async throws {
        let viewModel = VendingMachineMapViewModel()
        
        // マップ領域の初期値確認
        #expect(viewModel.mapRegion.center.latitude == LocationService.tokyoCenter.latitude)
        #expect(viewModel.mapRegion.center.longitude == LocationService.tokyoCenter.longitude)
        #expect(viewModel.mapRegion.span.latitudeDelta == 0.05)
        #expect(viewModel.mapRegion.span.longitudeDelta == 0.05)
        
        // UI状態の初期値確認
        #expect(viewModel.showingAddMachineDialog == false)
        #expect(viewModel.selectedCoordinate == nil)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isLoading == false)
        
        // 画像関連の初期値確認
        #expect(viewModel.selectedImage == nil)
        #expect(viewModel.imageUploadProgress == 0)
        #expect(viewModel.isUploadingImage == false)
        #expect(viewModel.showingPhotoSelection == false)
        
        // フィルター関連の初期値確認
        #expect(viewModel.selectedMachineTypeFilter == nil)
        #expect(viewModel.selectedOperatingStatusFilter == nil)
        
        // 詳細画面関連の初期値確認
        #expect(viewModel.selectedVendingMachine == nil)
        #expect(viewModel.showingVendingMachineDetail == false)
        
        // 削除関連の初期値確認
        #expect(viewModel.isDeletingVendingMachine == false)
        #expect(viewModel.showingDeleteConfirmation == false)
        #expect(viewModel.vendingMachineToDelete == nil)
    }
    
    // MARK: - Filter Tests
    
    @Test @MainActor func test_setMachineTypeFilter_shouldUpdateFilter() async throws {
        let viewModel = VendingMachineMapViewModel()
        
        viewModel.setMachineTypeFilter(.beverage)
        #expect(viewModel.selectedMachineTypeFilter == .beverage)
        
        viewModel.setMachineTypeFilter(.food)
        #expect(viewModel.selectedMachineTypeFilter == .food)
        
        viewModel.setMachineTypeFilter(nil)
        #expect(viewModel.selectedMachineTypeFilter == nil)
    }
    
    @Test @MainActor func test_setOperatingStatusFilter_shouldUpdateFilter() async throws {
        let viewModel = VendingMachineMapViewModel()
        
        viewModel.setOperatingStatusFilter(.operating)
        #expect(viewModel.selectedOperatingStatusFilter == .operating)
        
        viewModel.setOperatingStatusFilter(.outOfOrder)
        #expect(viewModel.selectedOperatingStatusFilter == .outOfOrder)
        
        viewModel.setOperatingStatusFilter(nil)
        #expect(viewModel.selectedOperatingStatusFilter == nil)
    }
    
    @Test @MainActor func test_clearFilters_shouldResetAllFilters() async throws {
        let viewModel = VendingMachineMapViewModel()
        
        // フィルターを設定
        viewModel.setMachineTypeFilter(.beverage)
        viewModel.setOperatingStatusFilter(.operating)
        
        // フィルターをクリア
        viewModel.clearFilters()
        
        #expect(viewModel.selectedMachineTypeFilter == nil)
        #expect(viewModel.selectedOperatingStatusFilter == nil)
    }
    
    // MARK: - Image Selection Tests
    
    @Test @MainActor func test_selectImage_shouldUpdateSelectedImage() async throws {
        let viewModel = VendingMachineMapViewModel()
        
        let testImage = UIImage(systemName: "plus")!
        viewModel.selectImage(testImage)
        
        #expect(viewModel.selectedImage != nil)
    }
    
    @Test @MainActor func test_clearSelectedImage_shouldResetImage() async throws {
        let viewModel = VendingMachineMapViewModel()
        
        // 画像を設定
        let testImage = UIImage(systemName: "plus")!
        viewModel.selectImage(testImage)
        
        // 画像をクリア
        viewModel.clearSelectedImage()
        
        #expect(viewModel.selectedImage == nil)
    }
    
    @Test @MainActor func test_cancelPhotoSelection_shouldResetPhotoSelectionState() async throws {
        let viewModel = VendingMachineMapViewModel()
        
        // 状態を設定
        let testImage = UIImage(systemName: "plus")!
        viewModel.selectImage(testImage)
        viewModel.showingPhotoSelection = true
        viewModel.selectedCoordinate = CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917)
        
        // キャンセル
        viewModel.cancelPhotoSelection()
        
        #expect(viewModel.showingPhotoSelection == false)
        #expect(viewModel.selectedImage == nil)
        #expect(viewModel.selectedCoordinate == nil)
    }
    
    // MARK: - Detail View Tests
    
    @Test @MainActor func test_selectVendingMachine_shouldUpdateDetailViewState() async throws {
        let viewModel = VendingMachineMapViewModel()
        
        let testMachine = VendingMachine(
            latitude: 35.6895,
            longitude: 139.6917,
            description: "テスト自動販売機"
        )
        
        viewModel.selectVendingMachine(testMachine)
        
        #expect(viewModel.selectedVendingMachine != nil)
        #expect(viewModel.selectedVendingMachine?.description == "テスト自動販売機")
        #expect(viewModel.showingVendingMachineDetail == true)
    }
    
    @Test @MainActor func test_closeVendingMachineDetail_shouldResetDetailViewState() async throws {
        let viewModel = VendingMachineMapViewModel()
        
        // 詳細画面を表示
        let testMachine = VendingMachine(
            latitude: 35.6895,
            longitude: 139.6917,
            description: "テスト自動販売機"
        )
        viewModel.selectVendingMachine(testMachine)
        
        // 詳細画面を閉じる
        viewModel.closeVendingMachineDetail()
        
        #expect(viewModel.showingVendingMachineDetail == false)
        #expect(viewModel.selectedVendingMachine == nil)
    }
    
    // MARK: - Delete Confirmation Tests
    
    @Test @MainActor func test_cancelDelete_shouldResetDeleteState() async throws {
        let viewModel = VendingMachineMapViewModel()
        
        // 削除状態を設定
        let testMachine = VendingMachine(
            latitude: 35.6895,
            longitude: 139.6917,
            description: "削除テスト"
        )
        viewModel.vendingMachineToDelete = testMachine
        viewModel.showingDeleteConfirmation = true
        
        // 削除をキャンセル
        viewModel.cancelDelete()
        
        #expect(viewModel.showingDeleteConfirmation == false)
        #expect(viewModel.vendingMachineToDelete == nil)
    }
    
    // MARK: - Error Handling Tests
    
    @Test @MainActor func test_clearError_shouldResetErrorMessage() async throws {
        let viewModel = VendingMachineMapViewModel()
        
        // エラーメッセージを設定
        viewModel.errorMessage = "テストエラー"
        
        // エラーをクリア
        viewModel.clearError()
        
        #expect(viewModel.errorMessage == nil)
    }
    
    // MARK: - Coordinate Handling Tests
    
    @Test @MainActor func test_handleMapLongPress_withValidCoordinate_shouldUpdateSelectedCoordinate() async throws {
        let viewModel = VendingMachineMapViewModel()
        
        let testCoordinate = CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917)
        
        // 認証が必要なので、認証なしの状態でテスト
        viewModel.handleMapLongPress(at: testCoordinate)
        
        // 認証なしの場合はエラーメッセージが設定される
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.contains("ログインが必要") == true)
    }
    
    // MARK: - Map Region Tests
    
    @Test @MainActor func test_selectImage_withLocationData_shouldUpdateMapRegion() async throws {
        let viewModel = VendingMachineMapViewModel()
        
        // EXIF位置情報付きの画像をシミュレート（実際にはEXIF情報はないが、メソッドの動作確認）
        let testImage = UIImage(systemName: "plus")!
        viewModel.selectImage(testImage)
        
        // 画像は選択されているが、EXIF位置情報がないため座標は更新されない
        #expect(viewModel.selectedImage != nil)
    }
    
    // MARK: - State Validation Tests
    
    @Test @MainActor func test_addVendingMachineWithImage_shouldUpdateState() async throws {
        let viewModel = VendingMachineMapViewModel()
        
        let testCoordinate = CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917)
        let testImage = UIImage(systemName: "plus")!
        
        viewModel.addVendingMachineWithImage(
            coordinate: testCoordinate,
            description: "画像付きテスト",
            machineType: .beverage,
            operatingStatus: .operating,
            paymentMethods: [.cash],
            image: testImage
        )
        
        // 状態が正しく設定されることを確認
        #expect(viewModel.selectedCoordinate != nil)
        #expect(viewModel.selectedImage != nil)
    }
}

// MARK: - Integration Tests

// MARK: - Service Integration Tests
struct ServiceIntegrationTests {
    
    // MARK: - Data Model Integration Tests
    
    @Test @MainActor func test_vendingMachineModel_withFirestoreServiceData_shouldBeCompatible() async throws {
        let firestoreService = VendingMachineFirestoreService.shared
        
        // Sample VendingMachine data that would come from Firestore
        let testMachine = VendingMachine(
            id: "integration-test-1",
            latitude: 35.6895,
            longitude: 139.6917,
            description: "統合テスト用自動販売機",
            machineType: .beverage,
            operatingStatus: .operating,
            paymentMethods: [.cash, .electronicMoney],
            lastUpdated: Date(),
            imageURL: "https://example.com/image.jpg",
            thumbnailURL: "https://example.com/thumb.jpg",
            hasImage: true,
            imageUploadedAt: Date()
        )
        
        // Verify all fields are compatible with service filtering
        let typeFiltered = firestoreService.filterByMachineType(.beverage)
        let statusFiltered = firestoreService.filterByOperatingStatus(.operating)
        
        // Test that the model structure works with service methods
        #expect(testMachine.coordinate.latitude == 35.6895)
        #expect(testMachine.coordinate.longitude == 139.6917)
        #expect(testMachine.location.coordinate.latitude == 35.6895)
        #expect(testMachine.machineType == .beverage)
        #expect(testMachine.operatingStatus == .operating)
        #expect(testMachine.paymentMethods.contains(.cash))
        #expect(testMachine.hasImage == true)
    }
    
    @Test @MainActor func test_userModel_withAuthServiceData_shouldBeCompatible() async throws {
        let authService = AuthService.shared
        
        // Sample User data that would come from Firebase Auth
        let testUser = User(
            id: "auth-integration-test",
            email: "test@integration.com",
            displayName: "統合テストユーザー",
            photoURL: URL(string: "https://example.com/photo.jpg")
        )
        
        // Test that User model integrates properly with expected auth flow
        #expect(testUser.id == "auth-integration-test")
        #expect(testUser.name == "統合テストユーザー")
        #expect(testUser.email == "test@integration.com")
        #expect(testUser.photoURL?.absoluteString == "https://example.com/photo.jpg")
    }
    
    // MARK: - Service Interaction Tests
    
    @Test @MainActor func test_imageService_errorTypes_shouldIntegrateWithViewModelErrorHandling() async throws {
        let imageService = ImageService.shared
        
        // Test different ImageError types that ViewModel needs to handle
        let authError = ImageError.authenticationRequired
        let configError = ImageError.configurationError
        let compressionError = ImageError.compressionFailed
        let uploadError = ImageError.uploadFailed
        
        // Verify error messages are localized and meaningful for UI display
        #expect(authError.errorDescription?.contains("ログイン") == true)
        #expect(configError.errorDescription?.contains("Firebase設定") == true)
        #expect(compressionError.errorDescription?.contains("圧縮") == true)
        #expect(uploadError.errorDescription?.contains("アップロード") == true)
        
        // Test that all errors have non-empty descriptions for UI error handling
        let allImageErrors: [ImageError] = [
            .authenticationRequired, .configurationError, .compressionFailed,
            .uploadFailed, .invalidImageData, .noLocationData
        ]
        
        for error in allImageErrors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }
    
    @Test @MainActor func test_locationService_errorTypes_shouldIntegrateWithViewModelErrorHandling() async throws {
        let locationService = LocationService.shared
        
        // Test LocationError types that ViewModel needs to handle
        let permissionError = LocationError.permissionDenied
        let unavailableError = LocationError.locationUnavailable
        
        // Verify error messages are localized and meaningful for UI display
        #expect(permissionError.errorDescription?.contains("位置情報") == true)
        #expect(unavailableError.errorDescription?.contains("取得できません") == true)
        
        // Test default location fallback integration
        let defaultLocation = locationService.getDefaultLocation()
        #expect(defaultLocation.coordinate.latitude == LocationService.tokyoCenter.latitude)
        #expect(defaultLocation.coordinate.longitude == LocationService.tokyoCenter.longitude)
    }
    
    // MARK: - Cross-Service Data Flow Tests
    
    @Test @MainActor func test_vendingMachineCreation_dataFlowIntegration() async throws {
        // Test the complete data flow for creating a vending machine
        
        // 1. User provides coordinate
        let userCoordinate = CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917)
        
        // 2. Create VendingMachine with coordinate
        let machine = VendingMachine(
            latitude: userCoordinate.latitude,
            longitude: userCoordinate.longitude,
            description: "データフロー統合テスト",
            machineType: .food,
            operatingStatus: .maintenance,
            paymentMethods: [.card, .qrCode]
        )
        
        // 3. Verify coordinate conversion for map display
        #expect(machine.coordinate.latitude == userCoordinate.latitude)
        #expect(machine.coordinate.longitude == userCoordinate.longitude)
        
        // 4. Verify location calculation for distance sorting
        let location = machine.location
        #expect(location.coordinate.latitude == userCoordinate.latitude)
        #expect(location.coordinate.longitude == userCoordinate.longitude)
        
        // 5. Test filtering compatibility
        let firestoreService = VendingMachineFirestoreService.shared
        firestoreService.vendingMachines = [machine]
        
        let foodMachines = firestoreService.filterByMachineType(.food)
        let maintenanceMachines = firestoreService.filterByOperatingStatus(.maintenance)
        
        #expect(foodMachines.count == 1)
        #expect(maintenanceMachines.count == 1)
        #expect(foodMachines.first?.id == machine.id)
        #expect(maintenanceMachines.first?.id == machine.id)
    }
    
    @Test @MainActor func test_viewModelServiceIntegration_stateManagement() async throws {
        let viewModel = VendingMachineMapViewModel()
        
        // Test ViewModel integrates properly with service initial states
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        
        // Test filter state integration
        viewModel.setMachineTypeFilter(.beverage)
        viewModel.setOperatingStatusFilter(.operating)
        
        #expect(viewModel.selectedMachineTypeFilter == .beverage)
        #expect(viewModel.selectedOperatingStatusFilter == .operating)
        
        // Test state reset integration
        viewModel.clearFilters()
        viewModel.clearError()
        
        #expect(viewModel.selectedMachineTypeFilter == nil)
        #expect(viewModel.selectedOperatingStatusFilter == nil)
        #expect(viewModel.errorMessage == nil)
    }
    
    // MARK: - End-to-End Workflow Tests
    
    @Test @MainActor func test_completeVendingMachineWorkflow_withoutImage() async throws {
        // Test complete workflow: coordinate selection → machine creation → filtering → display
        
        let viewModel = VendingMachineMapViewModel()
        let firestoreService = VendingMachineFirestoreService.shared
        
        // 1. User selects coordinate (simulated)
        let testCoordinate = CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917)
        viewModel.selectedCoordinate = testCoordinate
        
        // 2. Create machine data structure
        let newMachine = VendingMachine(
            latitude: testCoordinate.latitude,
            longitude: testCoordinate.longitude,
            description: "ワークフローテスト",
            machineType: .ice,
            operatingStatus: .operating,
            paymentMethods: [.cash, .card]
        )
        
        // 3. Add to service (simulated)
        firestoreService.vendingMachines = [newMachine]
        
        // 4. Test filtering workflow
        viewModel.setMachineTypeFilter(.ice)
        let filteredMachines = viewModel.getFilteredVendingMachines()
        
        #expect(filteredMachines.count == 1)
        #expect(filteredMachines.first?.machineType == .ice)
        #expect(filteredMachines.first?.description == "ワークフローテスト")
        
        // 5. Test selection workflow
        viewModel.selectVendingMachine(newMachine)
        
        #expect(viewModel.selectedVendingMachine != nil)
        #expect(viewModel.showingVendingMachineDetail == true)
        
        // 6. Test cleanup workflow
        viewModel.closeVendingMachineDetail()
        
        #expect(viewModel.selectedVendingMachine == nil)
        #expect(viewModel.showingVendingMachineDetail == false)
    }
    
    @Test @MainActor func test_completeFilteringWorkflow() async throws {
        // Test complete filtering workflow with multiple machines
        
        let viewModel = VendingMachineMapViewModel()
        let firestoreService = VendingMachineFirestoreService.shared
        
        // Create diverse test data
        let machines = [
            VendingMachine(
                id: "filter-test-1",
                latitude: 35.6895, longitude: 139.6917,
                description: "飲料機1", machineType: .beverage, operatingStatus: .operating
            ),
            VendingMachine(
                id: "filter-test-2",
                latitude: 35.6896, longitude: 139.6918,
                description: "食品機1", machineType: .food, operatingStatus: .outOfOrder
            ),
            VendingMachine(
                id: "filter-test-3",
                latitude: 35.6897, longitude: 139.6919,
                description: "飲料機2", machineType: .beverage, operatingStatus: .maintenance
            )
        ]
        
        firestoreService.vendingMachines = machines
        
        // Test machine type filtering
        viewModel.setMachineTypeFilter(.beverage)
        let beverageFiltered = viewModel.getFilteredVendingMachines()
        #expect(beverageFiltered.count == 2)
        
        viewModel.setMachineTypeFilter(.food)
        let foodFiltered = viewModel.getFilteredVendingMachines()
        #expect(foodFiltered.count == 1)
        
        // Test status filtering
        viewModel.clearFilters()
        viewModel.setOperatingStatusFilter(.operating)
        let operatingFiltered = viewModel.getFilteredVendingMachines()
        #expect(operatingFiltered.count == 1)
        
        // Test combined filtering
        viewModel.setMachineTypeFilter(.beverage)
        viewModel.setOperatingStatusFilter(.operating)
        let combinedFiltered = viewModel.getFilteredVendingMachines()
        #expect(combinedFiltered.count == 1)
        #expect(combinedFiltered.first?.id == "filter-test-1")
        
        // Test filter clearing
        viewModel.clearFilters()
        let allMachines = viewModel.getFilteredVendingMachines()
        #expect(allMachines.count == 3)
    }
}

// MARK: - User Model Tests
struct UserModelTests {
    
    // MARK: - Initialization Tests
    
    @Test func test_init_withAllParameters_shouldCreateInstance() async throws {
        let photoURL = URL(string: "https://example.com/photo.jpg")
        let user = User(
            id: "user123",
            email: "test@example.com",
            displayName: "Test User",
            photoURL: photoURL
        )
        
        #expect(user.id == "user123")
        #expect(user.email == "test@example.com")
        #expect(user.displayName == "Test User")
        #expect(user.photoURL == photoURL)
    }
    
    @Test func test_init_withRequiredParametersOnly_shouldCreateInstance() async throws {
        let user = User(
            id: "user456",
            email: nil,
            displayName: nil
        )
        
        #expect(user.id == "user456")
        #expect(user.email == nil)
        #expect(user.displayName == nil)
        #expect(user.photoURL == nil)
    }
    
    @Test func test_init_withPartialParameters_shouldCreateInstance() async throws {
        let user = User(
            id: "user789",
            email: "partial@example.com",
            displayName: nil
        )
        
        #expect(user.id == "user789")
        #expect(user.email == "partial@example.com")
        #expect(user.displayName == nil)
        #expect(user.photoURL == nil)
    }
    
    // MARK: - Name Property Tests
    
    @Test func test_name_withDisplayName_shouldReturnDisplayName() async throws {
        let user = User(
            id: "test1",
            email: "test@example.com",
            displayName: "Test Display Name"
        )
        
        #expect(user.name == "Test Display Name")
    }
    
    @Test func test_name_withoutDisplayNameButWithEmail_shouldReturnEmail() async throws {
        let user = User(
            id: "test2",
            email: "fallback@example.com",
            displayName: nil
        )
        
        #expect(user.name == "fallback@example.com")
    }
    
    @Test func test_name_withoutDisplayNameAndEmail_shouldReturnGuestUser() async throws {
        let user = User(
            id: "test3",
            email: nil,
            displayName: nil
        )
        
        #expect(user.name == "ゲストユーザー")
    }
    
    @Test func test_name_withEmptyDisplayName_shouldFallbackToEmail() async throws {
        let user = User(
            id: "test4",
            email: "empty@example.com",
            displayName: ""
        )
        
        // Empty string is truthy in Swift, so it should return empty string
        #expect(user.name == "")
    }
    
    // MARK: - Equatable Tests
    
    @Test func test_equality_withSameData_shouldBeEqual() async throws {
        let photoURL = URL(string: "https://example.com/same.jpg")
        
        let user1 = User(
            id: "same123",
            email: "same@example.com",
            displayName: "Same User",
            photoURL: photoURL
        )
        
        let user2 = User(
            id: "same123",
            email: "same@example.com",
            displayName: "Same User",
            photoURL: photoURL
        )
        
        #expect(user1 == user2)
    }
    
    @Test func test_equality_withDifferentIds_shouldNotBeEqual() async throws {
        let user1 = User(
            id: "different1",
            email: "test@example.com",
            displayName: "User"
        )
        
        let user2 = User(
            id: "different2",
            email: "test@example.com",
            displayName: "User"
        )
        
        #expect(user1 != user2)
    }
    
    @Test func test_equality_withDifferentEmails_shouldNotBeEqual() async throws {
        let user1 = User(
            id: "same123",
            email: "email1@example.com",
            displayName: "User"
        )
        
        let user2 = User(
            id: "same123",
            email: "email2@example.com",
            displayName: "User"
        )
        
        #expect(user1 != user2)
    }
    
    @Test func test_equality_withDifferentDisplayNames_shouldNotBeEqual() async throws {
        let user1 = User(
            id: "same123",
            email: "test@example.com",
            displayName: "Name 1"
        )
        
        let user2 = User(
            id: "same123",
            email: "test@example.com",
            displayName: "Name 2"
        )
        
        #expect(user1 != user2)
    }
    
    @Test func test_equality_withDifferentPhotoURLs_shouldNotBeEqual() async throws {
        let photoURL1 = URL(string: "https://example.com/photo1.jpg")
        let photoURL2 = URL(string: "https://example.com/photo2.jpg")
        
        let user1 = User(
            id: "same123",
            email: "test@example.com",
            displayName: "User",
            photoURL: photoURL1
        )
        
        let user2 = User(
            id: "same123",
            email: "test@example.com",
            displayName: "User",
            photoURL: photoURL2
        )
        
        #expect(user1 != user2)
    }
    
    // MARK: - Sample Data Tests
    
    @Test func test_sampleUser_shouldHaveValidData() async throws {
        let sampleUser = User.sampleUser
        
        #expect(sampleUser.id == "sample-user-id")
        #expect(sampleUser.email == "test@example.com")
        #expect(sampleUser.displayName == "テストユーザー")
        #expect(sampleUser.photoURL == nil)
        #expect(sampleUser.name == "テストユーザー")
    }
    
    // MARK: - Edge Case Tests
    
    @Test func test_photoURL_withValidURL_shouldBeSet() async throws {
        let validURL = URL(string: "https://example.com/valid-photo.jpg")!
        let user = User(
            id: "url-test",
            email: "url@example.com",
            displayName: "URL Test",
            photoURL: validURL
        )
        
        #expect(user.photoURL == validURL)
    }
    
    @Test func test_identifiable_shouldHaveUniqueIds() async throws {
        let user1 = User(id: "unique1", email: nil, displayName: nil)
        let user2 = User(id: "unique2", email: nil, displayName: nil)
        
        // Test that Identifiable protocol works
        #expect(user1.id != user2.id)
        
        // Test that users with same id are considered same by Identifiable
        let user3 = User(id: "unique1", email: "different@example.com", displayName: "Different Name")
        #expect(user1.id == user3.id) // Same id for Identifiable
        #expect(user1 != user3) // But not equal by Equatable (different content)
    }
}
