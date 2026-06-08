import Foundation

/**
 * A runtime exception that can be used to wrap checked exceptions. Use this where it is
 * appropriate to forward an error to the next point where it can be handled (i.e. displayed
 * to the user) without the need to explicitly declare the error in every method signature.
 */
internal class WrappedException: RuntimeException {

    /** the serial version UID. */
    internal static let serialVersionUID: Int64 = -1630132187697677735

    internal var cause: Error?

    /**
     * Create a wrapped exception.
     *
     * @param cause the error that caused this exception
     */
    internal init(cause: Error) {
        self.cause = cause
        super.init(cause.localizedDescription)
    }

    /**
     * Create a wrapped exception with additional message.
     *
     * @param message an additional message for information
     * @param cause the error that caused this exception
     */
    internal init(message: String, cause: Error) {
        self.cause = cause
        super.init(message)
    }

}

