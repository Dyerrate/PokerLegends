//
//  CloudKitUser.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 12/17/25.
//


import CloudKit

final class CloudKitUser {
    private let db = CKContainer.default().privateCloudDatabase
    private let recordType = "User"

    func fetchUser(byAppleUserId appleUserId: String) async throws -> CKRecord? {
        let predicate = NSPredicate(format: "appleUserId == %@", appleUserId)
        let query = CKQuery(recordType: recordType, predicate: predicate)
        let (matched, _) = try await db.records(matching: query, resultsLimit: 1)
        return try! matched.first?.1.get() // unwrap match result
    }

    func createUser(appleUserId: String, email: String?, fullName: String?) async throws -> CKRecord {
        let record = CKRecord(recordType: recordType)
        record["appleUserId"] = appleUserId as CKRecordValue
        if let email { record["email"] = email as CKRecordValue }
        if let fullName { record["fullName"] = fullName as CKRecordValue }
        record["createdAt"] = Date() as CKRecordValue
        record["updatedAt"] = Date() as CKRecordValue
        return try await db.save(record)
    }

    // TODO: Add logic to handle different User update types
    func updateUser(_ record: CKRecord, changes: (CKRecord) -> Void) async throws -> CKRecord {
        changes(record)
        record["updatedAt"] = Date() as CKRecordValue
        return try await db.save(record)
    }
}
