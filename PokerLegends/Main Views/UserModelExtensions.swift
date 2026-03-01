//
//  UserModelExtensions.swift
//  PokerLegends
//
//  Enhanced UserModel for CloudKit integration
//

import Foundation
import CloudKit
import Combine

extension UserModel {
    
    // MARK: - CloudKit Integration
    
    /// Tracks if there are pending changes that need to be synced to CloudKit
    @Published var hasPendingChanges: Bool = false
    
    /// Last sync timestamp for conflict resolution
    @Published var lastSyncDate: Date?
    
    /// Debounced save to CloudKit - prevents too many network calls
    private var saveToCloudKitCancellable: AnyCancellable?
    
    /// Configure CloudKit change tracking
    func setupCloudKitTracking() {
        // Monitor changes to playerMoney specifically
        $playerMoney
            .dropFirst() // Skip initial value
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.handlePlayerMoneyChange(newValue)
            }
            .store(in: &cancellables)
        
        // You can add other property observers as needed
        Publishers.CombineLatest3($username, $email, $playerMicroData)
            .dropFirst()
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.markForCloudKitSync()
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    /// Handle player money changes with validation and CloudKit sync
    private func handlePlayerMoneyChange(_ newValue: Double?) {
        guard let newValue = newValue else { return }
        
        // Validate the change (prevent negative money, etc.)
        let validatedAmount = max(0, newValue)
        
        if validatedAmount != newValue {
            // Correct invalid values
            DispatchQueue.main.async {
                self.playerMoney = validatedAmount
            }
        }
        
        // Mark for CloudKit sync
        markForCloudKitSync()
        
        // Optional: Log the change for debugging
        print("💰 Player money changed to: \(validatedAmount)")
    }
    
    /// Mark the model as needing CloudKit sync
    private func markForCloudKitSync() {
        hasPendingChanges = true
        scheduleCloudKitSync()
    }
    
    /// Schedule a debounced save to CloudKit
    private func scheduleCloudKitSync() {
        // Cancel any existing save operation
        saveToCloudKitCancellable?.cancel()
        
        // Schedule a new save after a delay
        saveToCloudKitCancellable = Just(())
            .delay(for: .seconds(3), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.saveToCloudKit()
                }
            }
    }
    
    /// Save changes to CloudKit
    @MainActor
    func saveToCloudKit() async {
        guard hasPendingChanges else { return }
        
        do {
            let record = createCloudKitRecord()
            let database = CKContainer.default().publicCloudDatabase
            
            try await database.save(record)
            
            // Mark as synced
            hasPendingChanges = false
            lastSyncDate = Date()
            
            print("✅ UserModel synced to CloudKit successfully")
            
        } catch {
            print("❌ Failed to sync UserModel to CloudKit: \(error)")
            // Keep hasPendingChanges = true for retry
            
            // Optional: Schedule retry with exponential backoff
            scheduleRetrySync()
        }
    }
    
    /// Create a CloudKit record from current model state
    private func createCloudKitRecord() -> CKRecord {
        let record = CKRecord(recordType: "UserModel", recordID: id)
        
        record["appleUserId"] = appleUserId
        record["username"] = username
        record["email"] = email
        record["playerMoney"] = playerMoney
        record["lastModified"] = Date()
        
        // Add playerMicroData if it's encodable
        if let microDataData = try? JSONEncoder().encode(playerMicroData) {
            record["playerMicroData"] = microDataData
        }
        
        return record
    }
    
    /// Schedule a retry sync with exponential backoff
    private func scheduleRetrySync() {
        saveToCloudKitCancellable = Just(())
            .delay(for: .seconds(10), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.saveToCloudKit()
                }
            }
    }
}

// MARK: - Money Transaction Extensions
extension UserModel {
    
    /// Safely deduct money with validation and CloudKit tracking
    func deductMoney(amount: Double) -> Bool {
        guard let currentMoney = playerMoney, currentMoney >= amount else {
            return false
        }
        
        let newAmount = currentMoney - amount
        playerMoney = newAmount
        
        // The property observer will handle CloudKit sync
        return true
    }
    
    /// Add money with CloudKit tracking
    func addMoney(amount: Double) {
        let currentMoney = playerMoney ?? 0
        playerMoney = currentMoney + amount
        
        // The property observer will handle CloudKit sync
    }
    
    /// Check if player can afford a purchase
    func canAfford(amount: Double) -> Bool {
        guard let currentMoney = playerMoney else { return false }
        return currentMoney >= amount
    }
    
    /// Get current balance safely
    var currentBalance: Double {
        return playerMoney ?? 0
    }
}