/*******************************************************************************
 * Copyright (c) 2017 Kiel University and others.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * SPDX-License-Identifier: EPL-2.0
 *******************************************************************************/

/// Data structure for storing four (different) values.
internal struct Quadruple<A, B, C, D> {
    internal let first: A
    internal let second: B
    internal let third: C
    internal let fourth: D

    /// Creates a Quadruple with initial values. These are read-only afterwards.
    internal init(_ a: A, _ b: B, _ c: C, _ d: D) {
        self.first = a
        self.second = b
        self.third = c
        self.fourth = d
    }

    internal init(first: A, second: B, third: C, fourth: D) {
        self.first = first
        self.second = second
        self.third = third
        self.fourth = fourth
    }

    /// Gets the first value.
    internal func getFirst() -> A {
        return first
    }

    /// Gets the second value.
    internal func getSecond() -> B {
        return second
    }

    /// Gets the third value.
    internal func getThird() -> C {
        return third
    }

    /// Gets the fourth value.
    internal func getFourth() -> D {
        return fourth
    }

    // MARK: - CustomStringConvertible

    var description: String {
        return "(\(first), \(second), \(third), \(fourth))"
    }
}

extension Quadruple: Equatable where A: Equatable, B: Equatable, C: Equatable, D: Equatable {
    internal static func == (lhs: Quadruple<A, B, C, D>, rhs: Quadruple<A, B, C, D>) -> Bool {
        return lhs.first == rhs.first
            && lhs.second == rhs.second
            && lhs.third == rhs.third
            && lhs.fourth == rhs.fourth
    }
}

extension Quadruple: Hashable where A: Hashable, B: Hashable, C: Hashable, D: Hashable {
    internal func hash(into hasher: inout Hasher) {
        hasher.combine(first)
        hasher.combine(second)
        hasher.combine(third)
        hasher.combine(fourth)
    }
}

// Helper function to compare optional values for equality
internal func ObjectsEqual<T: Equatable>(_ a: T?, _ b: T?) -> Bool {
    switch (a, b) {
    case (.none, .none): return true
    case (.some(let aValue), .some(let bValue)): return aValue == bValue
    default: return false
    }
}
