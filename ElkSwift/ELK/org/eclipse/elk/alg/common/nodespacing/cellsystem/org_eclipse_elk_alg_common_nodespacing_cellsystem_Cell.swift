import Foundation

/**
 * A cell is the basic component of the cell system. Each cell has a padding, which determines the amount of space
 * between its content area and its border. It also has a minimum width and height, which is the minimum size it
 * would like to be in the final layout. `ContainerCell` container cells will use that information to compute
 * their own minimum size. Whether or not a cell contributes to that is controlled through its flags, for width and
 * height separately. Finally, a cell has a rectangle which describes its actual position and size. While these
 * information can be set manually, they will often be computed by container cells.
 */
internal class Cell {
    
    // MARK: - Properties
    
    /** A cell has a padding. */
    internal var padding = ElkPadding()
    /** The actual size and position of the cell. Includes the padding. */
    internal var cellRectangle = ElkRectangle()
    /** Whether the cell contributes to the minimum width calculation of a container cell or not. */
    internal var contributesToMinimumWidth = false
    /** Whether the cell contributes to the minimum height calculation of a container cell or not. */
    internal var contributesToMinimumHeight = false
    
    // MARK: - Getters / Setters
    
    /**
     * Returns this cell's padding, to be modified by the caller.
     */
    internal func getPadding() -> ElkPadding {
        return padding
    }
    
    /**
     * Returns a rectangle that describes the cell's size and position, including padding, to be modified by the
     * caller.
     */
    internal func getCellRectangle() -> ElkRectangle {
        return cellRectangle
    }
    
    /**
     * Checks whether this cell should be included when calculating a container cell's minimum width.
     */
    internal func isContributingToMinimumWidth() -> Bool {
        return contributesToMinimumWidth
    }
    
    /**
     * Sets whether this cell should be included when calculating a container cell's minimum width.
     */
    internal func setContributesToMinimumWidth(_ contributesToMinimumWidth: Bool) {
        self.contributesToMinimumWidth = contributesToMinimumWidth
    }
    
    /**
     * Checks whether this cell should be included when calculating a container cell's minimum height.
     */
    internal func isContributingToMinimumHeight() -> Bool {
        return contributesToMinimumHeight
    }
    
    /**
     * Sets whether this cell should be included when calculating a container cell's minimum height.
     */
    internal func setContributesToMinimumHeight(_ contributesToMinimumHeight: Bool) {
        self.contributesToMinimumHeight = contributesToMinimumHeight
    }
    
    // MARK: - Abstract Methods
    
    /**
     * Returns this cell's minimum width, including padding.
     */
    internal func getMinimumWidth() -> Double {
        assertionFailure("Subclass must override")
        return 0
    }

    /**
     * Returns this cell's minimum height, including padding.
     */
    internal func getMinimumHeight() -> Double {
        assertionFailure("Subclass must override")
        return 0
    }
}
