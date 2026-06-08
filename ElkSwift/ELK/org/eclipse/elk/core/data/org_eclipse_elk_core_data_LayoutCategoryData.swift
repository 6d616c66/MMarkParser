import Foundation

/**
 * Data type used to store information for a layout category.
 */
internal final class LayoutCategoryData: Equatable, Hashable {

    /** identifier of the layout type. */
    internal let id: String
    /** user friendly name of the layout type. */
    internal let name: String
    /** detail description. */
    internal let categoryDescription: String
    /** the list of layout algorithms that are registered for this category. */
    internal let layouters: [LayoutAlgorithmData]

    // ILayoutMetaData-like conformance
    internal var description: String { return categoryDescription }

    /**
     * Create a layout category data entry.
     */
    private init(builder: Builder) {
        self.id = builder.id ?? ""
        self.name = builder.name ?? ""
        self.categoryDescription = builder.categoryDescription ?? ""
        self.layouters = []
    }

    internal static func == (lhs: LayoutCategoryData, rhs: LayoutCategoryData) -> Bool {
        return lhs.id == rhs.id
    }

    internal func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    internal func getLayouters() -> [LayoutAlgorithmData] {
        return layouters
    }

    internal func getId() -> String {
        return id
    }

    internal func getName() -> String {
        return name
    }

    internal func getDescription() -> String {
        return categoryDescription
    }

    /**
     * Builder for `LayoutCategoryData` instances.
     */
    internal struct Builder {

        internal var id: String?
        internal var name: String?
        internal var categoryDescription: String?

        internal init() {}

        internal func create() -> LayoutCategoryData {
            return LayoutCategoryData(builder: self)
        }

        @discardableResult
        internal mutating func id(_ aid: String) -> Self {
            self.id = aid
            return self
        }

        @discardableResult
        internal mutating func name(_ aname: String) -> Self {
            self.name = aname
            return self
        }

        @discardableResult
        internal mutating func description(_ adescription: String) -> Self {
            self.categoryDescription = adescription
            return self
        }

    }

}
