//
//  ContentView.swift
//  VendingMachineLocator
//
//  Created by Hiroshi Takagi on 2025/07/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VendingMachineMapScreenView()
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService.shared)
        .environmentObject(LocationService.shared)
        .environmentObject(VendingMachineFirestoreService.shared)
}
