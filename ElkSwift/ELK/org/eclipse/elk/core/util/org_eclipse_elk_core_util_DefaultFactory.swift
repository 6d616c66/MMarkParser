import Foundation

/**
 * A factory that uses a creator closure to create instances.
 *
 * @param T type of instances that are created by this factory
 */
internal final class DefaultFactory<T>: IFactory {

    /** the creator closure. */
    internal let creator: () -> T

    /**
     * Creates an instance factory with a creator closure.
     *
     * @param creator a closure that creates instances of T
     */
    internal init(_ creator: @escaping () -> T) {
        self.creator = creator
    }

    internal func create() -> Any {
        return creator()
    }

    internal func destroy(_ obj: Any) {
        // do nothing by default
    }
}
