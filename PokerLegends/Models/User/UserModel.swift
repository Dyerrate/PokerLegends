//
//  UserModel.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 8/10/24.
//


import Foundation
import CloudKit
import Combine

final class UserModel: ObservableObject {
    // Necessary Data from logged in CloudKit
    @Published var id: CKRecord.ID
    @Published var appleUserId: String
    @Published var username: String?
    @Published var email: String?
    @Published var playerMoney: Double?
    @Published var playerMicroData: PlayerMicroData
    @Published var loginStreakCount: Int
    @Published var lastLoginDate: Date?

    /// Weak reference so UserModel can trigger CloudKit syncs without owning UserManager.
    weak var userManager: UserManager?

    // Designated initializer for manual creation (optional but useful)
    init(
        id: CKRecord.ID = CKRecord.ID(),
        appleUserId: String,
        username: String? = nil,
        email: String? = nil,
        playerMoney: Double? = nil,
        playerMicroData: PlayerMicroData,
        loginStreakCount: Int = 0,
        lastLoginDate: Date? = nil
    ) {
        self.id = id
        self.appleUserId = appleUserId
        self.username = username
        self.email = email
        self.playerMoney = playerMoney
        self.playerMicroData = playerMicroData
        self.loginStreakCount = loginStreakCount
        self.lastLoginDate = lastLoginDate
    }

    // Convenience initializer from CloudKit record
    convenience init?(record: CKRecord) {
        guard let appleUserId = record["appleUserId"] as? String else { return nil }
        let id = record.recordID
        let username = record["username"] as? String
        let email = record["email"] as? String
        let playerMoney = record["playerMoney"] as? Double
        let loginStreakCount = record["loginStreakCount"] as? Int ?? 0
        let lastLoginDate = record["lastLoginDate"] as? Date
        let micro = PlayerMicroData(parentRecordId: id)

        self.init(
            id: id,
            appleUserId: appleUserId,
            username: username,
            email: email,
            playerMoney: playerMoney,
            playerMicroData: micro,
            loginStreakCount: loginStreakCount,
            lastLoginDate: lastLoginDate
        )
    }

    static var sample: UserModel {
        let fakeRecordID = CKRecord.ID(recordName: "sample-user")
        return UserModel(
            id: fakeRecordID,
            appleUserId: "sample_apple_user_id",
            username: "Lord Vlad",
            email: "sample@example.com",
            playerMoney: 1234.56,
            playerMicroData: PlayerMicroData.test
        )
    }
}
