import UIKit

/// Delegate protocol for streaming render state changes.
@available(iOS 15.0, *)
public protocol MMarkStreamDelegate: AnyObject {
    func onSizeChange(_ size: CGSize)
    func didChangeState(_ state: MMarkStreamTextView.StreamState)
    func didFinishStreaming()
}

@available(iOS 15.0, *)
public extension MMarkStreamDelegate {
    func onSizeChange(_ size: CGSize) {}
    func didChangeState(_ state: MMarkStreamTextView.StreamState) {}
    func didFinishStreaming() {}
}

/// A UITextView that supports incremental (streaming) Markdown rendering.
@available(iOS 15.0, *)
@MainActor
public class MMarkStreamTextView: UITextView, MMarkTextComponent {

    // MARK: - State

    public enum StreamState: Equatable {
        case idle
        case streaming
        case paused
        case stopped
    }

    // MARK: - 流式配置

    public var typingSpeed: TimeInterval = 0.03
    public var chunkSize: Int = 3
    public var styleConfiguration: MMarkStyleConfiguration = .defaultStyle
    public weak var streamDelegate: MMarkStreamDelegate?
    public weak var mmarkLinkDelegate: MMarkLinkDelegate?

    /// 是否开启自动滚动到底部。开启后，若用户当前在底部，则新内容出现时会自动跟进。
    public var autoScrollToBottom: Bool = true

    // MARK: - 公开只读状态

    public func scrollToBottom(animated: Bool = false) {
        if #available(iOS 16.0, *), let layoutManager = self.textLayoutManager {
            layoutManager.ensureLayout(for: layoutManager.documentRange)
        }

        let width = bounds.width
        guard width > 0 else { return }
        // 使用最新的 sizeThatFits 结果进行滚动计算
        let size = sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        let offsetY = max(0, size.height - bounds.height + textContainerInset.bottom + textContainerInset.top)

        if abs(offsetY - contentOffset.y) > 0.5 {
            setContentOffset(CGPoint(x: 0, y: offsetY), animated: animated)
        }
    }

    private func checkAndAutoScroll() {
        guard autoScrollToBottom else { return }

        // 判定用户是否在底部附近（允许 40pt 的误差，兼容不同行高）
        let threshold: CGFloat = 40
        let isAtBottom = contentOffset.y + bounds.height >= contentSize.height - threshold
        if isAtBottom {
            scrollToBottom(animated: false)
        }
    }

    public private(set) var streamState: StreamState = .idle
    public private(set) var displayedLength: Int = 0
    public var totalLength: Int { fullAttrString?.length ?? 0 }

    // MARK: - 私有

    private var timer: DispatchSourceProtocol?
    private let timerQueue = DispatchQueue(label: "com.mmarkparser.stream.timer", qos: .userInteractive)
    private let parsingQueue = DispatchQueue(label: "com.mmarkparser.stream.parsing", qos: .userInteractive)
    private var fullAttrString: NSAttributedString?
    private var displayIndex: Int = 0
    private var accumulatedMarkdown: String = ""

    // MARK: - Init

    public convenience init() {
        self.init(frame: .zero, textContainer: nil)
    }

    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        self.isEditable = false
        self.isScrollEnabled = true
        self.backgroundColor = .systemBackground
        self.linkTextAttributes = [:]
        self.delegate = self
        registerCommonViewProviders()
    }

    // MARK: - Content Update

    /// 采用增量方式更新流式内容，避免 TextKit 2 全量重布局。
    private func updateStreamContent(to newIndex: Int) {
        guard let full = fullAttrString, newIndex <= full.length else { return }
        
        let currentLength = displayedLength
        guard newIndex > currentLength else {
            // 如果新索引变小了（通常是内容重置），则执行全量替换
            replaceStreamContent(with: full.attributedSubstring(from: NSRange(location: 0, length: newIndex)))
            return
        }

        let deltaRange = NSRange(location: currentLength, length: newIndex - currentLength)
        let deltaString = full.attributedSubstring(from: deltaRange)

        if #available(iOS 16.0, *),
           let layoutManager = self.textLayoutManager,
           let contentStorage = layoutManager.textContentManager as? NSTextContentStorage {
            contentStorage.performEditingTransaction {
                contentStorage.textStorage?.append(deltaString)
            }
        } else {
            textStorage.beginEditing()
            textStorage.append(deltaString)
            textStorage.endEditing()
        }
        
        displayedLength = newIndex
    }

    /// 替换全部流式内容。
    private func replaceStreamContent(with attributedString: NSAttributedString) {
        if #available(iOS 16.0, *),
           let layoutManager = self.textLayoutManager,
           let contentStorage = layoutManager.textContentManager as? NSTextContentStorage {
            // TextKit 2 路径
            contentStorage.performEditingTransaction {
                contentStorage.textStorage?.setAttributedString(attributedString)
            }
        } else {
            // TextKit 1 回退路径
            textStorage.beginEditing()
            textStorage.setAttributedString(attributedString)
            textStorage.endEditing()
        }
    }

    private func clearStreamContent() {
        if #available(iOS 16.0, *),
           let layoutManager = self.textLayoutManager,
           let contentStorage = layoutManager.textContentManager as? NSTextContentStorage {
            contentStorage.performEditingTransaction {
                contentStorage.textStorage?.setAttributedString(NSAttributedString())
            }
        } else if textStorage.length > 0 {
            textStorage.beginEditing()
            textStorage.replaceCharacters(in: NSRange(location: 0, length: textStorage.length), with: "")
            textStorage.endEditing()
        }
    }

    // MARK: - 流式 API

    public func startStreaming(markdown: String) {
        resetStreaming()

        guard !markdown.isEmpty else { return }

        accumulatedMarkdown = markdown

        parsingQueue.async { [weak self] in
            guard let self = self else { return }
            let parser = CMarkParser()
            let attrStr = (try? parser.parse(markdown, configuration: self.styleConfiguration)) ?? NSAttributedString(string: markdown)
            
            DispatchQueue.main.async {
                self.fullAttrString = attrStr
                self.displayIndex = 0
                self.displayedLength = 0

                self.clearStreamContent()

                self.streamState = .streaming
                self.streamDelegate?.didChangeState(.streaming)

                self.startTimer()
            }
        }
    }

    public func appendStreamContent(_ text: String) {
        guard !text.isEmpty else { return }

        if streamState == .idle {
            startStreaming(markdown: text)
            return
        }

        guard streamState == .streaming || streamState == .paused || streamState == .stopped else {
            return
        }

        accumulatedMarkdown += text

        parsingQueue.async { [weak self] in
            guard let self = self else { return }
            let parser = CMarkParser()
            guard let attrStr = try? parser.parse(self.accumulatedMarkdown, configuration: self.styleConfiguration) else {
                return
            }

            DispatchQueue.main.async {
                self.fullAttrString = attrStr

                if self.displayIndex >= attrStr.length {
                    return
                }

                if self.streamState == .stopped {
                    self.streamState = .streaming
                    self.streamDelegate?.didChangeState(.streaming)
                    self.startTimer()
                } else if self.streamState == .paused {
                    self.resumeStreaming()
                }
            }
        }
    }

    public func pauseStreaming() {
        guard streamState == .streaming else { return }
        streamState = .paused
        stopTimer()
        streamDelegate?.didChangeState(.paused)
    }

    public func resumeStreaming() {
        guard streamState == .paused else { return }
        streamState = .streaming
        streamDelegate?.didChangeState(.streaming)
        startTimer()
    }

    public func stopStreaming() {
        stopTimer()
        streamState = .stopped

        if let full = fullAttrString {
            replaceStreamContent(with: full)
            displayIndex = full.length
            displayedLength = full.length
        }

        notifySizeChanged()
        streamDelegate?.didChangeState(.stopped)
    }

    public func renderComplete(_ markdown: String) {
        resetStreaming()

        let parser = CMarkParser()
        guard let attrStr = try? parser.parse(markdown, configuration: styleConfiguration) else {
            return
        }

        fullAttrString = attrStr
        displayIndex = attrStr.length
        displayedLength = attrStr.length

        replaceStreamContent(with: attrStr)
        notifySizeChanged()
    }

    public func resetStreaming() {
        stopTimer()
        timer = nil
        fullAttrString = nil
        displayIndex = 0
        displayedLength = 0
        accumulatedMarkdown = ""
        streamState = .idle

        clearStreamContent()
        streamDelegate?.didChangeState(.idle)
    }

    // MARK: - Timer 驱动

    private func startTimer() {
        stopTimer()
        let timer = DispatchSource.makeTimerSource(queue: timerQueue)
        let intervalMs = max(16, Int(typingSpeed * 1000))
        timer.schedule(deadline: .now() + .milliseconds(intervalMs), repeating: .milliseconds(intervalMs), leeway: .milliseconds(2))
        timer.setEventHandler { [weak self] in
            self?.onTimerTick()
        }
        self.timer = timer
        timer.resume()
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    private func onTimerTick() {
        guard streamState == .streaming,
              let full = fullAttrString,
              displayIndex < full.length else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.streamState == .streaming else { return }
                self.stopTimer()
                self.streamState = .stopped
                self.notifySizeChanged()
                self.streamDelegate?.didChangeState(.stopped)
                self.streamDelegate?.didFinishStreaming()
            }
            return
        }

        // 性能优化：对于非常长的文档，自动增加 chunk 大小以维持视觉上的流式感
        let dynamicChunkSize = displayIndex > 5000 ? max(chunkSize, 15) : chunkSize
        let newIndex = min(displayIndex + dynamicChunkSize, full.length)
        guard newIndex > displayIndex else { return }

        displayIndex = newIndex

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.updateStreamContent(to: self.displayIndex)
            // 先通知外部尺寸变化，让宿主视图（如 TableViewCell）先调整好 frame
            self.notifySizeChanged()
            // 更新内部装饰
            self.updateBlockquoteBars()
            // 最后根据稳定的 frame 执行滚动
            self.checkAndAutoScroll()
        }
    }

    // MARK: - Blockquote Bar Rendering (TextKit 2)

    internal var isUpdatingBars = false

    private func updateBlockquoteBars() {
        renderBlockquoteBars(isUpdating: &isUpdatingBars, subviews: subviews)
    }

    // MARK: - Size Change

    private var lastNotifiedSize: CGSize = .zero

    private func notifySizeChanged() {
        let width = frame.width
        guard width > 0 else { return }

        // 不主动获取 layoutManager / textStorage（会激活 TextKit 1 bridge），
        // 直接通过 sizeThatFits（TextKit 2 模式下走 NSTextLayoutManager 路径）计算高度。
        let size = sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        let contentHeight = max(displayedLength > 0 ? 1 : 0, size.height)
        let rounded = CGSize(width: ceil(size.width), height: ceil(contentHeight))
        if abs(rounded.width - lastNotifiedSize.width) > 0.5 ||
           abs(rounded.height - lastNotifiedSize.height) > 0.5 {
            lastNotifiedSize = rounded
            streamDelegate?.onSizeChange(rounded)
        }
    }

    // MARK: - Deinit

    deinit {
        let timer = self.timer
        timerQueue.async {
            timer?.cancel()
        }
    }
}

// MARK: - Link Handling

@available(iOS 15.0, *)
extension MMarkStreamTextView: UITextViewDelegate {
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return self.handleCommonLink(URL, in: textView)
    }
}
