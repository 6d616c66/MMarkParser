/**
 * A label in the layered graph structure.
 */
internal final class LLabel: LShape {

    internal var text: String

    internal override init() {
        self.text = ""
        super.init()
    }

    internal init(_ thetext: String) {
        self.text = thetext
        super.init()
    }

    internal func getText() -> String {
        return text
    }

    internal func setText(_ text: String) {
        self.text = text
    }

    internal override func getDesignation() -> String? {
        if !text.isEmpty {
            return text
        }
        return super.getDesignation()
    }

    internal func toString() -> String {
        if let designation = getDesignation() {
            return "l_\(designation)"
        }
        return "label"
    }
}
