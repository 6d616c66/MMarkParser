import Foundation

internal enum JavaNumbers {
    internal static func intDiv(_ lhs: Int, _ rhs: Int) -> Int {
        lhs / rhs
    }

    internal static func intMod(_ lhs: Int, _ rhs: Int) -> Int {
        lhs % rhs
    }

    internal static func toInt(_ value: Double) -> Int {
        Int(value)
    }

    internal static func toDouble(_ value: Int) -> Double {
        Double(value)
    }

    internal static func isNaN(_ value: Double) -> Bool {
        value.isNaN
    }
}
