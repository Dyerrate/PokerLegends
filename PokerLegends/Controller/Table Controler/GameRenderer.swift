//
//  GameRenderer.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 10/6/24.
//

import TabletopKit
import RealityKit
import SwiftUI
import Combine
import BlackJackProject // Ensure this bundle contains your .rkassets

@MainActor
class GameRenderer: TabletopGame.RenderDelegate {

    // --- Properties ---
    let root: Entity
    let rootOffset: Vector3D = .init(x: 0, y: -0.7, z: 0)
    let typeOfGame: String

    weak var blackJackGame: BlackJackGame?
    var gameSetup: GameSetup?

    // --- Scene Management ---
    private var lobbySceneEntity: Entity?
    var mainGameSceneEntity: Entity?

    // --- Entity References (Found within scenes) ---
    private var startButtonEntity: Entity?
    private var closeButtonEntity: Entity?
    private var blackjackTableEntity: Entity?
    private var cardShoeEntity: Entity?
    private var hitButtonEntity: Entity?
    private var standButtonEntity: Entity?
    private var dealerHandAreaMarker: Entity?
    private var playerHandAreaMarkers: [Int: Entity] = [:]

    // --- Card Rendering ---
    var cardEntities: [EquipmentIdentifier: Entity] = [:] // Card Equipment ID -> Instantiated Card Entity
    private var cardPrototypeCache: [String: Entity] = [:] // Cache: "ace_spade" -> Loaded Ace of Spades Entity Prototype

    // Animation Constants
    private let cardDealDuration: TimeInterval = 0.4
    private let cardFlipDuration: TimeInterval = 0.3 // Duration for flip animation
    private let cardSpacing: Float = 0.07

    // --- Initialization ---
    init(typeOfGame: String) {
        self.typeOfGame = typeOfGame
        self.root = Entity()
        self.root.transform.translation = .init(rootOffset)
        print("GameRenderer initialized. Waiting for setupScenesAndReferences call.")
    }

    // --- Scene and Entity Setup ---
    func setupScenesAndReferences() async {
        print("GameRenderer: Setting up scenes and references...")

        // Load Lobby Scene
        self.lobbySceneEntity = await loadSceneAsync(named: "bjLobby")
        if let lobby = lobbySceneEntity {
            root.addChild(lobby)
            lobby.isEnabled = false
            self.startButtonEntity = lobby.findEntity(named: "startBJButton")
            self.closeButtonEntity = lobby.findEntity(named: "closeGameButton")
            verifyInteractionComponents(for: startButtonEntity, name: "startBJButton")
            verifyInteractionComponents(for: closeButtonEntity, name: "closeGameButton")
            self.startButtonEntity?.isEnabled = false
            self.closeButtonEntity?.isEnabled = false
            print("GameRenderer: Lobby scene loaded.")
        } else { print("GameRenderer: ERROR - Failed to load lobby scene 'bjLobby'.") }

        // Load Main Game Scene
        self.mainGameSceneEntity = await loadSceneAsync(named: "bjGameScene")
        if let gameScene = mainGameSceneEntity {
            root.addChild(gameScene)
            gameScene.isEnabled = false
            self.blackjackTableEntity = gameScene.findEntity(named: "BlackjackTable")
            self.cardShoeEntity = gameScene.findEntity(named: "cardSleeve")
            self.hitButtonEntity = gameScene.findEntity(named: "HitButton")
            self.standButtonEntity = gameScene.findEntity(named: "StandButton")
            self.dealerHandAreaMarker = gameScene.findEntity(named: "DealerHandAreaMarker")
            if let setup = self.gameSetup {
                 for i in 0..<setup.seats.count {
                    let markerName = "PlayerHandAreaMarker_\(i)"
                    if let marker = gameScene.findEntity(named: markerName) {
                        self.playerHandAreaMarkers[i] = marker
                    } else { print("GameRenderer: WARNING - Player hand marker '\(markerName)' not found.") }
                 }
            } else { print("GameRenderer: WARNING - GameSetup not available for player hand markers.") }
            verifyInteractionComponents(for: hitButtonEntity, name: "HitButton")
            verifyInteractionComponents(for: standButtonEntity, name: "StandButton")
            self.hitButtonEntity?.isEnabled = false
            self.standButtonEntity?.isEnabled = false
            print("GameRenderer: Main game scene loaded.")
        } else { print("GameRenderer: ERROR - Failed to load main game scene 'bjGameScene'.") }
        print("GameRenderer: Scene and reference setup complete.")
    }

    // Helper for loading scenes
    private func loadSceneAsync(named sceneName: String) async -> Entity? {
        print("GameRenderer: Loading scene '\(sceneName)'...")
        do {
            let sceneEntity = try await Entity(named: sceneName, in: blackJackProjectBundle)
            print("GameRenderer: Scene '\(sceneName)' loaded successfully.")
            return sceneEntity
        } catch {
            print("GameRenderer: ERROR - Failed to load scene '\(sceneName)': \(error)")
            return nil
        }
    }
    // Helper to verify interaction components
    private func verifyInteractionComponents(for entity: Entity?, name: String) {
        guard let entity = entity else { return }
        if entity.components[InputTargetComponent.self] == nil {
            print("GameRenderer: WARNING - Entity '\(name)' is missing InputTargetComponent.")
        }
        if entity.components[CollisionComponent.self] == nil {
            print("GameRenderer: WARNING - Entity '\(name)' is missing CollisionComponent.")
        }
     }

    // Scene Visibility Control
    func showLobbyScene() {
        print("GameRenderer: Showing Lobby Scene")
        mainGameSceneEntity?.isEnabled = false
        hitButtonEntity?.isEnabled = false
        standButtonEntity?.isEnabled = false
        lobbySceneEntity?.isEnabled = true
        startButtonEntity?.isEnabled = true
        closeButtonEntity?.isEnabled = true
        removeAllCardEntities()
     }
    func showMainGameScene() {
        print("GameRenderer: Showing Main Game Scene")
        lobbySceneEntity?.isEnabled = false
        startButtonEntity?.isEnabled = false
        closeButtonEntity?.isEnabled = false
        mainGameSceneEntity?.isEnabled = true
     }

    // --- Card Model Loading ---
    /// Loads (or retrieves from cache) the prototype entity for a specific card USDZ model.
    private func loadCardPrototype(assetName: String) async -> Entity? {
        if let cachedProto = cardPrototypeCache[assetName] {
            return cachedProto
        }
        print("GameRenderer: Loading card prototype USDZ ('\(assetName)')...")
        do {
            let entity = try await Entity(named: assetName, in: blackJackProjectBundle)
            entity.name = "\(assetName)_Proto"
            cardPrototypeCache[assetName] = entity
            print("GameRenderer: Card prototype '\(assetName)' loaded and cached.")
            return entity
        } catch {
            print("GameRenderer: ERROR - Failed to load card prototype USDZ '\(assetName)': \(error)")
            let mesh = MeshResource.generateBox(width: 0.06, height: 0.001, depth: 0.09, cornerRadius: 0.005)
            let material = SimpleMaterial(color: .lightGray, roughness: 0.8, isMetallic: false)
            let fallback = ModelEntity(mesh: mesh, materials: [material])
            fallback.name = "\(assetName)_Proto_Fallback"
            cardPrototypeCache[assetName] = fallback
            return fallback
        }
    }

    /// Clones a card entity from the prototype cache based on PlayingCard data.
    private func cloneCardEntity(for card: PlayingCard) async -> Entity? {
        let assetName = card.assetName
        guard let prototype = await loadCardPrototype(assetName: assetName) else {
            print("GameRenderer: ERROR - Could not get prototype for \(assetName)")
            return nil
        }
        let cardEntity = prototype.clone(recursive: true)
        cardEntity.name = "Card_\(card.description)"
        return cardEntity
    }

    // --- Card Entity Management ---
    /// Finds an existing Entity or creates a new one by cloning the specific card prototype.
    func findOrCreateCardEntity(for equipmentId: EquipmentIdentifier, cardData: PlayingCard) async -> Entity? {
        if let existingEntity = cardEntities[equipmentId] {
            return existingEntity
        } else {
            guard let newEntity = await cloneCardEntity(for: cardData) else {
                print("GameRenderer: ERROR - Failed to clone entity for \(cardData.description)")
                return nil
            }
            newEntity.isEnabled = false
            newEntity.position = getShoeTransform().translation
            mainGameSceneEntity?.addChild(newEntity)
            cardEntities[equipmentId] = newEntity
            return newEntity
        }
    }

    func removeCardEntity(for equipmentId: EquipmentIdentifier) {
        if let entity = cardEntities.removeValue(forKey: equipmentId) {
            print("GameRenderer: Removing entity for card ID \(equipmentId.rawValue)")
            entity.removeFromParent()
        }
     }
    func removeAllCardEntities() {
        print("GameRenderer: Removing all card entities...")
        cardEntities.values.forEach { $0.removeFromParent() }
        cardEntities.removeAll()
     }

    // --- Card Positioning ---
    func getShoeTransform() -> Transform {
        guard let shoe = cardShoeEntity else {
            print("GameRenderer: WARNING - Card shoe entity not found. Using default transform.")
            return Transform(scale: .one, rotation: .init(), translation: [-0.4, 0.1, -0.3])
        }
        return Transform(scale: .one,
                         rotation: shoe.orientation(relativeTo: nil),
                         translation: shoe.position(relativeTo: nil) + [0, 0.05, 0])
     }
    func getTransformForCard(cardIndex: Int, totalCardsInHand: Int, targetMarkerEntity: Entity?) -> Transform {
        guard let marker = targetMarkerEntity else {
            print("WARNING: Target marker entity is nil. Returning default transform.")
            return Transform(scale: .one, rotation: .init(), translation: [0, 0.1, Float(cardIndex) * 0.1])
        }
        let markerWorldPos = marker.position(relativeTo: nil)
        let markerWorldRot = marker.orientation(relativeTo: nil)
        let totalWidth = Float(totalCardsInHand - 1) * cardSpacing
        let startX = -totalWidth / 2.0
        let cardX = startX + Float(cardIndex) * cardSpacing
        let cardY: Float = 0.002
        let cardZ: Float = 0.0
        let relativePos: SIMD3<Float> = [cardX, cardY, cardZ]
        let worldPos = markerWorldPos + markerWorldRot.act(relativePos)
        let cardRotation = markerWorldRot
        return Transform(scale: .one, rotation: cardRotation, translation: worldPos)
     }
    func getTransformForPlayerCard(cardIndex: Int, totalCardsInHand: Int, seatIndex: Int) -> Transform {
        return getTransformForCard(cardIndex: cardIndex,
                                   totalCardsInHand: totalCardsInHand,
                                   targetMarkerEntity: playerHandAreaMarkers[seatIndex])
     }
    func getTransformForDealerCard(cardIndex: Int, totalCardsInHand: Int) -> Transform {
        return getTransformForCard(cardIndex: cardIndex,
                                   totalCardsInHand: totalCardsInHand,
                                   targetMarkerEntity: dealerHandAreaMarker)
     }

    // --- Card Animations ---
    func animateDealCard(cardEntity: Entity, from startTransform: Transform, to endTransform: Transform, faceUp: Bool, delay: TimeInterval = 0.0, completion: (() -> Void)? = nil) {
        print("GameRenderer: Animating deal for \(cardEntity.name) to faceUp: \(faceUp)")
        cardEntity.transform = startTransform
        cardEntity.isEnabled = true
        var finalTransform = endTransform
        if !faceUp {
            let flipRotation = simd_quatf(angle: .pi, axis: [0, 1, 0])
            finalTransform.rotation = endTransform.rotation * flipRotation
        } else {
             finalTransform.rotation = endTransform.rotation
        }

        Task {
            if delay > 0 { try? await Task.sleep(for: .seconds(delay)) }
            _ = cardEntity.move(to: finalTransform, relativeTo: nil, duration: cardDealDuration, timingFunction: .easeInOut)
            try? await Task.sleep(for: .seconds(cardDealDuration))
            cardEntity.transform = finalTransform
            print("GameRenderer: Animation complete for \(cardEntity.name)")
            completion?()
        }
    }

     func animateFlipCard(cardEntity: Entity, faceUp: Bool, completion: (() -> Void)? = nil) {
         print("GameRenderer: Animating flip for \(cardEntity.name) to faceUp: \(faceUp)")
         var targetTransform = cardEntity.transform
         let currentRotation = targetTransform.rotation
         let yAxis: SIMD3<Float> = [0, 1, 0]
         let flipRotation = simd_quatf(angle: .pi, axis: yAxis)
         let targetFaceUpRotation = currentRotation * (currentRotation.isFaceDown ? flipRotation : simd_quatf())
         let targetFaceDownRotation = currentRotation * (currentRotation.isFaceUp ? flipRotation : simd_quatf())
         targetTransform.rotation = faceUp ? targetFaceUpRotation : targetFaceDownRotation

         // --- Use dot product for quaternion comparison ---
         let dotProduct = simd_dot(targetTransform.rotation, currentRotation)
         let tolerance: Float = 0.001 // Tolerance for dot product check near 1.0 or -1.0

         // Check if the absolute value of the dot product is close to 1
         if abs(dotProduct) > (1.0 - tolerance) {
              print("GameRenderer: Flip animation skipped, already in target orientation (dot check).")
              completion?()
              return
         }
         // --- End of change ---

         _ = cardEntity.move(to: targetTransform, relativeTo: nil, duration: cardFlipDuration, timingFunction: .easeInOut)

         Task {
             try? await Task.sleep(for: .seconds(cardFlipDuration))
             cardEntity.transform = targetTransform
             print("GameRenderer: Flip animation complete for \(cardEntity.name)")
             completion?()
         }
     }

    // --- Visual Feedback ---
    func highlightPlayerArea(seatIndex: Int, highlight: Bool) {
        print("GameRenderer: \(highlight ? "Highlighting" : "Unhighlighting") player area \(seatIndex)")
     }
    func updateStatusText(text: String?, for targetAreaId: EquipmentIdentifier, offset: SIMD3<Float> = [0, 0.05, 0]) {
         print("GameRenderer: Updating status text to '\(text ?? "nil")' for area ID \(targetAreaId.rawValue)")
     }

    // --- Button Enable/Disable ---
    func setActionButtonsEnabled(_ enabled: Bool) {
        print("GameRenderer: Setting Hit/Stand buttons enabled: \(enabled)")
        hitButtonEntity?.isEnabled = enabled
        standButtonEntity?.isEnabled = enabled
     }

    // --- Cleanup ---
    func cleanup() {
        print("GameRenderer: Cleaning up...")
        removeAllCardEntities()
        lobbySceneEntity?.removeFromParent(); mainGameSceneEntity?.removeFromParent()
        lobbySceneEntity = nil; mainGameSceneEntity = nil
        startButtonEntity = nil; closeButtonEntity = nil
        hitButtonEntity = nil; standButtonEntity = nil
        blackjackTableEntity = nil; cardShoeEntity = nil
        dealerHandAreaMarker = nil; playerHandAreaMarkers.removeAll()
        cardPrototypeCache.removeAll() // Clear prototype cache
        root.children.removeAll()
    }
}
