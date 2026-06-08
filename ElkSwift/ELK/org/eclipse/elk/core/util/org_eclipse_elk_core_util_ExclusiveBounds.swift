import Foundation

/**
 * Utility `Comparable` implementations that can be used to specify exclusive upper and lower
 * bounds for layout options. For instance, a layout option whose values may be in the range (0, 1)
 * could be specified with the lower bound `greaterThan(0)` and the upper bound `lessThan(1)`.
 * 
 * <p>For inclusive bounds, you can simply use the numbers themselves as lower and upper bounds.</p>
 */
internal struct ExclusiveBounds {
    
    /**
     * Create a lower bound that does not include the limit.
     * 
     * @param exclusiveLowerBound the lower bound
     * @return a comparable that excludes the given lower bound
     */
    internal static func greaterThan(_ exclusiveLowerBound: Double) -> ExclusiveLowerBound {
        return ExclusiveLowerBound(exclusiveLowerBound)
    }
    
    /**
     * Lower bound that does not include the limit.
     */
    internal struct ExclusiveLowerBound: Comparable, CustomStringConvertible {
        
        internal let exclusiveLowerBound: Double
        
        /**
         * Create an exclusive lower bound.
         */
        internal init(_ exclusiveLowerBound: Double) {
            self.exclusiveLowerBound = exclusiveLowerBound
        }

        internal static func < (lhs: ExclusiveLowerBound, rhs: ExclusiveLowerBound) -> Bool {
            return lhs.exclusiveLowerBound < rhs.exclusiveLowerBound
        }
        
        internal static func == (lhs: ExclusiveLowerBound, rhs: ExclusiveLowerBound) -> Bool {
            return lhs.exclusiveLowerBound == rhs.exclusiveLowerBound
        }
        
        internal func compare(_ other: Number) -> ComparisonResult {
            if exclusiveLowerBound < other.doubleValue {
                return .orderedAscending
            } else {
                return .orderedDescending
            }
        }
        
        internal var description: String {
            return "\(exclusiveLowerBound) (exclusive)"
        }
        
    }
    
    /**
     * Create an upper bound that does not include the limit.
     * 
     * @param exclusiveUpperBound the upper bound
     * @return a comparable that excludes the given upper bound
     */
    internal static func lessThan(_ exclusiveUpperBound: Double) -> ExclusiveUpperBound {
        return ExclusiveUpperBound(exclusiveUpperBound)
    }
    
    /**
     * Upper bound that does not include the limit.
     */
    internal struct ExclusiveUpperBound: Comparable, CustomStringConvertible {
        
        internal let exclusiveUpperBound: Double
        
        /**
         * Create an exclusive upper bound.
         */
        internal init(_ exclusiveUpperBound: Double) {
            self.exclusiveUpperBound = exclusiveUpperBound
        }

        internal static func < (lhs: ExclusiveUpperBound, rhs: ExclusiveUpperBound) -> Bool {
            return lhs.exclusiveUpperBound < rhs.exclusiveUpperBound
        }
        
        internal static func == (lhs: ExclusiveUpperBound, rhs: ExclusiveUpperBound) -> Bool {
            return lhs.exclusiveUpperBound == rhs.exclusiveUpperBound
        }
        
        internal func compare(_ other: Number) -> ComparisonResult {
            if exclusiveUpperBound > other.doubleValue {
                return .orderedAscending
            } else {
                return .orderedDescending
            }
        }
        
        internal var description: String {
            return "\(exclusiveUpperBound) (exclusive)"
        }
        
    }

}

// Extension to support Number comparison
extension Number {
    internal var doubleValue: Double {
        if let value = self as? Double {
            return value
        } else if let value = self as? Float {
            return Double(value)
        } else if let value = self as? Int {
            return Double(value)
        } else if let value = self as? Int64 {
            return Double(value)
        } else if let value = self as? Int32 {
            return Double(value)
        } else if let value = self as? Int16 {
            return Double(value)
        } else if let value = self as? Int8 {
            return Double(value)
        } else if let value = self as? UInt64 {
            return Double(value)
        } else if let value = self as? UInt32 {
            return Double(value)
        } else if let value = self as? UInt16 {
            return Double(value)
        } else if let value = self as? UInt8 {
            return Double(value)
        } else {
            return 0.0
        }
    }
}
