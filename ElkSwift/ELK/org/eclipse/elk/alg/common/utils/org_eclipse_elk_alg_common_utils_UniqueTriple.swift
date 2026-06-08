internal struct UniqueTriple<F, S, T> {
    internal let first: F
    internal let second: S
    internal let third: T

    internal init(_ f: F, _ s: S, _ t: T) {
        self.first = f
        self.second = s
        self.third = t
    }

    internal init(first: F, second: S, third: T) {
        self.first = first
        self.second = second
        self.third = third
    }

    internal func getFirst() -> F {
        return first
    }

    internal func getSecond() -> S {
        return second
    }

    internal func getThird() -> T {
        return third
    }

    var description: String {
        return "(\(first), \(second), \(third))"
    }
}
