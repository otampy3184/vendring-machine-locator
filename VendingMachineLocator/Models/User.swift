//
//  User.swift
//  VendingMachineLocator
//
//  Created by Claude on 2025/01/23.
//

import Foundation

/// ユーザー情報を表すデータモデル
struct User: Identifiable, Equatable {
    let id: String
    let email: String?
    let displayName: String?
    let photoURL: URL?
    
    init(id: String, email: String?, displayName: String?, photoURL: URL? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
    }
    
    /// 表示用の名前を取得
    var name: String {
        return displayName ?? email ?? "ゲストユーザー"
    }
}

// MARK: - Preview用のサンプルデータ
extension User {
    static let sampleUser = User(
        id: "sample-user-id",
        email: "test@example.com",
        displayName: "テストユーザー"
    )
}