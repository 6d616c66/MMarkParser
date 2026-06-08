import Foundation

/**
 * A generic factory for layout algorithms.
 */
internal class AlgorithmFactory: IFactory {

    /** The class for which instances shall be created. */
    internal let clazz: AbstractLayoutProvider.Type
    /** The parameter used for initialization of layout providers. */
    internal let parameter: String?

    /**
     * Creates an instance factory for the given layout provider class.
     *
     * @param theclazz the class for which instances shall be created
     */
    internal convenience init(_ theclazz: AbstractLayoutProvider.Type) {
        self.init(theclazz, parameter: nil)
    }

    /**
     * Creates an instance factory for the given layout provider class, initialized with a parameter.
     *
     * @param theclazz the class for which instances shall be created
     * @param theparameter the parameter used for initialization of layout providers
     */
    internal init(_ theclazz: AbstractLayoutProvider.Type, parameter: String?) {
        self.clazz = theclazz
        self.parameter = parameter
    }

    internal func create() -> Any {
        let algorithm = clazz.init()
        algorithm.initialize(parameter ?? "")
        return algorithm
    }

    internal func destroy(_ obj: Any) {
        if let provider = obj as? AbstractLayoutProvider {
            provider.dispose()
        }
    }
}

internal class Exception: Error {
    internal let message: String
    internal init(message: String) {
        self.message = message
    }
}
