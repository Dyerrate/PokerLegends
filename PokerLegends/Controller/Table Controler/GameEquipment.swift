//
//  GameEquipment.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 10/13/24.
//
import TabletopKit
import RealityKit
import SwiftUI // Import SwiftUI for Color
// Assuming BlackJackProject bundle is available if needed for assets
// import BlackJackProject
import Spatial

// --- Existing Equipment Definitions ---
extension EquipmentIdentifier {
    static var tableID: Self { .init(0) }
    // Define static IDs for clarity if preferred
    static var dealerHandAreaID: Self { .init(100) }
    static var cardShoeID: Self { .init(101) }
}

struct Table: Tabletop {
    var shape: TabletopShape = .rectangular(width: GameMetrics.tableEdge, height: GameMetrics.tableEdge, thickness: 0)
    var id: EquipmentIdentifier = .tableID
}

struct Board: Equipment { // Keep if needed for other games or common elements
    let id: ID
    var initialState: BaseEquipmentState {
        .init(parentID: .tableID,
              seatControl: .restricted([]),
              pose: .init(position: .init(), rotation: .degrees(45)), // Example pose
              boundingBox: .init(center: .zero, size: .init(GameMetrics.tableEdge, GameMetrics.tableEdge, GameMetrics.tableEdge)))
    }
}

struct PlayerSeat: TableSeat {
    let id: ID
    var initialState: TableSeatState

    /* Using 5 seats typical for Blackjack, arranged in an arc */
    @MainActor static let seatPoses: [TableVisualState.Pose2D] = {
        let radius: Double = Double(GameMetrics.tableEdge) * 0.8 // Adjust radius as needed
        let totalAngle: Double = .pi * 0.8 // Arc angle (e.g., 144 degrees)
        let angleStep = totalAngle / Double(5 - 1) // Angle between seats
        let startAngle = -totalAngle / 2.0 // Start from the left

        return (0..<5).map { index in
            let angle = startAngle + Double(index) * angleStep
            let x = radius * sin(angle)
            let z = radius * cos(angle) // Position along the Z-axis (closer/further)
            let rotation = Angle2D(radians: -angle) // Seats face the center (0,0)
            return .init(position: .init(x: x, z: z + 0.1), rotation: rotation) // Adjust z offset if needed
        }
    }()

    init(id: TableSeatIdentifier, pose: TableVisualState.Pose2D) {
        self.id = id
        let spatialSeatPose: TableVisualState.Pose2D = .init(position: pose.position,
                                                             rotation: pose.rotation)
        initialState = .init(pose: spatialSeatPose)
    }
}

// --- Blackjack Specific Equipment Definitions ---

/// Represents the area where the dealer's hand is placed.
struct DealerHandArea: Equipment {
    let id: EquipmentIdentifier = .dealerHandAreaID // Use static ID

    var initialState: BaseEquipmentState {
        .init(parentID: .tableID,
              seatControl: .restricted([]), // No player controls this directly
              pose: .init(position: .init(x: 0, z: -0.3), rotation: .degrees(0)), // Position in front of dealer
              boundingBox: .init(center: .zero, size: .init(x: 0.3, y: 0.01, z: 0.15))) // Define size
    }
}

/// Represents the area in front of a player seat for their hand.
struct PlayerHandArea: Equipment {
    let id: EquipmentIdentifier // Unique ID per instance
    let associatedSeatIndex: Int // Store the index directly

    private static let offsetFromSeat: TableVisualState.Pose2D = .init(
        position: .init(x: 0, z: -0.15), // Position slightly in front of the seat center
        rotation: .zero // Align with seat rotation
    )

    init(id: EquipmentIdentifier, seatIndex: Int) {
        self.id = id
        self.associatedSeatIndex = seatIndex
    }

    var initialState: BaseEquipmentState {
        guard let seatPose = PlayerSeat.seatPoses[safe: associatedSeatIndex] else {
            print("Warning: Invalid seat index \(associatedSeatIndex) for PlayerHandArea \(id)")
            return .init(parentID: .tableID, seatControl: .restricted([]), pose: .init(), boundingBox: .init(center: .zero, size: .init(x: 0.25, y: 0.01, z: 0.15)))
        }
        let absolutePose = Self.offsetFromSeat * seatPose
        let associatedSeatId = TableSeatIdentifier(associatedSeatIndex)

        return .init(parentID: .tableID,
                     seatControl: .restricted([associatedSeatId]),
                     pose: absolutePose,
                     boundingBox: .init(center: .zero, size: .init(x: 0.25, y: 0.01, z: 0.15)))
    }
}

/// Represents the area in front of a player seat for placing bets.
struct BettingSpot: Equipment {
    let id: EquipmentIdentifier // Unique ID per instance
    let associatedSeatIndex: Int // Store the index directly

    private static let offsetFromSeat: TableVisualState.Pose2D = .init(
        position: .init(x: 0, z: -0.30), // Position further in front of the seat than the hand area
        rotation: .zero // Align with seat rotation
    )

    init(id: EquipmentIdentifier, seatIndex: Int) {
        self.id = id
        self.associatedSeatIndex = seatIndex
    }

    var initialState: BaseEquipmentState {
        guard let seatPose = PlayerSeat.seatPoses[safe: associatedSeatIndex] else {
             print("Warning: Invalid seat index \(associatedSeatIndex) for BettingSpot \(id)")
             return .init(parentID: .tableID, seatControl: .restricted([]), pose: .init(), boundingBox: .init(center: .zero, size: .init(x: 0.1, y: 0.01, z: 0.1)))
        }
        let absolutePose = Self.offsetFromSeat * seatPose
        let associatedSeatId = TableSeatIdentifier(associatedSeatIndex)

        return .init(parentID: .tableID,
                     seatControl: .restricted([associatedSeatId]),
                     pose: absolutePose,
                     boundingBox: .init(center: .zero, size: .init(x: 0.1, y: 0.01, z: 0.1)))
    }
}

/// Represents the card shoe holding multiple decks.
struct CardShoe: Equipment {
    let id: EquipmentIdentifier = .cardShoeID // Use static ID

    var initialState: BaseEquipmentState {
        .init(parentID: .tableID,
              seatControl: .restricted([]), // Usually only dealer interacts (programmatically)
              pose: .init(position: .init(x: -0.4, z: -0.3), rotation: .degrees(-15)), // Position to the dealer's left (example)
              boundingBox: .init(center: .zero, size: .init(x: 0.1, y: 0.1, z: 0.2))) // Define size
    }
}


// --- Updated/New Card Representation ---

struct PlayingCardEquipment: Equipment { // Conforms to Equipment
    let id: EquipmentIdentifier
    let playingCard: PlayingCard

    // --- Corrected initialState ---
    var initialState: BaseEquipmentState {
        // Set initial parent to the Card Shoe's ID.
        // The card's pose will be updated dynamically when dealt by BlackJackGame/GameRenderer.
        .init(parentID: .cardShoeID, // Use CardShoe static ID
              pose: .init(position: .init(x: 0, z: 0), rotation: .zero), // Position relative to parent (shoe)
              boundingBox: .init(center: .zero, size: .init(x: 0.06, y: 0.001, z: 0.09))) // Approx card size
    }

    init(id: EquipmentIdentifier, card: PlayingCard) {
        self.id = id
        self.playingCard = card
    }
}


// --- Utility Extension ---
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// Helper to convert Rank/Suit to asset names (adjust if your names differ)
extension PlayingCard {
    var assetName: String {
        let rankString: String
        switch self.rank {
            case .ace: rankString = "ace"
            case .king: rankString = "king"
            case .queen: rankString = "queen"
            case .jack: rankString = "jack"
            case .ten: rankString = "10" // Assuming T is not used
            default: rankString = String(self.rank.rawValue)
        }

        let suitString: String
        switch self.suit {
            case .hearts: suitString = "heart"
            case .diamonds: suitString = "diamond"
            case .clubs: suitString = "club"
            case .spades: suitString = "spade"
        }
        // Example: "ace_club", "2_heart", "king_spade"
        return "\(rankString)_\(suitString)"
    }
}
