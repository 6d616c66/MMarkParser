import Foundation

/**
 * A proxy class for lazy resolving of layout options.
 */
internal final class LayoutOptionProxy: IPropertyValueProxy {

    /** the serialized layout option value. */
    internal let value: String?

    internal init(_ value: String?) {
        self.value = value
    }

    /**
     * Create a layout option proxy with given key and value strings.
     */
    internal static func setProxyValue(_ propertyHolder: IPropertyHolder, key: String, value: String?) {
        let property = Property<LayoutOptionProxy>(key)
        let proxy = LayoutOptionProxy(value)
        propertyHolder.setProperty(property, proxy)
    }

    internal func resolveValue<T>(_ property: IProperty) -> T? {
        var optionData: LayoutOptionData?

        if let layoutOptionData = property as? LayoutOptionData {
            optionData = layoutOptionData
        } else {
            optionData = LayoutMetaDataService.getInstance().getOptionData(property.id)
        }

        if let data = optionData, let serializedValue = value {
            return data.parseValue(serializedValue) as? T
        }

        return nil
    }
}

extension LayoutOptionProxy: Equatable {
    internal static func == (lhs: LayoutOptionProxy, rhs: LayoutOptionProxy) -> Bool {
        return lhs.value == rhs.value
    }
}

extension LayoutOptionProxy: CustomStringConvertible {
    internal var description: String {
        return value ?? ""
    }
}
