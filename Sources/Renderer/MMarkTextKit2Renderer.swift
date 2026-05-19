import UIKit
import QuartzCore
import SwiftUI

/// TextKit2 渲染器，使用 TextKit2 API 进行 Markdown 渲染
@available(iOS 15.0, *)
public final class MMarkTextKit2Renderer {
    private let contentStorage: NSTextContentStorage
    private let layoutManager: NSTextLayoutManager
    private let _textContainer: NSTextContainer
    private let parser: CMarkParser

    public init(configuration: MMarkStyleConfiguration = .defaultStyle) {
        self.contentStorage = NSTextContentStorage()
        self.layoutManager = NSTextLayoutManager()
        self._textContainer = NSTextContainer(size: .zero)
        self.parser = CMarkParser()

        self.layoutManager.textContainer = _textContainer
        self.contentStorage.addTextLayoutManager(layoutManager)
    }

    /// 获取 TextKit2 组件
    public var textContentStorage: NSTextContentStorage {
        return contentStorage
    }

    public var textLayoutManager: NSTextLayoutManager {
        return layoutManager
    }

    public var textContainer: NSTextContainer {
        return _textContainer
    }

    /// 渲染 Markdown 文本
    public func render(markdown: String, width: CGFloat, configuration: MMarkStyleConfiguration = .defaultStyle) -> NSAttributedString {
        do {
            return try parser.parse(markdown, configuration: configuration)
        } catch {
            return NSAttributedString(string: markdown)
        }
    }

    /// 渲染 Markdown 文本并设置到 TextKit2 组件
    public func renderToTextKit2(markdown: String, width: CGFloat, containerSize: CGSize, configuration: MMarkStyleConfiguration = .defaultStyle) {
        let attributedString = render(markdown: markdown, width: width, configuration: configuration)
        contentStorage.textStorage?.setAttributedString(attributedString)

        _textContainer.size = containerSize
        layoutManager.ensureLayout(for: layoutManager.documentRange)
    }

    /// 创建用于 UITextView 的 TextKit2 配置
    public func createTextKit2Configuration() -> (NSTextContentStorage, NSTextLayoutManager, NSTextContainer) {
        return (contentStorage, layoutManager, _textContainer)
    }
}

// MARK: - UIKit 集成

@available(iOS 15.0, *)
extension MMarkTextKit2Renderer {
    /// 创建一个配置好的 UITextView
    public static func createTextView(markdown: String, frame: CGRect, configuration: MMarkStyleConfiguration = .defaultStyle) -> UITextView {
        let textView = MMarkTextView(frame: frame)
        textView.styleConfiguration = configuration
        textView.setMarkdown(markdown)
        return textView
    }

    /// 更新 UITextView 的内容
    public func updateTextView(_ textView: UITextView, markdown: String, width: CGFloat, configuration: MMarkStyleConfiguration = .defaultStyle) {
        if let mmarkTextView = textView as? MMarkTextView {
            mmarkTextView.styleConfiguration = configuration
            mmarkTextView.setMarkdown(markdown)
        } else {
            let attributedString = render(markdown: markdown, width: width, configuration: configuration)
            textView.attributedText = attributedString
        }
    }
}

// MARK: - SwiftUI 集成

@available(iOS 15.0, *)
public struct MarkdownTextView: UIViewRepresentable {
    private let markdown: String
    private let configuration: MMarkStyleConfiguration

    public init(markdown: String, configuration: MMarkStyleConfiguration = .defaultStyle) {
        self.markdown = markdown
        self.configuration = configuration
    }

    public func makeUIView(context: Context) -> UITextView {
        let textView = MMarkTextView(frame: .zero)
        textView.styleConfiguration = configuration
        textView.setMarkdown(markdown)
        textView.translatesAutoresizingMaskIntoConstraints = true
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        return textView
    }

    public func updateUIView(_ uiView: UITextView, context: Context) {
        if let mmarkTextView = uiView as? MMarkTextView {
            mmarkTextView.styleConfiguration = configuration
            mmarkTextView.setMarkdown(markdown)
        }
    }
}
