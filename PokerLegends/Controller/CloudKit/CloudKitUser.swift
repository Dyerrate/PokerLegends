//
//  CloudKitUser.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 12/17/25.
//
import Foundation
import CloudKit

// Map CKRecord to your app model
struct CloudKitUser {
    let id: CKRecord.ID
    let appleUserId: String
    let email: String?
    let username: String?
    let playerMoney: Double?

    init?(record: CKRecord) {
        guard let appleUserId = record["appleUserId"] as? String else { return nil }
        self.id = record.recordID
        self.appleUserId = appleUserId
        self.email = record["email"] as? String
        self.username = record["username"] as? String
        self.playerMoney = record["playerMoney"] as? Double
    }
}

struct CloudKitUserService {
    static let logger = "CloudKitUserService" // simple static logger placeholder

    private let container = CKContainer(identifier: "iCloud.studio.subspatial.pokerlegends")
    private var db: CKDatabase { container.privateCloudDatabase }

    private enum Constants {
        static let recordType = "PLegendsUserRecord"
        static let appleUserIdKey = "appleUserId"
        static let emailKey = "email"
        static let usernameKey = "username"
        static let playerMoneyKey = "playerMoney"
        static let loginStreakCountKey = "loginStreakCount"
        static let lastLoginDateKey = "lastLoginDate"
    }

    /// Fetch a user record by Apple user ID in the private database.
    func fetchUser(byAppleUserId appleUserId: String) async throws -> CKRecord? {
        print("[CloudKitUserService] fetchUser started for appleUserId=\(appleUserId)")
        let predicate = NSPredicate(format: "%K == %@", Constants.appleUserIdKey, appleUserId)
        let query = CKQuery(recordType: Constants.recordType, predicate: predicate)
        query.sortDescriptors = []

        return try await withCheckedThrowingContinuation { continuation in
            let op = CKQueryOperation(query: query)
            op.resultsLimit = 1

            var firstRecord: CKRecord?

            op.recordMatchedBlock = { _, result in
                if case .success(let record) = result, firstRecord == nil {
                    firstRecord = record
                }
            }

            op.queryResultBlock = { result in
                switch result {
                case .success:
                    print("[CloudKitUserService] fetchUser completed. Found record? \(firstRecord != nil)")
                    continuation.resume(returning: firstRecord)
                case .failure(let error):
                    print("[CloudKitUserService] fetchUser failed: \(error)")
                    continuation.resume(throwing: error)
                }
            }

            db.add(op)
        }
    }

    /// Create a new user record with the provided details.
    func createUser(appleUserId: String, email: String?, username: String?) async throws -> CKRecord {
        print("[CloudKitUserService] createUser started for appleUserId=\(appleUserId), email=\(String(describing: email)), username=\(String(describing: username))")

        let record = CKRecord(recordType: Constants.recordType)
        record[Constants.appleUserIdKey] = appleUserId as CKRecordValue
        if let email { record[Constants.emailKey] = email as CKRecordValue }
        if let username { record[Constants.usernameKey] = username as CKRecordValue }
        record[Constants.playerMoneyKey] = 50000 as CKRecordValue

        print("[CloudKitUserService] Saving new record with playMoney=\(record[Constants.playerMoneyKey] ?? 0 as CKRecordValue)")
        let saved = try await db.save(record)
        print("[CloudKitUserService] createUser saved record id=\(saved.recordID.recordName)")
        return saved
    }

    /// Update the playerMoney field on an existing record.
    func updatePlayerBalance(recordId: CKRecord.ID, newBalance: Double) async throws {
        print("[CloudKitUserService] updatePlayerBalance: fetching record \(recordId.recordName)")
        let record = try await db.record(for: recordId)
        record[Constants.playerMoneyKey] = newBalance as CKRecordValue
        let saved = try await db.save(record)
        print("[CloudKitUserService] updatePlayerBalance: saved balance=\(newBalance) on record \(saved.recordID.recordName)")
    }

    /// Persist updated login streak fields to the existing record.
    func updateLoginStreak(recordId: CKRecord.ID, newStreak: Int, loginDate: Date) async throws {
        let record = try await db.record(for: recordId)
        record[Constants.loginStreakCountKey] = newStreak as CKRecordValue
        record[Constants.lastLoginDateKey] = loginDate as CKRecordValue
        let saved = try await db.save(record)
        print("[CloudKitUserService] updateLoginStreak: streak=\(newStreak) saved on record \(saved.recordID.recordName)")
    }

    /// Fetch the user if it exists, otherwise create a new one.
    func fetchOrCreateUser(appleUserId: String, email: String?, username: String?) async throws -> CKRecord {
        print("[CloudKitUserService] fetchOrCreateUser for appleUserId=\(appleUserId)")
        if let existing = try await fetchUser(byAppleUserId: appleUserId) {
            print("[CloudKitUserService] Existing user found: id=\(existing.recordID.recordName)")
            return existing
        }
        print("[CloudKitUserService] No existing user. Creating...")
        return try await createUser(appleUserId: appleUserId, email: email, username: username)
    }
}
