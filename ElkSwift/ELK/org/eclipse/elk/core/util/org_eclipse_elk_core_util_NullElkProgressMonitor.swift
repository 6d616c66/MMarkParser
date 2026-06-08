import Foundation

/**
 * An implementation of `IElkProgressMonitor` which does not do anything. The primary purpose of this monitor is
 * for it to be used with unit tests. The only method which returns something sensible is `subTask(_:)`, which
 * simply returns the instance it was called on (since the progress monitor doesn't do anything anyway, we don't bother
 * creating a new instance).
 */
internal class NullElkProgressMonitor: IElkProgressMonitor {

    internal static let UNKNOWN_WORK: Float = -1

    internal var taskName: String { return "" }
    internal var subMonitors: [IElkProgressMonitor] { return [] }
    internal var parentMonitor: (any IElkProgressMonitor)? { return nil }
    internal var logs: [String] { return [] }
    internal var loggedGraphs: [LoggedGraph] { return [] }
    internal var debugFolder: URL? { return nil }
    internal var executionTime: Double { return 0 }

    internal init() {}

    internal func isCanceled() -> Bool {
        return false
    }

    @discardableResult
    internal func begin(_ name: String, _ totalWork: Float) -> Bool {
        return true
    }

    internal func worked(_ work: Float) {
    }

    internal func done() {
    }

    internal func isRunning() -> Bool {
        return false
    }

    internal func subTask(_ work: Float) -> (any IElkProgressMonitor)? {
        return self
    }

    internal func isLoggingEnabled() -> Bool {
        return false
    }

    internal func isLogPersistenceEnabled() -> Bool {
        return false
    }

    internal func log(_ object: Any) {
    }

    internal func logGraph(_ graph: ElkNode, _ tag: String) {
    }

    internal func logGraph(_ graph: Any, _ tag: String, _ graphType: LoggedGraph.GraphType = .elk) {
    }

    internal func isExecutionTimeMeasured() -> Bool {
        return false
    }
}
