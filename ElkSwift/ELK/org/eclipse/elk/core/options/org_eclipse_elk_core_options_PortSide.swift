import Foundation

/**
 * Definition of port sides on a node.
 */
internal enum PortSide: String, Hashable {
    case UNDEFINED
    case NORTH
    case EAST
    case SOUTH
    case WEST

    // Lowercase aliases for compatibility
    internal static var undefined: PortSide { .UNDEFINED }
    internal static var north: PortSide { .NORTH }
    internal static var east: PortSide { .EAST }
    internal static var south: PortSide { .SOUTH }
    internal static var west: PortSide { .WEST }

    // Port Side Combinations
    internal static let SIDES_NONE: Set<PortSide> = []
    internal static let SIDES_NORTH: Set<PortSide> = [.NORTH]
    internal static let SIDES_EAST: Set<PortSide> = [.EAST]
    internal static let SIDES_SOUTH: Set<PortSide> = [.SOUTH]
    internal static let SIDES_WEST: Set<PortSide> = [.WEST]
    internal static let SIDES_NORTH_SOUTH: Set<PortSide> = [.NORTH, .SOUTH]
    internal static let SIDES_EAST_WEST: Set<PortSide> = [.EAST, .WEST]
    internal static let SIDES_NORTH_WEST: Set<PortSide> = [.NORTH, .WEST]
    internal static let SIDES_NORTH_EAST: Set<PortSide> = [.NORTH, .EAST]
    internal static let SIDES_SOUTH_WEST: Set<PortSide> = [.SOUTH, .WEST]
    internal static let SIDES_EAST_SOUTH: Set<PortSide> = [.EAST, .SOUTH]
    internal static let SIDES_NORTH_EAST_WEST: Set<PortSide> = [.NORTH, .EAST, .WEST]
    internal static let SIDES_EAST_SOUTH_WEST: Set<PortSide> = [.EAST, .SOUTH, .WEST]
    internal static let SIDES_NORTH_SOUTH_WEST: Set<PortSide> = [.NORTH, .SOUTH, .WEST]
    internal static let SIDES_NORTH_EAST_SOUTH: Set<PortSide> = [.NORTH, .EAST, .SOUTH]
    internal static let SIDES_NORTH_EAST_SOUTH_WEST: Set<PortSide> = [.NORTH, .EAST, .SOUTH, .WEST]

    internal func right() -> PortSide {
        switch self {
        case .NORTH: return .EAST
        case .EAST: return .SOUTH
        case .SOUTH: return .WEST
        case .WEST: return .NORTH
        case .UNDEFINED: return .UNDEFINED
        }
    }

    internal func left() -> PortSide {
        switch self {
        case .NORTH: return .WEST
        case .EAST: return .NORTH
        case .SOUTH: return .EAST
        case .WEST: return .SOUTH
        case .UNDEFINED: return .UNDEFINED
        }
    }

    internal func opposed() -> PortSide {
        switch self {
        case .NORTH: return .SOUTH
        case .EAST: return .WEST
        case .SOUTH: return .NORTH
        case .WEST: return .EAST
        case .UNDEFINED: return .UNDEFINED
        }
    }

    internal func areAdjacent(_ other: PortSide) -> Bool {
        if self == .UNDEFINED { return false }
        return self.left() == other || self.right() == other
    }

    internal static func fromDirection(_ direction: Direction) -> PortSide {
        switch direction {
        case .UP: return .NORTH
        case .RIGHT: return .EAST
        case .DOWN: return .SOUTH
        case .LEFT: return .WEST
        default: return .UNDEFINED
        }
    }

    internal static func isVertical(_ side: PortSide) -> Bool {
        return side == .NORTH || side == .SOUTH
    }

    internal static func isHorizontal(_ side: PortSide) -> Bool {
        return side == .WEST || side == .EAST
    }

    internal func isVertical() -> Bool {
        return PortSide.isVertical(self)
    }

    internal func isHorizontal() -> Bool {
        return PortSide.isHorizontal(self)
    }

    /// Returns the ordinal index of this port side (matching Java enum ordinal).
    internal var ordinal: Int {
        switch self {
        case .UNDEFINED: return 0
        case .NORTH: return 1
        case .EAST: return 2
        case .SOUTH: return 3
        case .WEST: return 4
        }
    }

    /// Returns the ordinal index as a function call (Java compatibility).
    internal func getOrdinal() -> Int {
        return ordinal
    }
}

// MARK: - Set<PortSide> convenience names (matching Java EnumSet usage)
extension Set where Element == PortSide {
    internal static var none: Set<PortSide> { [] }
    internal static var north: Set<PortSide> { [.NORTH] }
    internal static var east: Set<PortSide> { [.EAST] }
    internal static var south: Set<PortSide> { [.SOUTH] }
    internal static var west: Set<PortSide> { [.WEST] }
    internal static var northSouth: Set<PortSide> { [.NORTH, .SOUTH] }
    internal static var eastWest: Set<PortSide> { [.EAST, .WEST] }
    internal static var northWest: Set<PortSide> { [.NORTH, .WEST] }
    internal static var northEast: Set<PortSide> { [.NORTH, .EAST] }
    internal static var southWest: Set<PortSide> { [.SOUTH, .WEST] }
    internal static var eastSouth: Set<PortSide> { [.EAST, .SOUTH] }
    internal static var northEastWest: Set<PortSide> { [.NORTH, .EAST, .WEST] }
    internal static var eastSouthWest: Set<PortSide> { [.EAST, .SOUTH, .WEST] }
    internal static var northSouthWest: Set<PortSide> { [.NORTH, .SOUTH, .WEST] }
    internal static var northEastSouth: Set<PortSide> { [.NORTH, .EAST, .SOUTH] }
    internal static var northEastSouthWest: Set<PortSide> { [.NORTH, .EAST, .SOUTH, .WEST] }
}
