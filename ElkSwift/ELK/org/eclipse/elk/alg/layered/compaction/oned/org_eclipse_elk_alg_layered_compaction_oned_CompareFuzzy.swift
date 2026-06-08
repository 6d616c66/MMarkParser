import Foundation

/**
 * Internal Class for tolerance affected double comparisons.
 */
internal final class CompareFuzzy {
    internal static let tolerance: Double = 0.0001
    
    private init() {}
    
    // SUPPRESS CHECKSTYLE NEXT 20 Javadoc
    internal static func eq(_ d1: Double, _ d2: Double) -> Bool {
        return abs(d1 - d2) <= tolerance
    }
    
    internal static func gt(_ d1: Double, _ d2: Double) -> Bool {
        return d1 - d2 > tolerance
    }
    
    internal static func lt(_ d1: Double, _ d2: Double) -> Bool {
        return d2 - d1 > tolerance
    }
    
    internal static func ge(_ d1: Double, _ d2: Double) -> Bool {
        return d1 >= d2 - tolerance
    }
    
    internal static func le(_ d1: Double, _ d2: Double) -> Bool {
        return d1 <= d2 + tolerance
    }
}
