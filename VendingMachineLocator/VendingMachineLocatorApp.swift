//
//  VendingMachineLocatorApp.swift
//  VendingMachineLocator
//
//  Created by Hiroshi Takagi on 2025/07/23.
//

import SwiftUI
import Firebase

@main
struct VendingMachineLocatorApp: App {
    
    init() {
        // Firebase初期化
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AuthService.shared)
                .environmentObject(LocationService.shared)
                .environmentObject(VendingMachineFirestoreService.shared)
        }
    }
}
