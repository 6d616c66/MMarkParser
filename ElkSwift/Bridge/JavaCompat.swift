import Foundation

// MARK: - Java Compatibility Types

internal protocol Serializable {}

internal typealias Boolean = Bool
internal typealias Long = Int64
internal typealias Number = Double
internal typealias Object = AnyObject

internal typealias List<E> = [E]
internal typealias Map<K: Hashable, V> = [K: V]
internal typealias Iterable<E> = AnySequence<E>

internal class RuntimeException: Error {
    internal let message: String
    internal init(_ message: String = "") {
        self.message = message
    }
}

internal class StringWriter {
    private var buffer = ""
    internal init() {}
    internal func write(_ s: String) { buffer += s }
    internal func toString() -> String { return buffer }
}

// MARK: - Java Math Compat

internal enum DoubleMath {
    internal static func fuzzyEquals(_ a: Double, _ b: Double, _ tolerance: Double) -> Bool {
        return abs(a - b) <= tolerance
    }

    /// Compares two doubles with a tolerance. Returns -1, 0, or 1.
    internal static func fuzzyCompare(_ a: Double, _ b: Double, _ tolerance: Double) -> Int {
        if fuzzyEquals(a, b, tolerance) {
            return 0
        }
        return a < b ? -1 : 1
    }
}

internal enum Strings {
    internal static func isNullOrEmpty(_ s: String?) -> Bool {
        return s?.isEmpty ?? true
    }
    internal static func nullToEmpty(_ s: String?) -> String {
        return s ?? ""
    }
}

// MARK: - Java Collections Compat

internal typealias EnumSet<E: Hashable> = Set<E>
internal typealias EnumMap<K: Hashable, V> = Dictionary<K, V>

/// Swift equivalent of Guava's `TreeMultimap<K, V>`.
///
/// A sorted multimap that groups values by key, maintaining sorted order for both
/// keys (by `keyComparator`) and values within each key bucket (by `valueComparator`).
/// Values are inserted in O(log n) via binary search.
///
/// Matches Java's `TreeMultimap.create(keyComparator, valueComparator)` factory pattern.
internal struct TreeMultimap<K: Hashable, V>: Sequence {

    private var storage: [K: [V]] = [:]
    private let keyComparator: (K, K) -> Bool
    private let valueComparator: (V, V) -> Bool

    /// Creates a TreeMultimap with custom comparators (less-than semantics).
    internal init(
        keyComparator: @escaping (K, K) -> Bool,
        valueComparator: @escaping (V, V) -> Bool
    ) {
        self.keyComparator = keyComparator
        self.valueComparator = valueComparator
    }

    /// Insert a value under the given key, maintaining sorted order.
    internal mutating func put(_ key: K, _ value: V) {
        if storage[key] == nil {
            storage[key] = [value]
        } else {
            var arr = storage[key, default: []]
            var lo = 0
            var hi = arr.count
            while lo < hi {
                let mid = (lo + hi) / 2
                if valueComparator(arr[mid], value) {
                    lo = mid + 1
                } else {
                    hi = mid
                }
            }
            arr.insert(value, at: lo)
            storage[key] = arr
        }
    }

    /// Returns the sorted values for a key, or empty array if absent.
    internal func get(_ key: K) -> [V] {
        storage[key] ?? []
    }

    /// Subscript access — returns nil if key has no entries.
    internal subscript(_ key: K) -> [V]? {
        storage[key]
    }

    /// All keys in sorted order.
    internal var sortedKeys: [K] {
        storage.keys.sorted(by: keyComparator)
    }

    /// All keys in sorted order (Java API name).
    internal func keySet() -> [K] {
        sortedKeys
    }

    /// All values flattened, iterated in key-sorted then value-sorted order.
    internal func values() -> [V] {
        sortedKeys.flatMap { storage[$0, default: []] }
    }

    /// Whether the multimap has no entries.
    internal var isEmpty: Bool {
        storage.isEmpty
    }

    /// Sequence conformance — iterates as `(K, [V])` pairs in key-sorted order.
    internal func makeIterator() -> IndexingIterator<[(K, [V])]> {
        sortedKeys.map { ($0, storage[$0, default: []]) }.makeIterator()
    }
}

// MARK: - EMF Compat (minimal stubs)

internal protocol EObject: AnyObject {}
internal typealias EList<E> = [E]
internal typealias EMap<K: Hashable, V> = [K: V]

internal protocol EClass: AnyObject {
    var name: String { get }
    func classifierID() -> Int
    func getEPackage() -> (any EPackage)?
}

extension EClass {
    internal func classifierID() -> Int { return -1 }
    internal func getEPackage() -> (any EPackage)? { return nil }
}

// Convenience: allow calling name() as a function (some transpiled code uses name() instead of .name)
extension EClass {
    internal func name() -> String { return name }
}

internal protocol EPackage: AnyObject {
}

internal class EFactory {
    internal init() {}
}

// MARK: - Double Extensions for Java Math

internal extension Double {
    func toRadians() -> Double {
        return self * .pi / 180.0
    }
    func toDegrees() -> Double {
        return self * 180.0 / .pi
    }
}

// MARK: - Consumer typealias

internal typealias Consumer<T> = (T) -> Void

// MARK: - Missing Protocol Stubs

internal protocol IPropertyHolderOptionFilter {}
internal protocol LayoutMetaData {}
internal protocol TestController {}

// MARK: - IllegalArgumentException

internal struct IllegalArgumentException: Error, CustomStringConvertible {
    internal let description: String
    internal init(_ description: String) {
        self.description = description
    }
}
