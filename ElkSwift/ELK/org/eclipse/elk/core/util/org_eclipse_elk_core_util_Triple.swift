internal struct Triple<F, S, T> {
    internal let first: F
    internal let second: S
    internal let third: T

    internal init(_ f: F, _ s: S, _ t: T) {
        first = f
        second = s
        third = t
    }

    internal var getFirst: F {
        return first
    }

    internal var getSecond: S {
        return second
    }

    internal var getThird: T {
        return third
    }

    internal func toString() -> String {
        return "(\(first), \(second), \(third))"
    }
}

extension Triple: Equatable where F: Equatable, S: Equatable, T: Equatable {
    internal static func == (lhs: Triple, rhs: Triple) -> Bool {
        return lhs.first == rhs.first
            && lhs.second == rhs.second
            && lhs.third == rhs.third
    }
}

extension Triple: Hashable where F: Hashable, S: Hashable, T: Hashable {
    internal func hash(into hasher: inout Hasher) {
        hasher.combine(first)
        hasher.combine(second)
        hasher.combine(third)
    }
}
