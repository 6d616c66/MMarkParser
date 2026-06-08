import Foundation

/**
 * Simple scaffold for a scanline algorithm.
 */
internal final class Scanline<T> {
    
    /** The points to process along. */
    internal var points: [T]
    /** The comparator to sort the points. */
    internal var comparator: (T, T) -> Bool
    /** Handlers processing a point. */
    internal var eventHandlers: [EventHandler]
    
    private init(points: [T], comparator: @escaping (T, T) -> Bool, eventHandlers: [EventHandler]) {
        self.comparator = comparator
        self.points = points
        self.eventHandlers = eventHandlers
    }
    
    /**
     * @param points
     *            the points to process. They will be sorted according to `comparator` and
     *            are then passed in the determined order to the passed `eventHandlers`.
     * @param comparator
     *            a comparator to sort the passed points.
     * @param eventHandlers
     *            handlers to treat the points.
     * @param T
     *            The type of the points.
     */
    internal static func execute(_ points: [T], comparator: @escaping (T, T) -> Bool, eventHandlers: [EventHandler]) {
        let copy = points
        Scanline(points: copy, comparator: comparator, eventHandlers: eventHandlers).go()
    }
    
    /**
     * @param points
     *            the points to process. They will be sorted according to `comparator` and
     *            are then passed in the determined order to the passed `eventHandler`.
     * @param comparator
     *            a comparator to sort the passed points.
     * @param eventHandler
     *            a handler to treat the points.
     * @param T
     *            The type of the point.
     */
    internal static func execute(_ points: [T], comparator: @escaping (T, T) -> Bool, eventHandler: @escaping EventHandler) {
        execute(points, comparator: comparator, eventHandlers: [eventHandler])
    }
    
    internal func go() {
        // sort
        points.sort(by: comparator)
        
        // now move scanline
        for p in points {
            for handler in eventHandlers {
                handler(p)
            }
        }
    }
    
    /**
     * An event handler, gets passed a point of type T and does with it whatever it likes.
     */
    internal typealias EventHandler = (T) -> Void
}
