/**
 * A set of connected components.
 */
internal protocol IConnectedComponents {
    associatedtype ComponentType

    /// The components
    func getComponents() -> [ComponentType]

    /// Whether any of the components contains external extensions
    func isContainsExternalExtensions() -> Bool
}
