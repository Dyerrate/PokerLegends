//
//  GameRenderer.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 10/6/24.
//

import TabletopKit
import RealityKit
import SwiftUI
import UIKit
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
    private var blackjackTableEntity: Entity?
    private var cardMainDeck: Entity?
    private var cardTemplate: Entity?
    private var cardShoeEntity: Entity?

    private var dealerHandAreaMarker: Entity?
    private var playerHandAreaMarkers: [Int: Entity] = [:]
    private var dealerHoleCardAlreadyFlipped = false
    
    //Button Entitys
    private var startButtonEntity: Entity?
    private var closeButtonEntity: Entity?
    private var hitButtonEntity: Entity?
    private var standButtonEntity: Entity?
    private var betttingReadyCheckButton: Entity?
    private var betZoneTrigger: Entity?
    
    //Poker Chip Trays
    private var pokerChipTray: Entity?
    
    //Parent Chips
    private var blueParentChip: Entity?
    private var greenParentChip: Entity?
    private var redParentChip: Entity?

    //Active Tracking
    @State var activeCards: [Entity] = []
    @State var activeChips: [Entity] = []



    // --- Card Rendering ---
    var cardEntities: [EquipmentIdentifier: Entity] = [:] // Card Equipment ID -> Instantiated Card Entity
    private var cardPrototypeCache: [String: Entity] = [:] // Cache: "ace_spade" -> Loaded Ace of Spades Entity Prototype

    // Animation Constants
    private let cardDealDuration: TimeInterval = 0.4
    private let cardFlipDuration: TimeInterval = 0.3 // Duration for flip animation
    private let cardSpacing: Float = 0.07
    private let cardFlipAnimationName = "group"
    var dealerHoleCardId: Entity?  // <- NEW

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
            root.addChild(lobby); lobby.isEnabled = false
            self.startButtonEntity = lobby.findEntity(named: "startBJButton")
            self.closeButtonEntity = lobby.findEntity(named: "closeGameButton")
            // --- Added Print for Lobby Buttons ---
//            print("GameRenderer: Found startBJButton? \(self.startButtonEntity != nil)")
//            print("GameRenderer: Found closeGameButton? \(self.closeButtonEntity != nil)")
            // ---
            verifyInteractionComponents(for: startButtonEntity, name: "startBJButton")
            verifyInteractionComponents(for: closeButtonEntity, name: "closeGameButton")
            self.startButtonEntity?.isEnabled = false; self.closeButtonEntity?.isEnabled = false
            print("GameRenderer: Lobby scene loaded.")
        } else { print("GameRenderer: ERROR - Failed to load lobby scene 'bjLobby'.") }
        // Load Main Game Scene
        self.mainGameSceneEntity = await loadSceneAsync(named: "bjGameScene")
        if let gameScene = mainGameSceneEntity {
            
            root.addChild(gameScene)
            gameScene.isEnabled = false

            // Find game entities using recursive search
            self.blackjackTableEntity = gameScene.findEntity(named: "blackJackTable")
            self.cardShoeEntity = gameScene.findEntity(named: "cardSleeve")
            self.hitButtonEntity = gameScene.findEntity(named: "hitButton")
            self.standButtonEntity = gameScene.findEntity(named: "standButton")
            self.dealerHandAreaMarker = gameScene.findEntity(named: "DealerHandAreaMarker")
            self.cardMainDeck = gameScene.findEntity(named: "cardMainDeck")
            self.cardTemplate = gameScene.findEntity(named: "cardTemplate")
            self.betttingReadyCheckButton = gameScene.findEntity(named: "bettingReadyCheck")
            self.pokerChipTray = gameScene.findEntity(named: "trayInitalState")
            
            self.greenParentChip = gameScene.findEntity(named: "greenChip_Element")
            self.blueParentChip = gameScene.findEntity(named: "blueChip_Element")
            self.redParentChip = gameScene.findEntity(named: "redChip_Element")
            
            self.betZoneTrigger = gameScene.findEntity(named: "betZoneTrigger")
            
            // --- Added Print for Game Entities ---
            print("GameRenderer: Found BlackjackTable? \(self.blackjackTableEntity != nil)")
            print("GameRenderer: Found cardSleeve? \(self.cardShoeEntity != nil)")
            print("GameRenderer: Found HitButton? \(self.hitButtonEntity?.position != nil)")
            print("GameRenderer: Found StandButton? \(self.standButtonEntity != nil)")
            print("GameRenderer: Found DealerHandAreaMarker? \(self.dealerHandAreaMarker != nil)")
            print("GameRenderer: Found cardMainDeck? \(self.cardMainDeck != nil)")
            print("GameRenderer: Found cardTemplate? \(self.cardTemplate != nil)")
            // ---

            if self.cardShoeEntity == nil { print("GameRenderer: ERROR - Card shoe 'cardSleeve' not found in bjGameScene.") }
            if self.dealerHandAreaMarker == nil { print("GameRenderer: ERROR - DealerHandAreaMarker not found in bjGameScene.") }

            if let setup = self.gameSetup {
                 print("GameRenderer: Searching for Player Hand Markers (0-\(setup.seats.count - 1))...") // Log start of search
                 for i in 0..<setup.seats.count { // Should be 5 seats (0-6)
                    let markerName = "PlayerHandAreaMarker_\(i)"
                    let marker = gameScene.findEntity(named: markerName)
                    if let foundMarker = marker {
                        self.playerHandAreaMarkers[i] = foundMarker
                        print("GameRenderer:   ✅ Found player hand marker '\(markerName)'.")
                    } else {
                        // Log error more prominently if marker is missing
                        print("GameRenderer:   ❌ ERROR - Player hand marker '\(markerName)' not found. Card positioning for seat \(i) will fail.") // Log failure for each
                    }
                 }
            } else { print("GameRenderer: WARNING - GameSetup not available for player hand markers.") }

            verifyInteractionComponents(for: hitButtonEntity, name: "HitButton")
            verifyInteractionComponents(for: standButtonEntity, name: "StandButton")
            self.hitButtonEntity?.isEnabled = false
            self.standButtonEntity?.isEnabled = false
            self.betttingReadyCheckButton?.isEnabled = false
            self.pokerChipTray?.components.remove(InputTargetComponent.self)
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
        //addPlayerActionButtons()
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
            entity.name = "\(assetName)"
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
    //Creating UI button for user to push in game
    func createButton(title: String,
                      baseColor: UIColor,
                      name: String) -> Entity {

        // Base cylinder
        let cylinder = MeshResource.generateCylinder(height: 0.005, radius: 0.05)
        let material = SimpleMaterial(color: baseColor, isMetallic: true)
        let button   = ModelEntity(mesh: cylinder, materials: [material])
        button.name  = name

        // = Tap support =
        button.generateCollisionShapes(recursive: true)
        button.components.set(InputTargetComponent())      // Tap detection
        button.components.set(HoverEffectComponent())      // 👁 automatic hover ring

        // Text label
        let textMesh  = MeshResource.generateText(title,
                                                  extrusionDepth: 0.002,
                                                  font: .boldSystemFont(ofSize: 0.05))
        let textMat   = SimpleMaterial(color: .white, isMetallic: false)
        let labelEnt  = ModelEntity(mesh: textMesh, materials: [textMat])
        labelEnt.scale      = [1,1,1] * 2
        labelEnt.position   = [-0.025, 0.01, 0]
        button.addChild(labelEnt)

        return button
    }
    
    func addPlayerActionButtons() {
        // (Grab your anchor that already holds the table)
        let anchor = self.blackjackTableEntity

        let hit   = createButton(title: "Hit",
                                 baseColor: .systemRed,
                                 name: "HitButton")
        hit.position   = [ 0.25, 1.015, 1]

        let stand = createButton(title: "Stand",
                                 baseColor: .systemRed,
                                 name: "StandButton")
        stand.position = [-0.25, 1.015, 0.5]

        anchor!.addChild(hit)
        anchor!.addChild(stand)
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
        print("🛠  cloneCardEntity → created \(cardEntity.name)")
        return cardEntity
    }

    // --- Card Entity Management ---
    /// Finds an existing Entity or creates a new one by cloning the specific card prototype.
    func findOrCreateCardEntity(for equipmentId: EquipmentIdentifier, cardData: PlayingCard) async -> Entity? {
        if let existingEntity = cardEntities[equipmentId] {
            // Ensure existing entity has correct orientation
            return existingEntity
        } else {
            guard let newEntity = await cloneCardEntity(for: cardData) else {
                print("GameRenderer: ERROR - Failed to clone entity for \(cardData.description)")
                return nil
            }
            // --- Set initial orientation based on our definitions ---
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
        dealerHoleCardAlreadyFlipped = false
        cardEntities.removeAll()
     }
    func newRemoveAllCards() {
        print("thought we removed all")
        self.activeCards.removeAll()
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
            print("[getTransformForCard] WARNING: Target marker entity is nil. Returning default transform.")
            return Transform(scale: .one, rotation: .init(), translation: [0, 0.1, Float(cardIndex) * 0.1])
        }

        let referenceEntity = self.blackjackTableEntity
        let referenceFrameName = referenceEntity?.name ?? "nil (World)"

        // 1. Get marker's base position and rotation relative to the table
        let markerPosRelativeToRef = marker.position(relativeTo: referenceEntity)
        let markerRotRelativeToRef = marker.orientation(relativeTo: referenceEntity)

        // 2. Calculate the SMALL offset for fanning/lifting relative to the marker's center
        let totalWidth = Float(totalCardsInHand - 1) * cardSpacing
        let startX = -totalWidth / 2.0
        let cardX = startX + Float(cardIndex) * cardSpacing
        let cardY: Float = 0.002 // Use a small constant Y offset again
        let cardZ: Float = 0.0   // Use a constant Z offset (usually 0)
        let offsetInMarkerSpace: SIMD3<Float> = [cardX, cardY, cardZ] // This is JUST the offset

        // 3. Rotate the small offset vector by the marker's rotation
        let rotatedOffset = markerRotRelativeToRef.act(offsetInMarkerSpace)

        // 4. ADD the rotated offset TO the marker's base position
        let finalPosRelativeToRef = markerPosRelativeToRef + rotatedOffset

        // 5. The card's base rotation matches the marker's rotation
        let finalRotRelativeToRef = markerRotRelativeToRef

        // --- Optional: Keep logs if helpful ---
        print("--- getTransformForCard Corrected ---")
        print("  Target Marker: \(marker.name)")
        print("  Marker Pos (rel to \(referenceFrameName)): \(markerPosRelativeToRef)")
        print("  Offset (in marker space): \(offsetInMarkerSpace)")
        print("  Rotated Offset: \(rotatedOffset)")
        print("  Final Pos (rel to \(referenceFrameName)): \(finalPosRelativeToRef)")
        print("---------------------------------")
        // ---

        return Transform(scale: .one, rotation: finalRotRelativeToRef, translation: finalPosRelativeToRef)
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
    
    //---------------- New Start -------------------
    func printAnimationsRecursively(for entity: Entity, depth: Int = 0) {
        let indent = String(repeating: "  ", count: depth)
        print("\(indent)🧩 \(entity.name)")
        if !entity.availableAnimations.isEmpty {
            print("\(indent)🔹 \(entity.name) has animations:")
            for anim in entity.availableAnimations {
                print("\(indent)   🎞️ \(anim.name)")
            }
        }
        for child in entity.children {
            printAnimationsRecursively(for: child, depth: depth + 1)
        }
    }
    
    func generateCardTemplateEntity(currentCardEntity: Entity?) -> Entity {
        let tag = UUID().uuidString.prefix(6)   // short unique id

         print("🎬 [\(tag)] GENERATE template for \(currentCardEntity?.name ?? "nil")")
        print("GameRender: generateCardTemplateEntity is starting...").self
        printAnimationsRecursively(for: self.cardTemplate!)
        
        guard let createdCardTemplate = self.cardTemplate?.clone(recursive: true) else {
            fatalError("CardTemplate missing")
        }
        printAnimationsRecursively(for: createdCardTemplate)
        guard let sleeve = createdCardTemplate.findEntity(named: "cardTemplate") else {
            fatalError("CardSleeve entity not found in CardTemplate!")
        }
        let sleeveBounds = sleeve.visualBounds(relativeTo: nil)
        let sleeveSize = sleeveBounds.extents
        print("🪄 Sleeve size from cloned template: \(sleeveSize)")

        guard let currentPlayerCard = currentCardEntity else {
            fatalError("Current card entity is nil")
        }
        guard let pivot  = createdCardTemplate.findEntity(named: "FlipPivot") else {
            fatalError("AHHHH")
        }


        print("GameRender: this is the current card \(currentPlayerCard.name) A QUICK CHECK")
        createdCardTemplate.name = currentPlayerCard.name
        print("📦 START ENTITY TREE + ANIMATIONS")
        printAnimationsRecursively(for: createdCardTemplate)

        // Place the card template where the main deck sits
        if let deckPosition = self.cardMainDeck?.position {
            print("🎯 Card target position: \(deckPosition)")
            createdCardTemplate.position = deckPosition
        } else {
            print("⚠️ Warning: cardMainDeck position is missing!")
        }
        // Load and configure the visual card mesh
        let visualGroup = extractCardModelGroup(from: currentPlayerCard,targetSize: sleeveSize)
        visualGroup.name = "CardVisual"
        pivot.transform = .identity
        if let m = (pivot as? ModelEntity) { m.model = nil }

        // Add it to the cloned template
        pivot.addChild(visualGroup)
        printEntityTree(createdCardTemplate)
        printEntityTree(self.cardTemplate!)
        createdCardTemplate.isEnabled = true      // 👈 ADD THIS LINE

        // Log final bounds for confirmation
        return createdCardTemplate
    }

    
    //INFO: Final add players new card to table
    func addPlayerCard(currentCard: Entity, playerSeat: Int, cardIndex: Int) {
        
        guard let targetSlot = self.mainGameSceneEntity!.findEntity(named: "PlayerHandAreaMarker_\(playerSeat)") else {
            fatalError("⚠️ Couldn't find card slot!")
        }
        let stackingOffset = SIMD3<Float>(Float(cardIndex) * 0.175, 0.00019, 0)
        let worldTarget = targetSlot.convert(position: stackingOffset, to: nil)
        let gameScene = self.mainGameSceneEntity
        gameScene!.addChild(currentCard)
        
        let finalTransform = Transform(
            scale: currentCard.transform.scale,
            rotation: currentCard.transform.rotation,
            translation: worldTarget
        )

        currentCard.move(
            to: finalTransform,
            relativeTo: nil,
            duration: 0.6,
            timingFunction: .easeInOut
        )
        self.activeCards.append(currentCard)
        Task { @MainActor in
            
            await playFlip(on: currentCard, toFaceUp: true)
        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
//            if let anim = currentCard.availableAnimations.first(where: { $0.name == "group" }) {
//                currentCard.playAnimation(anim)
//            }
//        }
        
    }
    
    func addDealerCard(currentCard: Entity, cardIndex: Int) {
        print("📌 addDealerCard ▶︎ index \(cardIndex) -> \(currentCard.name)")

        guard let dealerSlot = self.mainGameSceneEntity!.findEntity(named: "DealerHandAreaMarker") else {
            fatalError("⚠️ Couldn't find DEALER card slot!")
        }
        
        let stackingOffset = SIMD3<Float>(Float(cardIndex) * 0.025, 0.001 , 0)
        let worldTarget = dealerSlot.convert(position: stackingOffset, to: nil)
        
        
        let gameScene = self.mainGameSceneEntity
        gameScene!.addChild(currentCard)
        
        let finalTransform = Transform(
            scale: currentCard.transform.scale,
            rotation: currentCard.transform.rotation,
            translation: worldTarget
        )

        currentCard.move(
            to: finalTransform,
            relativeTo: nil,
            duration: 0.6,
            timingFunction: .easeInOut
        )
        self.activeCards.append(currentCard)
        print("📌 addDealerCard ▶︎ move() scheduled, finalPos = \(finalTransform.translation)")

        if(cardIndex == 0 || cardIndex > 1) {
            
            Task { @MainActor in
                
               await playFlip(on: currentCard, toFaceUp: true)
            }
            }
        if cardIndex == 1 {
            dealerHoleCardId = currentCard            
        }
       
    }
    
    func revealDealerHoleCard() {
        print("revealDealerHoleCard")
        print("🗂  cardEntities now contains:")
        for (id, ent) in cardEntities {
            print("     id \(id.rawValue)  → \(ent.name)")
        }
        guard let e = dealerHoleCardId, !dealerHoleCardAlreadyFlipped else { return }
        dealerHoleCardAlreadyFlipped = true
        Task { @MainActor in
           await playFlip(on: e, toFaceUp: true)            // one-liner
            try? await Task.sleep(for: .seconds(2.5))

        }
    }
    
    private func playFlip(on root: Entity, toFaceUp: Bool) async -> Void {
        guard let pivot = root.findEntity(named: "FlipPivot") else {
            print("[Renderer] ⚠️ FlipPivot not found for \(root.name)"); return
        }
        let wanted = "group"
        if let clip = pivot.availableAnimations.first(where: { $0.name == wanted }) {
            print("⚠️ clip found \(clip)")
            pivot.playAnimation(clip)
        } else {
            print("[Renderer] ⚠️ Clip \(wanted) missing on \(pivot.name)")
        }
    }
    
    //INFO: Just for debugging entity
    func printEntityTree(_ entity: Entity, indent: String = "") {
        print("\(indent)- \(entity.name) [\(type(of: entity))]")
        for child in entity.children {
            printEntityTree(child, indent: indent + "  ")
        }
    }
    func extractCardModelGroup(from root: Entity, targetSize: SIMD3<Float>) -> Entity {
        let container = Entity()
        
        func recursiveSearch(entity: Entity) {
            for child in entity.children {
                if let model = child as? ModelEntity {
                    let clonedModel = model.clone(recursive: true)
                    container.addChild(clonedModel)

                    // Log unscaled bounds for visibility
                    let rawBounds = clonedModel.visualBounds(relativeTo: nil)
                    print("🧩 ModelEntity '\(model.name)' raw bounds:")
                    print("    Center: \(rawBounds.center)")
                    print("    Extents: \(rawBounds.extents)")
                } else {
                    recursiveSearch(entity: child)
                }
            }
        }
        recursiveSearch(entity: root)

        // Measure bounds of full visual group
        let bounds = container.visualBounds(relativeTo: nil)
        let currentSize = bounds.extents * 0.5
        let scaleRatioX = (targetSize.x / currentSize.x) * 3
        let scaleRatioZ = (targetSize.z / currentSize.z) * 0.5
        let uniformScale = min(scaleRatioX, scaleRatioZ)

        let scaleFactor = uniformScale
        print("🧮 Final group bounds before scale:")
        print("    Center: \(bounds.center)")
        print("    Extents: \(bounds.extents)")
        print("📏 Group size before scale: \(currentSize)")
        print("📐 Applying uniform scale factor: \(scaleFactor)")
        // ✅ Apply scale to entire container (includes geometry offsets)
        container.scale = SIMD3<Float>(repeating: scaleFactor)
        container.position = -bounds.center * scaleFactor
        // ✅ Lay flat
        container.orientation =
            simd_quatf(angle: -.pi / 2, axis: [1, 0, 0]) *  // Lay flat
            simd_quatf(angle: .pi, axis: [0, 1, 0]) 

        return container
    }
    func setBettingSettingStart() {
        self.betttingReadyCheckButton?.isEnabled = true
        self.blueParentChip?.isEnabled = false
        self.redParentChip?.isEnabled = false
        self.greenParentChip?.isEnabled = false
        if self.pokerChipTray?.components[InputTargetComponent.self] == nil {
            self.pokerChipTray?.components.set(InputTargetComponent())
        }
        
    }
    
    func spawnPokerChip(at position3D: Point3D, relativeTo reference: Entity,tappedChipColor: String) -> Entity {
        print("GameRenderer 🪩: spawnPokerChip - started")
        var returnedChip: Entity!

        switch tappedChipColor {
        case "red":
            returnedChip = _buildPokerChipHelper(at: position3D, relativeTo: self.redParentChip!, chipValue: 500)
            
        case "green":
            returnedChip =  _buildPokerChipHelper(at: position3D, relativeTo: self.greenParentChip!, chipValue: 100)
        case "blue":
            returnedChip =  _buildPokerChipHelper(at: position3D, relativeTo: self.blueParentChip!, chipValue: 50)
        default:
            print("GameRenderer 🪩: spawnPokerChip - no matching chip color?")
        }
        return returnedChip!
    }
    
    private func _buildPokerChipHelper(at position3D: Point3D, relativeTo reference: Entity, chipValue: Int) -> Entity {
                
        let tray = self.mainGameSceneEntity!
        print("this is the tray?\(tray.name)")
        
        let chip = reference.clone(recursive: true)
        chip.name = "chip-\(UUID().uuidString)"
                
        
        chip.setPosition(self.pokerChipTray!.position(relativeTo: tray), relativeTo: tray)
            chip  .position.y += 1.5
          // Add physics, set to kinematic for hand snapping
        chip.components.set(PokerChipModelComponenet(chipValue: chipValue))
        if chip.components[PhysicsBodyComponent.self] == nil {
            var body = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .dynamic)
            body.linearDamping = 1.5
            body.angularDamping = 2.2
            chip.components.set(body)
        }
        chip.isEnabled = true
          chip.generateCollisionShapes(recursive: true)
        
          tray.addChild(chip)
        return chip
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

