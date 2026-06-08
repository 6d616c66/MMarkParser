import Foundation

/**
 * A cell which manages the size and placement of labels.
 */
internal class LabelCell: Cell {

    // MARK: - Properties

    internal let horizontalLayoutMode: Bool
    internal var horizontalAlignment: HorizontalLabelAlignment = .center
    internal var verticalAlignment: VerticalLabelAlignment = .center
    internal let gap: Double
    internal var labels: [LabelAdapter] = []
    internal var minimumContentAreaSize = KVector()

    // MARK: - Computed properties for min width/height

    internal var minimumWidth: Double { return getMinimumWidth() }
    internal var minimumHeight: Double { return getMinimumHeight() }

    // MARK: - Constructors

    internal init(gap: Double) {
        self.gap = gap
        self.horizontalLayoutMode = true
        super.init()
    }

    internal init(gap: Double, horizontalLayoutMode: Bool) {
        self.gap = gap
        self.horizontalLayoutMode = horizontalLayoutMode
        super.init()
    }

    internal convenience init(gap: Double, nodeLabelLocation: NodeLabelLocation) {
        self.init(gap: gap, nodeLabelLocation: nodeLabelLocation, horizontalLayoutMode: true)
    }

    internal init(gap: Double, nodeLabelLocation: NodeLabelLocation, horizontalLayoutMode: Bool) {
        self.gap = gap
        self.horizontalLayoutMode = horizontalLayoutMode
        super.init()
        self.horizontalAlignment = nodeLabelLocation.horizontalAlignment
        self.verticalAlignment = nodeLabelLocation.verticalAlignment
    }

    /// Convenience init with labelLabelSpacing label
    internal convenience init(labelLabelSpacing: Double) {
        self.init(gap: labelLabelSpacing)
    }

    // MARK: - Getters / Setters

    internal func getHorizontalAlignment() -> HorizontalLabelAlignment {
        return horizontalAlignment
    }

    @discardableResult
    internal func setHorizontalAlignment(_ newHorizontalAlignment: HorizontalLabelAlignment) -> LabelCell {
        self.horizontalAlignment = newHorizontalAlignment
        return self
    }

    internal func getVerticalAlignment() -> VerticalLabelAlignment {
        return verticalAlignment
    }

    @discardableResult
    internal func setVerticalAlignment(_ newVerticalAlignment: VerticalLabelAlignment) -> LabelCell {
        self.verticalAlignment = newVerticalAlignment
        return self
    }

    internal func getLabels() -> [LabelAdapter] {
        return labels
    }

    // MARK: - Cell

    internal override func getMinimumWidth() -> Double {
        let padding = getPadding()
        return minimumContentAreaSize.x + padding.left + padding.right
    }

    internal override func getMinimumHeight() -> Double {
        let padding = getPadding()
        return minimumContentAreaSize.y + padding.top + padding.bottom
    }

    // MARK: - Adding Labels

    internal func addLabel(_ label: LabelAdapter) {
        labels.append(label)

        let labelSize = label.getSize()

        if horizontalLayoutMode {
            minimumContentAreaSize.x = max(minimumContentAreaSize.x, labelSize.x)
            minimumContentAreaSize.y += labelSize.y

            if labels.count > 1 {
                minimumContentAreaSize.y += gap
            }
        } else {
            minimumContentAreaSize.x += labelSize.x
            minimumContentAreaSize.y = max(minimumContentAreaSize.y, labelSize.y)

            if labels.count > 1 {
                minimumContentAreaSize.x += gap
            }
        }
    }

    internal func hasLabels() -> Bool {
        return !labels.isEmpty
    }

    // MARK: - Label Layout

    internal func applyLabelLayout() {
        if horizontalLayoutMode {
            applyHorizontalModeLabelLayout()
        } else {
            applyVerticalModeLabelLayout()
        }
    }

    internal func applyHorizontalModeLabelLayout() {
        let cellRect = getCellRectangle()
        let cellPadding = getPadding()

        var yPos = cellRect.y

        if verticalAlignment == .center {
            yPos += (cellRect.height - minimumContentAreaSize.y) / 2
        } else if verticalAlignment == .bottom {
            yPos += cellRect.height - minimumContentAreaSize.y
        }

        for label in labels {
            let labelSize = label.getSize()
            let labelPos = KVector()

            labelPos.y = yPos
            yPos += labelSize.y + gap

            switch horizontalAlignment {
            case .left:
                labelPos.x = cellRect.x + cellPadding.left
            case .center:
                labelPos.x = cellRect.x + cellPadding.left + (cellRect.width - labelSize.x) / 2
            case .right:
                labelPos.x = cellRect.x + cellRect.width - cellPadding.right - labelSize.x
            }

            label.setPosition(labelPos)
        }
    }

    internal func applyVerticalModeLabelLayout() {
        let cellRect = getCellRectangle()
        let cellPadding = getPadding()

        var xPos = cellRect.x

        if horizontalAlignment == .center {
            xPos += (cellRect.width - minimumContentAreaSize.x) / 2
        } else if horizontalAlignment == .right {
            xPos += cellRect.width - minimumContentAreaSize.x
        }

        for label in labels {
            let labelSize = label.getSize()
            let labelPos = KVector()

            labelPos.x = xPos
            xPos += labelSize.x + gap

            switch verticalAlignment {
            case .top:
                labelPos.y = cellRect.y + cellPadding.top
            case .center:
                labelPos.y = cellRect.y + cellPadding.top + (cellRect.height - labelSize.y) / 2
            case .bottom:
                labelPos.y = cellRect.y + cellRect.height - cellPadding.bottom - labelSize.y
            }

            label.setPosition(labelPos)
        }
    }
}
