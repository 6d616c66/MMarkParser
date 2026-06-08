/// A simple FIFO queue backed by an array with O(1) amortized dequeue.
///
/// Unlike `Array.removeFirst()` which is O(n), this uses an index to track
/// the front of the queue, avoiding element shifting on each dequeue.
internal struct ArrayDeque<Element> {
    private var storage: [Element]
    private var headIndex: Int = 0

    internal init() {
        storage = []
    }

    internal init(_ elements: [Element]) {
        storage = elements
    }

    internal var isEmpty: Bool {
        headIndex >= storage.count
    }

    internal var count: Int {
        storage.count - headIndex
    }

    internal mutating func append(_ element: Element) {
        storage.append(element)
    }

    internal mutating func append<S: Sequence>(contentsOf elements: S) where S.Element == Element {
        storage.append(contentsOf: elements)
    }

    @discardableResult
    internal mutating func removeFirst() -> Element {
        let element = storage[headIndex]
        headIndex += 1
        // Reclaim memory when more than half is consumed
        if headIndex > 64 && headIndex > storage.count / 2 {
            storage.removeFirst(headIndex)
            headIndex = 0
        }
        return element
    }

    internal var first: Element? {
        isEmpty ? nil : storage[headIndex]
    }

    internal mutating func removeAll(keepingCapacity: Bool = false) {
        storage.removeAll(keepingCapacity: keepingCapacity)
        headIndex = 0
    }

    internal func contains(where predicate: (Element) -> Bool) -> Bool {
        for i in headIndex..<storage.count {
            if predicate(storage[i]) { return true }
        }
        return false
    }
}

extension ArrayDeque: Sequence {
    internal func makeIterator() -> IndexingIterator<ArraySlice<Element>> {
        storage[headIndex...].makeIterator()
    }
}
