import Foundation

internal final class org_eclipse_elk_alg_layered_intermediate_loops_SelfHyperLoopLabels {

    internal enum Alignment {
        case CENTER
        case LEFT
        case RIGHT
        case TOP
    }

    internal var id: Int = 0

    private var lLabels: [LLabel] = []
    private let size = KVector()
    private let position = KVector()
    private let layoutDirection: Direction
    private let labelLabelSpacing: Double

    private var side: PortSide = .UNDEFINED
    private var alignment: Alignment = .CENTER
    private var alignmentReferenceSLPort: SelfLoopPort?

    internal init(_ slLoop: SelfHyperLoop) {
        let lNode = slLoop.getSLHolder().getLNode()
        self.layoutDirection = lNode.getGraph()?.getProperty(LayeredOptions.DIRECTION) as? Direction ?? .RIGHT
        self.labelLabelSpacing = LGraphUtil.getIndividualOrInherited(lNode, property: LayeredOptions.SPACING_LABEL_LABEL)
    }

    // MARK: - LLabel Access

    internal func addLLabels(_ newLLabels: [LLabel]) {
        for newLLabel in newLLabels {
            lLabels.append(newLLabel)
            updateSize(newLLabel)
        }
    }

    internal func getLLabels() -> [LLabel] {
        return lLabels
    }

    private func updateSize(_ newLLabel: LLabel) {
        let newLLabelSize = newLLabel.getSize()

        if layoutDirection.isHorizontal() {
            size.x = max(size.x, newLLabelSize.x)
            size.y += newLLabelSize.y
            if lLabels.count > 1 {
                size.y += labelLabelSpacing
            }
        } else {
            size.x += newLLabelSize.x
            size.y = max(size.y, newLLabelSize.y)
            if lLabels.count > 1 {
                size.x += labelLabelSpacing
            }
        }
    }

    internal func applyLabelManagement(_ labelManager: ILabelManager?, _ targetWidth: Double) {
        let result = org_eclipse_elk_alg_layered_intermediate_LabelManagementProcessor.doManageLabels(
            labelManager, lLabels, targetWidth, labelLabelSpacing, layoutDirection.isVertical())
        _ = size.set(result)
    }

    internal func applyPlacement(_ offset: KVector) {
        if layoutDirection.isHorizontal() {
            applyPlacementForHorizontalLayout(offset)
        } else {
            applyPlacementForVerticalLayout(offset)
        }
    }

    private func applyPlacementForHorizontalLayout(_ offset: KVector) {
        var x = position.x
        var y = position.y

        for lLabel in lLabels {
            let labelPos = lLabel.getPosition()

            if alignment == .LEFT || side == .EAST {
                labelPos.x = x
            } else if alignment == .RIGHT || side == .WEST {
                labelPos.x = x + size.x - lLabel.getSize().x
            } else {
                labelPos.x = x + (size.x - lLabel.getSize().x) / 2
            }

            labelPos.y = y
            _ = labelPos.add(offset)

            y += lLabel.getSize().y + labelLabelSpacing
        }
    }

    private func applyPlacementForVerticalLayout(_ offset: KVector) {
        var x = position.x
        let y = position.y

        for lLabel in lLabels {
            let labelPos = lLabel.getPosition()

            labelPos.x = x

            if side == .NORTH {
                labelPos.y = y + size.y - lLabel.getSize().y
            } else {
                labelPos.y = y
            }

            _ = labelPos.add(offset)

            x += lLabel.getSize().x + labelLabelSpacing
        }
    }

    // MARK: - Label Placement

    internal func getSize() -> KVector {
        return size
    }

    internal func getPosition() -> KVector {
        return position
    }

    internal func getSide() -> PortSide {
        return side
    }

    internal func setSide(_ side: PortSide) {
        self.side = side
    }

    internal func getAlignment() -> Alignment {
        return alignment
    }

    internal func setAlignment(_ alignment: Alignment) {
        self.alignment = alignment
    }

    internal func getAlignmentReferenceSLPort() -> SelfLoopPort? {
        return alignmentReferenceSLPort
    }

    internal func setAlignmentReferenceSLPort(_ port: SelfLoopPort?) {
        self.alignmentReferenceSLPort = port
    }
}
