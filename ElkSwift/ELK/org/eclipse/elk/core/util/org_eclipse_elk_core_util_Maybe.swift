/*******************************************************************************
 * Copyright (c) 2009, 2015 Kiel University and others.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * SPDX-License-Identifier: EPL-2.0
 *******************************************************************************/


/**
 * Object that may contain another object, inspired by the Haskell type Maybe.
 *
 * This class can be used to wrap objects for anonymous classes, or as a wrapper
 * for synchronization on objects that may be nil.
 *
 * - Parameter T: type of contained object
 */
internal final class Maybe<T: Hashable>: CustomStringConvertible, Hashable {

    /**
     * Create a maybe with inferred generic type.
     *
     * - Returns: a new instance of given type
     */
    internal static func create<D: Hashable>() -> Maybe<D> {
        return Maybe<D>()
    }

    /** the contained object, which may be nil. */
    internal var object: T?

    /**
     * Creates a maybe without an object.
     */
    internal init() {
        self.object = nil
    }

    /**
     * Creates a maybe with the given object.
     *
     * - Parameter theobject: the object to contain
     */
    internal init(_ theobject: T) {
        self.object = theobject
    }

    internal static func == (lhs: Maybe<T>, rhs: Maybe<T>) -> Bool {
        if lhs.object == nil {
            return rhs.object == nil
        } else {
            return lhs.object == rhs.object
        }
    }

    internal func hash(into hasher: inout Hasher) {
        hasher.combine(object)
    }

    internal var description: String {
        if let obj = object {
            return "maybe(\(obj))"
        } else {
            return "maybe(nil)"
        }
    }

    /**
     * Sets the contained object.
     *
     * - Parameter theobject: the object to set
     */
    internal func set(_ theobject: T) {
        self.object = theobject
    }

    /**
     * Returns the contained object.
     *
     * - Returns: the contained object
     */
    internal func get() -> T? {
        return object
    }

    // Iterator-like conformance
    internal func hasNext() -> Bool {
        return object != nil
    }

    internal func next() -> T? {
        defer { object = nil }
        return object
    }

    /**
     * Clear any contained object.
     */
    internal func clear() {
        object = nil
    }

    /**
     * Determine whether any object is contained.
     *
     * - Returns: false if an object instance is contained, true otherwise
     */
    internal func isEmpty() -> Bool {
        return object == nil
    }

}
