
/**
 * Abstract superclass for `LGraphElement`s that can have a position and a size.
 */
internal class LShape: LGraphElement {

    /** the current position of the element. */
    internal var position: KVector = KVector()
    /** the size of the element. */
    internal var size: KVector = KVector()

    /**
     * Returns the element's current position.
     */
    internal func getPosition() -> KVector {
        return position
    }

    /**
     * Sets the element's position.
     */
    internal func setPosition(_ pos: KVector) {
        self.position = pos
    }

    /**
     * Returns the element's current size.
     */
    internal func getSize() -> KVector {
        return size
    }

    /**
     * Sets the element's size.
     */
    internal func setSize(_ s: KVector) {
        self.size = s
    }
}
