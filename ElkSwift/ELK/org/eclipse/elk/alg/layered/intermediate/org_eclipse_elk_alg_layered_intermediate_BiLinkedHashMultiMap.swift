import Foundation

/**
 * This is a special data structure made to efficiently move nodes between layers and still be able to efficiently get
 * all nodes of a layer. Moreover, it is order preserving.
 * It consists of a `OrderedDictionary` with a list of nodes to have an ordered list for each layer id and
 * a `Dictionary` to get the layer of a node.
 */
internal class BiLinkedHashMultiMap<K: Comparable & Hashable, V: Hashable> {
    
    internal var multiMapKeyToValues: OrderedDictionary<K, [V]> = OrderedDictionary()
    internal var hashMapValuesToKey: [V: K] = [:]
    
    /**
     * Adds all values to the respective key.
     *
     * @param key The key.
     * @param values A list of values
     */
    internal func putAll(key: K, values: [V]) {
        for value in values {
            put(key: key, value: value)
        }
    }
    
    /**
     * Adds a new value linked to the given key and update prior occurrences of the value.
     *
     * @param key The key.
     * @param value The value.
     */
    internal func put(key: K, value: V) {
        // Remove old value.
        if let oldKey = hashMapValuesToKey[value] {
            if var values = multiMapKeyToValues[oldKey] {
                values.removeAll { $0 == value }
                multiMapKeyToValues[oldKey] = values
            }
        }
        
        // Add new value
        var values = multiMapKeyToValues[key] ?? []
        values.append(value)
        multiMapKeyToValues[key] = values
        
        hashMapValuesToKey[value] = key
    }
    
    /**
     * Returns the key associated with the given value.
     *
     * @param value The value.
     * @return The key.
     */
    internal func getKey(value: V) -> K? {
        return hashMapValuesToKey[value]
    }
    
    /**
     * Returns the values associated with the given key.
     *
     * @param key The key.
     * @return The list of values for the given key.
     */
    internal func getValues(key: K) -> [V] {
        return multiMapKeyToValues[key] ?? []
    }
    
    /**
     * Returns a set of all keys.
     *
     * @return The keys.
     */
    internal var keySet: [K] {
        return Array(multiMapKeyToValues.keys)
    }
    
    internal func isMaximalKey(key: K) -> Bool {
        for otherKey in multiMapKeyToValues.keys {
            if key < otherKey {
                return false
            }
        }
        return true
    }
    
    internal func isMinimalKey(key: K) -> Bool {
        for otherKey in multiMapKeyToValues.keys {
            if key > otherKey {
                return false
            }
        }
        return true
    }
}

// A simple implementation of an ordered dictionary in Swift
// to preserve insertion order of keys.
internal struct OrderedDictionary<Key: Hashable, Value> {
    internal var keys: [Key] = []
    internal var values: [Key: Value] = [:]
    
    subscript(key: Key) -> Value? {
        get { values[key] }
        set {
            if newValue == nil {
                if let index = keys.firstIndex(of: key) {
                    keys.remove(at: index)
                }
                values[key] = nil
            } else {
                if keys.firstIndex(of: key) == nil {
                    keys.append(key)
                }
                values[key] = newValue
            }
        }
    }
    
    internal var orderedKeys: [Key] {
        return keys
    }

    internal var dictionary: [Key: Value] {
        return values
    }
}
