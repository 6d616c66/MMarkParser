import Foundation
import CoreGraphics
import CoreText

/// Loads and registers KaTeX math fonts from the resource bundle.
@available(iOS 15.0, *)
public final class MMarkFontLoader: @unchecked Sendable {

    public static let shared = MMarkFontLoader()

    private var isRegistered = false
    private let lock = NSLock()

    /// KaTeX font file names to register (only fonts actually used by default styles)
    private let fontFileNames: [String] = [
        "KaTeX_Math-Italic.ttf",
        "KaTeX_Main-Regular.ttf"
    ]

    private init() {}

    /// Ensure KaTeX fonts are registered. Safe to call multiple times.
    public static func ensureFontsRegistered() {
        shared.registerFonts()
    }

    /// Register all KaTeX fonts from the resource bundle.
    public func registerFonts() {
        lock.lock()
        defer { lock.unlock() }

        guard !isRegistered else { return }

        guard let resourceBundle = getResourceBundle() else {
            return
        }

        var successCount = 0
        var failedFonts: [String] = []

        for fontName in fontFileNames {
            if registerFont(named: fontName, in: resourceBundle) {
                successCount += 1
            } else {
                failedFonts.append(fontName)
            }
        }

        isRegistered = true
    }

    /// Get the resource bundle.
    private func getResourceBundle() -> Bundle? {
        let bundleName = "MMarkParser"

        // CocoaPods: look for MMarkParser resource bundle
        if let bundleURL = Bundle(for: MMarkFontLoader.self).url(forResource: bundleName, withExtension: "bundle"),
           let bundle = Bundle(url: bundleURL) {
            return bundle
        }
        // Fallback: use the framework bundle directly
        return Bundle(for: MMarkFontLoader.self)
    }

    /// Register a single font file from the bundle.
    private func registerFont(named fontName: String, in bundle: Bundle) -> Bool {
        let nameWithoutExtension = (fontName as NSString).deletingPathExtension

        // Try multiple lookup strategies
        var fontURL: URL?

        // Strategy 1: Look in KaTeXFonts subdirectory (bundle structure)
        if let url = bundle.url(forResource: nameWithoutExtension, withExtension: "ttf", subdirectory: "KaTeXFonts") {
            fontURL = url
        }
        // Strategy 2: Look directly in bundle
        else if let url = bundle.url(forResource: nameWithoutExtension, withExtension: "ttf") {
            fontURL = url
        }
        // Strategy 3: Look in the bundle's resource path
        else if let resourcePath = bundle.resourceURL {
            let url = resourcePath.appendingPathComponent("\(nameWithoutExtension).ttf")
            if FileManager.default.fileExists(atPath: url.path) {
                fontURL = url
            }
        }

        guard let url = fontURL else {
            return false
        }

        return registerFont(from: url, fontName: fontName)
    }

    /// Register a font from its file URL.
    private func registerFont(from fontURL: URL, fontName: String) -> Bool {
        guard let fontDataProvider = CGDataProvider(url: fontURL as CFURL),
              let font = CGFont(fontDataProvider) else {
            return false
        }

        var error: Unmanaged<CFError>?
        let success = CTFontManagerRegisterGraphicsFont(font, &error)

        if !success {
            return false
        }

        return true
    }
}