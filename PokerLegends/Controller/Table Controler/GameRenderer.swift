//
//  GameRenderer.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 10/6/24.
//

import TabletopKit
import RealityKit
import SwiftUI // For Color, potentially materials
import Combine // For potential future state bindings if needed
// Assuming BlackJackProject bundle is available
import BlackJackProject

@MainActor
class GameRenderer { // Removed TabletopGame.RenderDelegate for now, can be added back if needed for specific delegate methods

    // --- Properties ---
    let root: Entity // Root for all game content in the scene
    let rootOffset: Vector3D = .init(x: 0, y: -0.7, z: 0) // Offset for positioning
    let typeOfGame: String // To know which game assets/logic to use

    // References to game logic/setup (passed in or set after init)
    // Weak reference to avoid retain cycles if GameRenderer holds reference back
    weak var blackJackGame: BlackJackGame?
    // Direct reference to setup might be useful for getting equipment locations
    
    var gameSetup: GameSetup?
    private var cardModelCache: [String: Entity] = [:]
    private var cardBackEntityProto: Entity? // Prototype for the card back

    // Asset Management
    private var blackjackTableEntity: Entity?
    private var cardShoeEntity: Entity?
    // Dictionary to store created card entities [EquipmentID from Logic -> RealityKit Entity]
    private var cardEntities: [EquipmentIdentifier: Entity] = [:]
    // Dictionary to store references to player area entities if they need manipulation (e.g., highlighting)
    private var playerAreaEntities: [Int: Entity] = [:] // Seat Index -> Entity
    private var dealerAreaEntity: Entity?

    // Animation Constants
    private let cardDealDuration: TimeInterval = 0.4
    private let cardFlipDuration: TimeInterval = 0.3

    // --- Initialization ---
    init(typeOfGame: String) {
        self.typeOfGame = typeOfGame
        self.root = Entity()
        self.root.transform.translation = .init(rootOffset)

        // Start loading assets asynchronously based on game type
        Task {
            if typeOfGame == "blackJack" {
                await loadBlackJackAssets()
            } else {
                // await loadOtherGameAssets(game: typeOfGame)
            }
            // Initial setup might depend on assets loading, consider completion handlers or further async tasks
        }
    }

    // --- Asset Loading ---

    /// Loads assets specific to Blackjack.
    @MainActor
    private func loadBlackJackAssets() async {
        print("GameRenderer: Loading Blackjack assets...")
        do {
            // 1. Load Blackjack Table Model
            // Replace "BlackjackTable_Scene" with your actual scene/entity name in the bundle
            if let tableScene = try? await Entity(named: "BlackjackTable_Scene", in: blackJackProjectBundle) {
                // Find the specific table entity within the loaded scene if necessary
                // e.g., self.blackjackTableEntity = tableScene.findEntity(named: "tableMesh")
                self.blackjackTableEntity = tableScene
                self.blackjackTableEntity?.name = "BlackjackTable"
                // Position the table appropriately (adjust as needed)
                self.blackjackTableEntity?.position = [0, 0, 0] // Relative to root
                root.addChild(self.blackjackTableEntity!)
                print("GameRenderer: Blackjack Table loaded.")
            } else {
                print("GameRenderer: ERROR - Failed to load Blackjack Table asset.")
                // Load a fallback placeholder?
            }

            // 2. Load Card Shoe Model (Optional)
            // Replace "CardShoe_Model" with your actual entity name
            if let shoeModel = try? await Entity(named: "CardShoe_Model", in: blackJackProjectBundle) {
                self.cardShoeEntity = shoeModel
                self.cardShoeEntity?.name = "CardShoe"
                // Position the shoe based on GameSetup's CardShoe equipment pose
                // Note: GameSetup might not be available yet during initial async load.
                // Positioning might need to happen later or be hardcoded if static.
                // Example static position:
                 self.cardShoeEntity?.position = [-0.4, 0.05, -0.3] // Example position relative to root
                 self.cardShoeEntity?.orientation = simd_quatf(angle: -.pi / 12, axis: [0, 1, 0]) // Rotate slightly
                root.addChild(self.cardShoeEntity!)
                print("GameRenderer: Card Shoe loaded.")
            } else {
                print("GameRenderer: WARNING - Failed to load Card Shoe asset. Using placeholder or none.")
                
            }

            // 3. Prepare Visual Areas (Optional - if they have visible meshes)
            // If DealerHandArea, PlayerHandArea, BettingSpot have visual representations
            // defined in GameSetup (e.g., simple planes), load/create them here or
            // get references if they are part of the main table model.
            // Example: dealerAreaEntity = blackjackTableEntity?.findEntity(named: "DealerAreaMesh")
            // Example: playerAreaEntities[seatIndex] = blackjackTableEntity?.findEntity(named: "PlayerArea_\(seatIndex)")

            print("GameRenderer: Blackjack asset loading complete.")

        } catch {
            print("GameRenderer: ERROR - Exception during Blackjack asset loading: \(error)")
        }
    }
    
    // --- NEW: Card Model Loading and Caching ---

      /// Loads the standard card back entity/model.
      private func loadCardBackEntity() async -> Entity? {
          // Replace "Card_Back" with the name of your card back model/entity in the bundle
          let backAssetName = "Card_Back"
          print("GameRenderer: Loading card back prototype ('\(backAssetName)')...")
          do {
              let entity = try await Entity(named: backAssetName, in: blackJackProjectBundle)
              entity.name = "CardBackProto"
              print("GameRenderer: Card back prototype loaded.")
              return entity
          } catch {
              print("GameRenderer: ERROR - Failed to load card back prototype: \(error)")
              // Create a fallback placeholder?
              let mesh = MeshResource.generateBox(width: 0.06, height: 0.001, depth: 0.09)
              let material = SimpleMaterial(color: .blue, isMetallic: false)
              let fallback = ModelEntity(mesh: mesh, materials: [material])
              fallback.name = "CardBackProto_Fallback"
              return fallback
          }
      }


      /// Loads a specific card face model using the cache.
      /// - Parameter assetName: The name of the card face model (e.g., "ace_club").
      /// - Returns: The prototype entity from the cache or newly loaded.
      private func loadCardFacePrototype(assetName: String) async -> Entity? {
          // Check cache first
          if let cachedProto = cardModelCache[assetName] {
              return cachedProto
          }

          // Not in cache, load from bundle
          print("GameRenderer: Loading card face prototype ('\(assetName)')...")
          do {
              let entity = try await Entity(named: assetName, in: blackJackProjectBundle)
              entity.name = "\(assetName)_Proto"
              cardModelCache[assetName] = entity // Store in cache
              print("GameRenderer: Card face prototype '\(assetName)' loaded and cached.")
              return entity
          } catch {
              print("GameRenderer: ERROR - Failed to load card face prototype '\(assetName)': \(error)")
              // Create a fallback placeholder?
               let mesh = MeshResource.generateBox(width: 0.06, height: 0.001, depth: 0.09)
               // Use simple color based on name for fallback
               let color: Color = assetName.contains("heart") || assetName.contains("diamond") ? .red : .black
              let material = SimpleMaterial(color: UIColor.red, isMetallic: false)
               let fallback = ModelEntity(mesh: mesh, materials: [material])
               fallback.name = "\(assetName)_Proto_Fallback"
               cardModelCache[assetName] = fallback // Cache fallback too
              return fallback
          }
      }


    /// Creates a complete card entity (face + back) by cloning prototypes.
    /// - Parameter card: The PlayingCard data.
    /// - Returns: A new Entity representing the card, or nil if prototypes failed to load.
    private func createClonedCardEntity(for card: PlayingCard) async -> Entity? {
        guard let faceProto = await loadCardFacePrototype(assetName: card.assetName) else {
            print("GameRenderer: ERROR - Could not get face prototype for \(card.assetName)")
            return nil
        }
        guard let backProto = self.cardBackEntityProto else {
            print("GameRenderer: ERROR - Card back prototype not loaded.")
            return nil
        }

        // Clone the prototypes
        let cardEntity = Entity() // Create a parent entity for face and back
        cardEntity.name = "Card_\(card.description)"

        let faceEntity = faceProto.clone(recursive: true)
        let backEntity = backProto.clone(recursive: true)

        // --- Assemble the card ---
        // This assumes face and back models are single-sided and aligned correctly
        // when positioned at the same origin. Adjust if your models are different.
        // Back entity might need to be rotated 180 degrees on Y if its front face is the back texture.
        backEntity.orientation = simd_quatf(angle: .pi, axis: [0, 1, 0]) // Rotate back to face opposite direction

        cardEntity.addChild(faceEntity)
        cardEntity.addChild(backEntity)

        // Optional: Add collision shape to cardEntity if needed for interaction
        // let bounds = cardEntity.visualBounds(relativeTo: cardEntity)
        // cardEntity.components.set(CollisionComponent(shapes: [ShapeResource.generateBox(size: bounds.extents).offsetBy(translation: bounds.center)]))

        return cardEntity
    }
    // --- Card Entity Management ---

    /// Finds an existing Entity for a card or creates a new one.
    /// - Parameters:
    ///   - equipmentId: The unique identifier for the card equipment.
    ///   - cardData: The PlayingCard data (rank, suit).
    /// - Returns: The found or newly created Entity for the card.

    // --- Card Entity Management (Updated) ---

    @MainActor
    func findOrCreateCardEntity(for equipmentId: EquipmentIdentifier, cardData: PlayingCard) async -> Entity? {
        if let existingEntity = cardEntities[equipmentId] {
             print("GameRenderer: Found existing entity for card ID \(equipmentId.rawValue)")
             // TODO: Ensure appearance matches cardData if needed (unlikely for same ID)
            return existingEntity
        } else {
            print("GameRenderer: Creating entity for card \(cardData.description) (ID: \(equipmentId.rawValue))")
            // Create by cloning prototypes
            guard let newEntity = await createClonedCardEntity(for: cardData) else {
                print("GameRenderer: ERROR - Failed to create cloned entity for \(cardData.description)")
                return nil
            }
            // Use the name set during cloning ("Card_...")
            // newEntity.name = "Card_\(cardData.description)_\(equipmentId.rawValue)" // Already named
            newEntity.isEnabled = false // Start disabled/hidden until placed/animated
            newEntity.position = [0, 0.5, 0] // Start off-screen or hidden position

            // Add to scene hierarchy (parented to root initially)
            root.addChild(newEntity)

            // Store reference
            cardEntities[equipmentId] = newEntity
            return newEntity
        }
    }

    /// Removes a card entity from the scene and internal tracking.
    /// - Parameter equipmentId: The identifier of the card equipment to remove.
    @MainActor
    func removeCardEntity(for equipmentId: EquipmentIdentifier) {
        if let entity = cardEntities.removeValue(forKey: equipmentId) {
            print("GameRenderer: Removing entity for card ID \(equipmentId.rawValue)")
            entity.removeFromParent()
        }
    }

    /// Removes all card entities currently managed by the renderer.
    @MainActor
    func removeAllCardEntities() {
        print("GameRenderer: Removing all card entities...")
        for entity in cardEntities.values {
            entity.removeFromParent()
        }
        cardEntities.removeAll()
    }


    // --- Card Animations (Called by BlackJackGame) ---

    /// Animates dealing a card from a start point (e.g., shoe) to an end point (e.g., hand area).
    /// - Parameters:
    ///   - cardEntity: The card entity to animate.
    ///   - startTransform: The starting transform (world space).
    ///   - endTransform: The ending transform (world space).
    ///   - faceUp: Should the card land face up?
    ///   - delay: Optional delay before starting the animation.
    ///   - completion: Optional closure called when the animation finishes.
    @MainActor
    func animateDealCard(cardEntity: Entity, from startTransform: Transform, to endTransform: Transform, faceUp: Bool, delay: TimeInterval = 0.0, completion: (() -> Void)? = nil) {

        print("GameRenderer: Animating deal for \(cardEntity.name) to faceUp: \(faceUp)")
        cardEntity.transform = startTransform // Ensure starting position is correct
        cardEntity.isEnabled = true // Make sure entity is visible for animation

        // --- TODO: Implement Flip Animation ---
        // Option 1: Rotate 180 degrees around Y during the move.
        // Option 2: Animate material change or visibility of front/back faces.
        // For simplicity, we'll just set the final orientation for the flip for now.
        var finalTransform = endTransform
        if !faceUp {
            // Apply a 180-degree rotation around Y axis for face-down
            let flipRotation = simd_quatf(angle: .pi, axis: [0, 1, 0])
            finalTransform.rotation = endTransform.rotation * flipRotation
        } else {
             // Ensure it's face up (assuming base model is face up)
             finalTransform.rotation = endTransform.rotation // Or apply identity rotation if needed
        }
        // We might need separate transforms for position and rotation animations.

        // Create the movement animation
        let moveAnimation = cardEntity.move(to: finalTransform, relativeTo: nil, duration: cardDealDuration, timingFunction: .easeInOut)

        // --- TODO: Add Flip Animation Sequence ---
        // A proper flip might involve animating rotation mid-flight.
        // Example placeholder: just move for now.

        // Execute animation after delay
        Task {
            try await Task.sleep(for: .seconds(delay))

            // --- Corrected Line ---
            // Play the animation directly on the moveAnimation controller
            await moveAnimation.resume()

            // Wait for animation to complete (approximately)
            // Note: Waiting for a fixed duration might not be perfectly accurate.
            // Consider using animation events or completion handlers if precision is critical.
            try await Task.sleep(for: .seconds(cardDealDuration))

            // Ensure final state is precise after animation might slightly overshoot/undershoot
            cardEntity.transform = finalTransform
            print("GameRenderer: Animation complete for \(cardEntity.name)")
            completion?() // Call completion handler
        }
    }

     /// Animates flipping a card over in place.
     /// - Parameters:
     ///   - cardEntity: The card entity to flip.
     ///   - faceUp: The target state (true for face up, false for face down).
     ///   - completion: Optional completion handler.
     @MainActor
     func animateFlipCard(cardEntity: Entity, faceUp: Bool, completion: (() -> Void)? = nil) {
         print("GameRenderer: Animating flip for \(cardEntity.name) to faceUp: \(faceUp)")

         // --- TODO: Implement actual flip animation ---
         // This usually involves animating the rotation property around the Y-axis by 180 degrees.
         // You might need to adjust the visual (material/texture) halfway through the rotation.

         // Placeholder: Instant flip by changing orientation
         var currentRotation = cardEntity.orientation(relativeTo: nil)
         let flipRotation = simd_quatf(angle: .pi, axis: [0, 1, 0])

         // Determine if a flip is needed based on current visual state vs target state
         // (Requires knowing the card's current visual orientation)
         // For now, assume we always apply the flip rotation if needed:
         // This logic needs refinement based on how you track the visual state.
         if faceUp { // Assuming model default is face-up
             // If visually face down, rotate to face up
             // cardEntity.orientation = currentRotation * flipRotation // Needs better state check
         } else {
             // If visually face up, rotate to face down
             cardEntity.orientation = currentRotation * flipRotation
         }
         print("GameRenderer: Instant flip applied for \(cardEntity.name)")
         completion?()
     }


    // --- Visual Feedback (Called by BlackJackGame) ---

    /// Highlights or removes highlight from a player's area.
    /// - Parameters:
    ///   - seatIndex: The index of the player seat area to modify.
    ///   - highlight: Boolean indicating whether to add or remove the highlight.
    @MainActor
    func highlightPlayerArea(seatIndex: Int, highlight: Bool) {
        print("GameRenderer: Setting highlight=\(highlight) for player area \(seatIndex)")
        // --- TODO: Implement highlighting ---
        // Option 1: Find a specific highlight entity associated with the area and enable/disable it.
        // Option 2: Change material properties (e.g., emissive color) of the player area mesh itself.
        // guard let areaEntity = playerAreaEntities[seatIndex] else { return }
        // if let model = areaEntity as? ModelEntity {
        //     if highlight {
        //         // Apply highlight material/effect
        //     } else {
        //         // Restore original material/effect
        //     }
        // }
    }

    /// Displays or updates status text (e.g., "Bust", "Blackjack", score) near a hand area.
    /// - Parameters:
    ///   - text: The string to display (or nil to clear).
    ///   - targetAreaId: The EquipmentIdentifier of the hand area (Player or Dealer).
    ///   - offset: Optional offset from the area's center.
    @MainActor
    func updateStatusText(text: String?, for targetAreaId: EquipmentIdentifier, offset: SIMD3<Float> = [0, 0.05, 0]) {
         print("GameRenderer: Updating status text to '\(text ?? "nil")' for area ID \(targetAreaId.rawValue)")
         // --- TODO: Implement text rendering ---
         // Option 1: Create/find/update a ModelEntity with a generated Text MeshResource.
         // Option 2: Use a pre-made text entity in your scene and update its text component.
         // Remember to position it relative to the target area's entity.
         // Needs a way to find the entity associated with targetAreaId (dealer or player hand area).
    }

    // --- Cleanup ---
    func cleanup() {
        // Called when the game view is disappearing
        print("GameRenderer: Cleaning up...")
        removeAllCardEntities()
        // Remove other entities, cancel tasks, etc.
        root.children.removeAll()
    }
}
// Helper extension to check visual orientation (basic example)
extension simd_quatf {
    // This is a simplified check assuming identity rotation is face-up
    // and a 180-degree Y rotation means face-down. Might need adjustment.
    var isFaceUp: Bool {
        // Check if rotation around Y is close to 0 or 2*pi
        let angle = self.angle
        let axis = self.axis
        return abs(axis.y) < 0.1 || abs(angle) < 0.1 || abs(angle - .pi * 2) < 0.1
    }
    var isFaceDown: Bool {
         // Check if rotation around Y is close to pi
        let angle = self.angle
        let axis = self.axis
        return abs(axis.y - 1.0) < 0.1 && abs(angle - .pi) < 0.1
    }
}
