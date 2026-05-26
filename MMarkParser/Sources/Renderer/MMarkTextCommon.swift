import UIKit

extension DispatchQueue {
    /// 确保在主线程执行闭包。如果在主线程则直接执行，否则同步派发到主线程。
    /// 适用于需要从后台解析线程同步获取 UI 尺寸或渲染图片的场景。
    static func mainSyncSafe<T>(_ block: () -> T) -> T {
        if Thread.isMainThread {
            return block()
        } else {
            return main.sync { block() }
        }
    }
}

/// Delegate protocol for handling link taps in Markdown content.
@available(iOS 15.0, *)
@MainActor
public protocol MMarkLinkDelegate: AnyObject {
    /// Called when the user taps a link, footnote reference, or anchor in the text view.
    /// - Parameters:
    ///   - textView: The text view that received the tap.
    ///   - url: The tapped URL, or nil if the URL could not be parsed.
    /// - Returns: `true` to let MMarkParser handle the link (default behavior), `false` to take over completely.
    func mmarkTextView(_ textView: UITextView, shouldOpen url: URL?) -> Bool
}

/// 内部协议，用于统一 MMarkTextView 和 MMarkStreamTextView 的共有逻辑
@available(iOS 15.0, *)
@MainActor
internal protocol MMarkTextComponent: AnyObject {
    var styleConfiguration: MMarkStyleConfiguration { get }
    var mmarkLinkDelegate: MMarkLinkDelegate? { get set }
}

@available(iOS 15.0, *)
extension MMarkTextComponent where Self: UITextView {
    
    /// 注册自定义附件视图提供者
    internal func registerCommonViewProviders() {
        NSTextAttachment.registerViewProviderClass(MMarkCodeBlockViewProvider.self, forFileType: MMarkBaseAttachment.fileType)
        NSTextAttachment.registerViewProviderClass(MMarkTableViewProvider.self, forFileType: MMarkBaseAttachment.fileType)
        NSTextAttachment.registerViewProviderClass(MMarkMathBlockViewProvider.self, forFileType: MMarkBaseAttachment.fileType)
        NSTextAttachment.registerViewProviderClass(MMarkImageViewProvider.self, forFileType: MMarkBaseAttachment.fileType)
        NSTextAttachment.registerViewProviderClass(MMarkListMarkerViewProvider.self, forFileType: MMarkBaseAttachment.fileType)
    }
    
    /// 处理通用链接跳转（脚注和锚点）
    internal func handleCommonLink(_ URL: URL?, in textView: UITextView) -> Bool {
        // 1. 优先回调给外部代理
        if let delegate = self.mmarkLinkDelegate {
            let shouldContinue = delegate.mmarkTextView(textView, shouldOpen: URL)
            if !shouldContinue { return false }
        }
        
        guard let URL = URL else { return false }
        
        let scheme = URL.scheme?.lowercased()
        let isWebLink = scheme == "http" || scheme == "https" || scheme == "mailto" || scheme == "tel"
        
        // 如果不是标准网页链接，我们应该内部处理或拦截，防止系统尝试打开导致 crash 或权限错误
        guard let attributedText = textView.attributedText, attributedText.length > 0 else { return isWebLink }
        
        // 2. 内部逻辑：脚注处理
        if scheme == "footnote" {
            let components = URL.path.split(separator: "/").filter { !$0.isEmpty }.map(String.init)
            guard components.count >= 2 else { return false }
            let label = components[1]
            let fullRange = NSRange(location: 0, length: attributedText.length)
            var targetRange: NSRange?
            
            attributedText.enumerateAttribute(.footnoteDef, in: fullRange) { value, range, stop in
                if let val = value as? String, val == label { targetRange = range; stop.pointee = true }
            }
            if targetRange == nil {
                attributedText.enumerateAttribute(.footnoteRef, in: fullRange) { value, range, stop in
                    if let val = value as? String, val == label { targetRange = range; stop.pointee = true }
                }
            }
            if let scrollRange = targetRange { textView.scrollRangeToVisible(scrollRange) }
            return false
        }
        
        // 3. 内部逻辑：锚点跳转
        let absoluteStr = URL.absoluteString
        let hasFragment = URL.fragment != nil
        // 判定条件：没有 scheme 且以 # 开头，或者是纯片段链接，或者是一个带有片段的 Web 链接（我们先尝试本地跳转）
        let isPotentialInternalAnchor = (scheme == nil && (absoluteStr.hasPrefix("#") || hasFragment)) || absoluteStr.hasPrefix("#")
        
        if isPotentialInternalAnchor {
            let fragment = URL.fragment ?? (absoluteStr.hasPrefix("#") ? String(absoluteStr.dropFirst()) : absoluteStr)
            let decoded = fragment.removingPercentEncoding ?? fragment
            guard !decoded.isEmpty else { return isWebLink }
            
            let nsText = attributedText.string as NSString
            let fullRange = NSRange(location: 0, length: nsText.length)
            var foundRange: NSRange?
            
            // 尝试查找匹配的标题文本（模糊匹配大小写和空格）
            let cleanFragment = decoded.lowercased().replacingOccurrences(of: "-", with: " ")
            
            nsText.enumerateSubstrings(in: fullRange, options: .byLines) { substring, range, _, stop in
                guard let line = substring?.lowercased() else { return }
                if line.contains(cleanFragment) {
                    foundRange = range
                    stop.pointee = true
                }
            }
            
            if foundRange == nil {
                let r = nsText.range(of: decoded, options: [.caseInsensitive])
                if r.location != NSNotFound { foundRange = r }
            }
            
            if let scrollRange = foundRange {
                DispatchQueue.main.async { [weak textView] in
                    guard let textView = textView, let currentAttrText = textView.attributedText else { return }
                    if scrollRange.location + scrollRange.length <= currentAttrText.length {
                        textView.scrollRangeToVisible(scrollRange)
                    }
                }
                return false
            }
            // 如果没找到本地锚点，但它本身是个 Web 链接，则允许系统尝试打开
            return isWebLink
        }
        
        return isWebLink
    }
    
    /// 渲染引用块侧边条
    internal func renderBlockquoteBars(isUpdating: inout Bool, subviews: [UIView]) {
        guard !isUpdating else { return }
        isUpdating = true
        defer { isUpdating = false }

        // 移除所有旧的引用条 layer
        layer.sublayers?.filter { $0.name == "MMarkBlockquoteBar" }.forEach { $0.removeFromSuperlayer() }
        
        guard let attributedText = self.attributedText, attributedText.length > 0 else { return }

        let fullRange = NSRange(location: 0, length: attributedText.length)
        
        // 收集所有引用块的范围和深度
        var blockquoteRanges: [(range: NSRange, depth: Int)] = []
        
        attributedText.enumerateAttribute(.blockquote, in: fullRange) { value, range, stop in
            guard value != nil else { return }
            let depth = attributedText.attribute(.blockquoteDepth, at: range.location, effectiveRange: nil) as? Int ?? 1
            blockquoteRanges.append((range, depth))
        }
        
        // 按深度分组，合并连续的相同深度的引用块
        var depthRanges: [Int: [NSRange]] = [:]
        for (range, depth) in blockquoteRanges {
            // 为当前深度及其所有父级深度添加范围
            for level in 1...depth {
                if depthRanges[level] == nil {
                    depthRanges[level] = []
                }
                depthRanges[level]?.append(range)
            }
        }
        
        // 为每个深度层级创建连续的引用条
        for (depth, ranges) in depthRanges {
            // 合并重叠或相邻的范围
            let mergedRanges = mergeRanges(ranges)
            
            for range in mergedRanges {
                if #available(iOS 16.0, *), let tlm = self.textLayoutManager {
                    guard let startPos = tlm.location(tlm.documentRange.location, offsetBy: range.location),
                          let endPos = tlm.location(startPos, offsetBy: range.length),
                          let textRange = NSTextRange(location: startPos, end: endPos) else { continue }

                    var minY = CGFloat.greatestFiniteMagnitude
                    var maxY: CGFloat = 0
                    var found = false
                    
                    tlm.enumerateTextLayoutFragments(from: textRange.location, options: [.ensuresLayout, .ensuresExtraLineFragment]) { fragment in
                        let fragRange = fragment.rangeInElement
                        guard fragRange.intersects(textRange) else { return true }
                        let rect = fragment.layoutFragmentFrame
                        if rect.isNull || rect.isEmpty { return true }
                        minY = min(minY, rect.minY)
                        maxY = max(maxY, rect.maxY)
                        found = true
                        return true
                    }
                    
                    if found && maxY > minY {
                        let borderWidth = styleConfiguration.blockquoteBorderWidth
                        let spacing: CGFloat = 8.0
                        let blockquoteIndent: CGFloat = borderWidth + spacing
                        let barX = textContainerInset.left + CGFloat(depth - 1) * blockquoteIndent
                        
                        // 使用段落样式的行高，如果没有则使用字体行高
                        var lineHeight: CGFloat = styleConfiguration.paragraphStyle.font.lineHeight
                        if let ps = attributedText.attribute(.paragraphStyle, at: range.location, effectiveRange: nil) as? NSParagraphStyle {
                            if let font = attributedText.attribute(.font, at: range.location, effectiveRange: nil) as? UIFont {
                                lineHeight = font.lineHeight + ps.lineSpacing
                            }
                        }
                        let verticalOffset = lineHeight * 0.5
                        
                        let barLayer = CALayer()
                        barLayer.name = "MMarkBlockquoteBar"
                        barLayer.frame = CGRect(
                            x: barX,
                            y: minY + verticalOffset,
                            width: borderWidth,
                            height: maxY - minY
                        )
                        barLayer.backgroundColor = styleConfiguration.blockquoteBorderColor.cgColor
                        layer.addSublayer(barLayer)
                    }
                } else {
                    // TextKit 1: 需要遍历所有行来计算完整高度
                    let layoutManager = self.layoutManager
                    
                    let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
                    var minY = CGFloat.greatestFiniteMagnitude
                    var maxY: CGFloat = 0
                    var found = false
                    
                    layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { rect, usedRect, textContainer, glyphRange, stop in
                        minY = min(minY, rect.minY)
                        maxY = max(maxY, rect.maxY)
                        found = true
                    }
                    
                    if found && maxY > minY {
                        let borderWidth = styleConfiguration.blockquoteBorderWidth
                        let spacing: CGFloat = 8.0
                        let blockquoteIndent: CGFloat = borderWidth + spacing
                        let barX = textContainerInset.left + CGFloat(depth - 1) * blockquoteIndent
                        
                        // 使用段落样式的行高，如果没有则使用字体行高
                        var lineHeight: CGFloat = styleConfiguration.paragraphStyle.font.lineHeight
                        if let ps = attributedText.attribute(.paragraphStyle, at: range.location, effectiveRange: nil) as? NSParagraphStyle {
                            if let font = attributedText.attribute(.font, at: range.location, effectiveRange: nil) as? UIFont {
                                lineHeight = font.lineHeight + ps.lineSpacing
                            }
                        }
                        let verticalOffset = lineHeight * 0.5
                        
                        let barLayer = CALayer()
                        barLayer.name = "MMarkBlockquoteBar"
                        barLayer.frame = CGRect(
                            x: barX,
                            y: minY + textContainerInset.top + verticalOffset,
                            width: borderWidth,
                            height: maxY - minY
                        )
                        barLayer.backgroundColor = styleConfiguration.blockquoteBorderColor.cgColor
                        layer.addSublayer(barLayer)
                    }
                }
            }
        }
    }
    
    /// 合并重叠或相邻的范围
    private func mergeRanges(_ ranges: [NSRange]) -> [NSRange] {
        guard !ranges.isEmpty else { return [] }
        
        let sorted = ranges.sorted { $0.location < $1.location }
        var merged: [NSRange] = []
        var current = sorted[0]
        
        for i in 1..<sorted.count {
            let next = sorted[i]
            let currentEnd = current.location + current.length
            let nextStart = next.location
            
            // 如果范围重叠或相邻（允许小间隙），则合并
            if nextStart <= currentEnd + 2 {
                let newEnd = max(currentEnd, next.location + next.length)
                current = NSRange(location: current.location, length: newEnd - current.location)
            } else {
                merged.append(current)
                current = next
            }
        }
        merged.append(current)
        
        return merged
    }
}
