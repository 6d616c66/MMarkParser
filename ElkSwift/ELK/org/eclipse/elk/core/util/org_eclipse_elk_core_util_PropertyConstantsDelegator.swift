import Foundation

/**
 * Allows to reroute access to properties through other property constants which may provide different default values.
 */
internal final class PropertyConstantsDelegator {

    /** Set of property constants to be used for accessing their respective property. */
    internal var propertyDelegates: [String: IProperty] = [:]

    // MARK: - Creation

    private init() {}

    internal static func createEmpty() -> PropertyConstantsDelegator {
        return PropertyConstantsDelegator()
    }

    internal static func createForLayoutAlgorithmData(_ algorithmData: LayoutAlgorithmData) -> PropertyConstantsDelegator {
        let delegator = PropertyConstantsDelegator()

        for optionId in algorithmData.getKnownOptionIds() {
            let defaultValue = algorithmData.getDefaultValue(optionId)
            let delegate = Property<Any>(optionId, defaultValue: defaultValue)
            delegator.addDelegate(delegate)
        }

        return delegator
    }

    internal static func createForLayoutAlgorithmWithId(_ algorithmId: String) -> PropertyConstantsDelegator {
        guard let algorithmData = LayoutMetaDataService.getInstance().getAlgorithmData(algorithmId) else {
            return createEmpty()
        }
        return createForLayoutAlgorithmData(algorithmData)
    }

    // MARK: - Configuration

    @discardableResult
    internal func addDelegate(_ delegate: IProperty) -> PropertyConstantsDelegator {
        propertyDelegates[delegate.id] = delegate
        return self
    }

    // MARK: - Getters

    internal func getPropertyOrDelegate(_ property: IProperty) -> IProperty {
        if let actualProperty = propertyDelegates[property.id] {
            return actualProperty
        } else {
            return property
        }
    }

    // MARK: - Property Access

    internal func getProperty(_ propertyHolder: IPropertyHolder, _ property: IProperty) -> Any? {
        return propertyHolder.getProperty(getPropertyOrDelegate(property))
    }

    internal func getProperty(_ adapter: any GraphElementAdapter, _ property: IProperty) -> Any? {
        return adapter.getProperty(getPropertyOrDelegate(property))
    }

    internal func getIndividualOrInheritedProperty(_ node: ElkNode, _ property: IProperty) -> Any? {
        return IndividualSpacings.getIndividualOrInherited(node, getPropertyOrDelegate(property))
    }

    internal func getIndividualOrInheritedProperty(_ nodeAdapter: any NodeAdapterProtocol, _ property: IProperty) -> Any? {
        return IndividualSpacings.getIndividualOrInherited(nodeAdapter, getPropertyOrDelegate(property))
    }
}
