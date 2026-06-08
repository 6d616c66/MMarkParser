/*******************************************************************************
 * Copyright (c) 2017 Kiel University and others.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * SPDX-License-Identifier: EPL-2.0
 *******************************************************************************/

import Foundation

internal final class RectangleStripOverlapRemover {

    // MARK: - Constants

    internal static let defaultGap: Double = 5.0

    // MARK: - Fields

    internal let overlapRemovalDirection: OverlapRemovalDirection
    internal var gapVertical: Double = defaultGap
    internal var gapHorizontal: Double = defaultGap
    internal var startCoordinate: Double = 0.0
    internal var overlapRemovalStrategy: IRectangleStripOverlapRemovalStrategy?
    internal var rectangleNodes: [RectangleNode] = []

    // MARK: - Creation

    private init(direction: OverlapRemovalDirection) {
        self.overlapRemovalDirection = direction
    }

    internal static func create(for direction: OverlapRemovalDirection) -> RectangleStripOverlapRemover {
        return RectangleStripOverlapRemover(direction: direction)
    }

    // MARK: - Configuration

    internal func withGap(_ horizontalGap: Double, _ verticalGap: Double) -> RectangleStripOverlapRemover {
        gapHorizontal = horizontalGap
        gapVertical = verticalGap
        return self
    }

    internal func withStartCoordinate(_ coordinate: Double) -> RectangleStripOverlapRemover {
        startCoordinate = coordinate
        return self
    }

    internal func withOverlapRemovalStrategy(_ strategy: IRectangleStripOverlapRemovalStrategy) -> RectangleStripOverlapRemover {
        overlapRemovalStrategy = strategy
        return self
    }

    @discardableResult
    internal func addRectangle(_ rectangle: ElkRectangle) -> RectangleStripOverlapRemover {
        let transformedRectangle = importRectangle(rectangle)
        let node = RectangleNode(originalRectangle: rectangle, rectangle: transformedRectangle)
        rectangleNodes.append(node)
        return self
    }

    // MARK: - Getters

    internal func getHorizontalGap() -> Double {
        return gapHorizontal
    }

    internal func getVerticalGap() -> Double {
        return gapVertical
    }

    internal func getRectangleNodes() -> [RectangleNode] {
        return rectangleNodes
    }

    // MARK: - Coordinate Transformation

    internal func importRectangle(_ rectangle: ElkRectangle) -> ElkRectangle {
        switch overlapRemovalDirection {
        case .up, .down:
            return rectangle
        case .left, .right:
            return ElkRectangle(x: rectangle.y, y: 0, width: rectangle.height, height: rectangle.width)
        }
    }

    internal func exportRectangle(_ rectangleNode: RectangleNode, stripSize: Double) {
        let rectangle = rectangleNode.rectangle
        let originalRectangle = rectangleNode.originalRectangle

        switch overlapRemovalDirection {
        case .up:
            originalRectangle.y = startCoordinate - rectangle.height - rectangle.y
        case .down:
            originalRectangle.y += startCoordinate
        case .left:
            originalRectangle.x = startCoordinate - rectangle.height - rectangle.y
        case .right:
            originalRectangle.x = startCoordinate + rectangle.y
        }
    }

    // MARK: - Actual Algorithm

    @discardableResult
    internal func removeOverlaps() -> Double {
        if overlapRemovalStrategy == nil {
            overlapRemovalStrategy = GreedyRectangleStripOverlapRemover()
        }

        rectangleNodes.sort { RectangleStripOverlapRemover.compareLeftRectangleBorders($0, $1) }

        computeOverlaps()
        guard let strategy = overlapRemovalStrategy else { return 0 }
        let stripSize = strategy.removeOverlaps(self)

        rectangleNodes.forEach { node in
            exportRectangle(node, stripSize: stripSize)
        }

        return stripSize
    }

    internal func computeOverlaps() {
        var intersectingNodes = OverlapSortedSet(compare: RectangleStripOverlapRemover.compareRightRectangleBorders)
        var scanlinePos: Double = Double.greatestFiniteMagnitude * -1

        for currNode in rectangleNodes {
            scanlinePos = currNode.rectangle.x

            while !intersectingNodes.isEmpty {
                guard let intersectingRectangle = intersectingNodes.first() else { break }

                if intersectingRectangle.rectangle.x + intersectingRectangle.rectangle.width < scanlinePos {
                    intersectingNodes.remove(intersectingRectangle)
                } else {
                    break
                }
            }

            for intersectingNode in intersectingNodes {
                intersectingNode.overlappingNodes.append(currNode)
                currNode.overlappingNodes.append(intersectingNode)
            }

            intersectingNodes.add(currNode)
        }
    }

    // MARK: - Utility Methods

    internal static func compareLeftRectangleBorders(_ rn1: RectangleNode, _ rn2: RectangleNode) -> Bool {
        return rn1.rectangle.x < rn2.rectangle.x
    }

    internal static func compareRightRectangleBorders(_ rn1: RectangleNode, _ rn2: RectangleNode) -> Bool {
        return rn1.rectangle.x + rn1.rectangle.width < rn2.rectangle.x + rn2.rectangle.width
    }

    // MARK: - Support Classes

    internal enum OverlapRemovalDirection {
        case up
        case down
        case left
        case right

        // Uppercase aliases
        internal static var UP: OverlapRemovalDirection { .up }
        internal static var DOWN: OverlapRemovalDirection { .down }
        internal static var LEFT: OverlapRemovalDirection { .left }
        internal static var RIGHT: OverlapRemovalDirection { .right }
    }

    internal final class RectangleNode {

        internal var originalRectangle: ElkRectangle
        internal var rectangle: ElkRectangle
        internal var overlappingNodes: [RectangleNode] = []

        init(originalRectangle: ElkRectangle, rectangle: ElkRectangle) {
            self.originalRectangle = originalRectangle
            self.rectangle = rectangle
        }

        internal func getRectangle() -> ElkRectangle {
            return rectangle
        }

        internal func getOverlappingNodes() -> [RectangleNode] {
            return overlappingNodes
        }
    }
}

// MARK: - OverlapSortedSet (simple sorted set for RectangleNode)

internal class OverlapSortedSet: Sequence {
    internal var elements: [RectangleStripOverlapRemover.RectangleNode] = []
    internal let compare: (RectangleStripOverlapRemover.RectangleNode, RectangleStripOverlapRemover.RectangleNode) -> Bool

    internal init(compare: @escaping (RectangleStripOverlapRemover.RectangleNode, RectangleStripOverlapRemover.RectangleNode) -> Bool) {
        self.compare = compare
    }

    internal func add(_ element: RectangleStripOverlapRemover.RectangleNode) {
        var index = 0
        while index < elements.count && compare(elements[index], element) {
            index += 1
        }
        elements.insert(element, at: index)
    }

    internal func remove(_ element: RectangleStripOverlapRemover.RectangleNode) {
        if let idx = elements.firstIndex(where: { $0 === element }) {
            elements.remove(at: idx)
        }
    }

    internal func first() -> RectangleStripOverlapRemover.RectangleNode? {
        return elements.first
    }

    internal var isEmpty: Bool {
        return elements.isEmpty
    }

    internal func makeIterator() -> Array<RectangleStripOverlapRemover.RectangleNode>.Iterator {
        return elements.makeIterator()
    }
}
