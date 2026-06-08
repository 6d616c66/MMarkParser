import Foundation

/**
 * Data type used to store information for a layout algorithm.
 */
internal final class LayoutAlgorithmData: ILayoutMetaData, Hashable {

    /** identifier of the layout provider. */
    internal let id: String
    /** user friendly name of the layout algorithm. */
    internal let name: String
    /** runtime instance of the layout algorithm. */
    internal let providerPool: InstancePool<AbstractLayoutProvider>
    /** layout category identifier. */
    internal let category: String
    /** name of the bundle of which this algorithm is part of. */
    internal let melkBundleName: String
    /** id of the (eclipse) bundle in which the melk file resides. */
    internal let definingBundleId: String
    /** detail description. */
    internal let algorithmDescription: String
    /** a path to a preview image for displaying in user interfaces. */
    internal let imagePath: String
    /** Set of supported graph features. */
    internal let supportedFeatures: Set<GraphFeature>
    /** Validator that can be applied to input graphs before the algorithm is executed. */
    internal let validatorClass: AnyClass?

    /** Map of known layout options. Keys are option IDs, values are the default values. */
    internal var knownOptions: [String: Any] = [:]

    // MARK: - ILayoutMetaData conformance
    internal var description: String { return algorithmDescription }

    /**
     * Create a layout algorithm data entry.
     */
    private init(builder: Builder) {
        self.id = builder.id
        self.name = builder.name
        self.algorithmDescription = builder.algorithmDescription
        guard let factory = builder.providerFactory else {
            fatalError("LayoutAlgorithmData requires a providerFactory to be set on the Builder")
        }
        self.providerPool = InstancePool(providerFactory: factory)
        self.category = builder.category
        self.melkBundleName = builder.melkBundleName
        self.definingBundleId = builder.definingBundleId
        self.imagePath = builder.imagePath
        self.supportedFeatures = builder.supportedFeatures ?? []
        self.validatorClass = builder.validatorClass
    }

    internal func equals(_ obj: Any) -> Bool {
        guard let other = obj as? LayoutAlgorithmData else { return false }
        return self.id == other.id
    }

    internal static func == (lhs: LayoutAlgorithmData, rhs: LayoutAlgorithmData) -> Bool {
        return lhs.id == rhs.id
    }

    internal func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    /**
     * Sets the knowledge status of the given layout option.
     */
    internal func addKnownOption(_ property: IProperty, defaultValue: Any?) {
        knownOptions[property.id] = defaultValue
    }

    /**
     * Returns the set of IDs of layout options declared to be known by this algorithm.
     */
    internal func getKnownOptionIds() -> Set<String> {
        return Set(knownOptions.keys)
    }

    /**
     * Determines whether the layout algorithm knows the given layout option.
     */
    internal func knowsOption(_ property: IProperty) -> Bool {
        return knowsOption(property.id)
    }

    /**
     * Determines whether the layout algorithm knows the given layout option.
     */
    internal func knowsOption(_ propertyId: String) -> Bool {
        return knownOptions.keys.contains(propertyId)
    }

    /**
     * Returns the layout algorithm's default value for the given option.
     */
    internal func getDefaultValue(_ property: IProperty) -> Any? {
        return getDefaultValue(property.id)
    }

    /**
     * Returns the layout algorithm's default value for the given option.
     */
    internal func getDefaultValue(_ propertyId: String) -> Any? {
        return knownOptions[propertyId]
    }

    /**
     * Check whether the given graph feature is supported.
     */
    internal func supportsFeature(_ graphFeature: GraphFeature) -> Bool {
        return supportedFeatures.contains(graphFeature)
    }

    internal func getSupportedFeatures() -> Set<GraphFeature> {
        return supportedFeatures
    }

    internal func getId() -> String {
        return id
    }

    internal func getName() -> String {
        return name
    }

    internal func getDescription() -> String {
        return algorithmDescription
    }

    internal func getInstancePool() -> InstancePool<AbstractLayoutProvider> {
        return providerPool
    }

    internal func getValidatorClass() -> AnyClass? {
        return validatorClass
    }

    internal func getCategoryId() -> String {
        return category
    }

    internal func getBundleName() -> String {
        return melkBundleName
    }

    internal func getDefiningBundleId() -> String {
        return definingBundleId
    }

    internal func getPreviewImagePath() -> String {
        return imagePath
    }

    /**
     * Builder for `LayoutAlgorithmData` instances.
     */
    internal class Builder {

        internal var id: String = ""
        internal var name: String = ""
        internal var providerFactory: IFactory?
        internal var category: String = ""
        internal var melkBundleName: String = ""
        internal var definingBundleId: String = ""
        internal var algorithmDescription: String = ""
        internal var imagePath: String = ""
        internal var supportedFeatures: Set<GraphFeature>?
        internal var validatorClass: AnyClass?

        internal init() {}

        internal func create() -> LayoutAlgorithmData {
            return LayoutAlgorithmData(builder: self)
        }

        @discardableResult
        internal func id(_ aid: String) -> Builder {
            self.id = aid
            return self
        }

        @discardableResult
        internal func name(_ aname: String) -> Builder {
            self.name = aname
            return self
        }

        @discardableResult
        internal func providerFactory(_ aproviderFactory: IFactory) -> Builder {
            self.providerFactory = aproviderFactory
            return self
        }

        @discardableResult
        internal func category(_ acategory: String) -> Builder {
            self.category = acategory
            return self
        }

        @discardableResult
        internal func melkBundleName(_ amelkBundleName: String) -> Builder {
            self.melkBundleName = amelkBundleName
            return self
        }

        @discardableResult
        internal func definingBundleId(_ adefiningBundleId: String) -> Builder {
            self.definingBundleId = adefiningBundleId
            return self
        }

        @discardableResult
        internal func description(_ adescription: String) -> Builder {
            self.algorithmDescription = adescription
            return self
        }

        @discardableResult
        internal func imagePath(_ aimagePath: String) -> Builder {
            self.imagePath = aimagePath
            return self
        }

        @discardableResult
        internal func supportedFeatures(_ asupportedFeatures: Set<GraphFeature>) -> Builder {
            self.supportedFeatures = asupportedFeatures
            return self
        }

        @discardableResult
        internal func validatorClass(_ avalidator: AnyClass?) -> Builder {
            self.validatorClass = avalidator
            return self
        }

    }

}
