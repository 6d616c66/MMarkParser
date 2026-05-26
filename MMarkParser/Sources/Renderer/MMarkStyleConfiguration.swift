import UIKit
@preconcurrency import iosMath

/// 列表前缀渲染模式
public enum ListMarkerMode {
    case character
    case image
}

/// Markdown 样式配置
public struct MMarkStyleConfiguration {
    /// 标题样式配置
    public struct HeadingStyle {
        public var font: UIFont
        public var textColor: UIColor

        public init(font: UIFont, textColor: UIColor) {
            self.font = font
            self.textColor = textColor
        }
    }

    /// 代码样式配置
    public struct CodeStyle {
        public var font: UIFont
        public var textColor: UIColor
        public var backgroundColor: UIColor

        public init(font: UIFont, textColor: UIColor, backgroundColor: UIColor) {
            self.font = font
            self.textColor = textColor
            self.backgroundColor = backgroundColor
        }
    }

    /// 链接样式配置
    public struct LinkStyle {
        public var textColor: UIColor
        public var underlineStyle: NSUnderlineStyle

        public init(textColor: UIColor, underlineStyle: NSUnderlineStyle = .single) {
            self.textColor = textColor
            self.underlineStyle = underlineStyle
        }
    }

    /// 有序列表样式
    public struct OrderedListStyle {
        public var mode: ListMarkerMode
        public var font: UIFont
        public var textColor: UIColor
        public var image: UIImage?
        /// 图标展示尺寸
        public var imageSize: CGSize

        public init(mode: ListMarkerMode = .character, font: UIFont, textColor: UIColor, image: UIImage? = nil, imageSize: CGSize = CGSize(width: 8, height: 8)) {
            self.mode = mode
            self.font = font
            self.textColor = textColor
            self.image = image
            self.imageSize = imageSize
        }
    }

    /// 无序列表样式
    public struct UnorderedListStyle {
        public var mode: ListMarkerMode
        public var font: UIFont
        public var textColor: UIColor
        /// 一级列表图标 (.image 模式)
        public var image: UIImage?
        /// 二级及以上列表图标 (.image 模式, nil 时回退到 image)
        public var secondaryImage: UIImage?
        /// 图标展示尺寸
        public var imageSize: CGSize

        public init(mode: ListMarkerMode = .character, font: UIFont, textColor: UIColor, image: UIImage? = nil, secondaryImage: UIImage? = nil, imageSize: CGSize = CGSize(width: 8, height: 8)) {
            self.mode = mode
            self.font = font
            self.textColor = textColor
            self.image = image
            self.secondaryImage = secondaryImage
            self.imageSize = imageSize
        }
    }

    /// H1-H6 标题样式
    public var headingStyles: [Int: HeadingStyle]
    /// 标题上间距 (paragraphSpacingBefore)，按级别配置
    public var headingSpacingBefore: [Int: CGFloat]
    /// 标题下间距 (paragraphSpacing)，按级别配置
    public var headingSpacing: [Int: CGFloat]
    /// 段落样式
    public var paragraphStyle: HeadingStyle
    /// 行内代码样式
    public var codeStyle: CodeStyle
    /// 代码块样式
    public var codeBlockStyle: CodeStyle
    /// 代码块 header 背景色
    public var codeBlockHeaderBackgroundColor: UIColor
    /// 代码块 body 背景色
    public var codeBlockBodyBackgroundColor: UIColor
    /// 代码块圆角
    public var codeBlockCornerRadius: CGFloat
    /// 代码块 header 高度
    public var codeBlockHeaderHeight: CGFloat
    /// 代码块内边距
    public var codeBlockPadding: CGFloat
    /// 链接样式
    public var linkStyle: LinkStyle
    /// 删除线颜色
    public var strikethroughColor: UIColor
    /// 引用块颜色
    public var blockquoteColor: UIColor
    /// 引用块背景颜色
    public var blockquoteBackgroundColor: UIColor
    /// 引用块左边框宽度
    public var blockquoteBorderWidth: CGFloat
    /// 引用块左边框颜色
    public var blockquoteBorderColor: UIColor
    /// 图片占位符颜色
    public var imagePlaceholderColor: UIColor
    /// 表格样式
    public var tableStyle: TableStyle
    /// 任务列表复选框样式
    public var taskListStyle: TaskListStyle
    /// 有序列表左侧序号样式
    public var orderedListStyle: OrderedListStyle
    /// 无序列表左侧前缀样式
    public var unorderedListStyle: UnorderedListStyle
    /// 行内数学公式样式
    public var mathInlineStyle: CodeStyle
    /// 块级数学公式样式
    public var mathBlockStyle: CodeStyle
    /// 块级数学公式背景色
    public var mathBlockBackgroundColor: UIColor
    /// 块级数学公式圆角
    public var mathBlockCornerRadius: CGFloat
    /// iosMath 渲染字体 (nil 时使用 Latin Modern Math 默认字体)
    public var mathDisplayFont: MTFont?

    /// 注脚引用样式（[N] 标记）
    public var footnoteReferenceStyle: CodeStyle
    /// 注脚定义文本样式
    public var footnoteStyle: HeadingStyle
    /// 注脚 ↩ 回链颜色
    public var footnoteBackrefColor: UIColor

    public struct TableStyle {
        public var headerBackgroundColor: UIColor
        public var borderColor: UIColor
        public var borderWidth: CGFloat
        public var cornerRadius: CGFloat

        public init(headerBackgroundColor: UIColor, borderColor: UIColor, borderWidth: CGFloat, cornerRadius: CGFloat = 8) {
            self.headerBackgroundColor = headerBackgroundColor
            self.borderColor = borderColor
            self.borderWidth = borderWidth
            self.cornerRadius = cornerRadius
        }
    }

    public struct TaskListStyle {
        public var mode: ListMarkerMode
        public var checkedColor: UIColor
        public var uncheckedColor: UIColor
        public var checkedFont: UIFont
        public var uncheckedFont: UIFont
        public var checkedImage: UIImage?
        public var uncheckedImage: UIImage?
        /// 图标展示尺寸
        public var imageSize: CGSize

        public init(mode: ListMarkerMode = .character, checkedColor: UIColor, uncheckedColor: UIColor,
                    checkedFont: UIFont, uncheckedFont: UIFont, checkedImage: UIImage? = nil,
                    uncheckedImage: UIImage? = nil, imageSize: CGSize = CGSize(width: 8, height: 8)) {
            self.mode = mode
            self.checkedColor = checkedColor
            self.uncheckedColor = uncheckedColor
            self.checkedFont = checkedFont
            self.uncheckedFont = uncheckedFont
            self.checkedImage = checkedImage
            self.uncheckedImage = uncheckedImage
            self.imageSize = imageSize
        }
    }

    /// 默认 GFM 样式配置
    public static var defaultStyle: MMarkStyleConfiguration {
        let headingFontBase = UIFont.systemFont(ofSize: 28, weight: .bold)
        let codeFont = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        // Try KaTeX fonts first, fall back to system serif/monospaced fonts
        let mathInlineFont = UIFont(name: "KaTeX_Math-Italic", size: 18)
        ?? UIFont(name: "KaTeX_Main-Regular", size: 18)
        ?? UIFont.italicSystemFont(ofSize: 18)
        let mathBlockFont = UIFont(name: "KaTeX_Main-Regular", size: 18)
        ?? UIFont.monospacedSystemFont(ofSize: 18, weight: .regular)

        return MMarkStyleConfiguration(
            headingStyles: [
                1: HeadingStyle(font: UIFont.systemFont(ofSize: 28, weight: .bold), textColor: .label),
                2: HeadingStyle(font: UIFont.systemFont(ofSize: 24, weight: .bold), textColor: .label),
                3: HeadingStyle(font: UIFont.systemFont(ofSize: 20, weight: .semibold), textColor: .label),
                4: HeadingStyle(font: UIFont.systemFont(ofSize: 18, weight: .semibold), textColor: .label),
                5: HeadingStyle(font: UIFont.systemFont(ofSize: 16, weight: .semibold), textColor: .label),
                6: HeadingStyle(font: UIFont.systemFont(ofSize: 14, weight: .semibold), textColor: .label)
            ],
            headingSpacingBefore: [1: 20, 2: 16, 3: 12, 4: 10, 5: 8, 6: 8],
            headingSpacing: [1: 12, 2: 10, 3: 8, 4: 6, 5: 6, 6: 6],
            paragraphStyle: HeadingStyle(font: UIFont.systemFont(ofSize: 16, weight: .regular), textColor: .label),
            codeStyle: CodeStyle(font: codeFont, textColor: .systemPink, backgroundColor: UIColor.systemGray.withAlphaComponent(0.1)),
            codeBlockStyle: CodeStyle(font: UIFont.monospacedSystemFont(ofSize: 14, weight: .regular), textColor: .black, backgroundColor: .systemGray),
            codeBlockHeaderBackgroundColor: UIColor.systemGray.withAlphaComponent(0.3),
            codeBlockBodyBackgroundColor: UIColor.systemGray.withAlphaComponent(0.1),
            codeBlockCornerRadius: 12,
            codeBlockHeaderHeight: 32,
            codeBlockPadding: 12,
            linkStyle: LinkStyle(textColor: .systemBlue),
            strikethroughColor: .systemRed,
            blockquoteColor: .label,
            blockquoteBackgroundColor: UIColor.systemGray6.withAlphaComponent(0.5),
            blockquoteBorderWidth: 4,
            blockquoteBorderColor: UIColor.systemGray3,
            imagePlaceholderColor: .systemGray4,
            tableStyle: TableStyle(
                headerBackgroundColor: .systemGray5,
                borderColor: .systemGray4,
                borderWidth: 0.5
            ),
            taskListStyle: TaskListStyle(
                checkedColor: .systemGreen,
                uncheckedColor: .systemGray,
                checkedFont: .systemFont(ofSize: 16, weight: .regular),
                uncheckedFont: .systemFont(ofSize: 16, weight: .regular)
            ),
            orderedListStyle: OrderedListStyle(
                font: .systemFont(ofSize: 16, weight: .regular),
                textColor: .label
            ),
            unorderedListStyle: UnorderedListStyle(
                font: .systemFont(ofSize: 16, weight: .regular),
                textColor: .label
            ),
            mathInlineStyle: CodeStyle(
                font: mathInlineFont,
                textColor: .label,
                backgroundColor: UIColor.systemPurple.withAlphaComponent(0.1)
            ),
            mathBlockStyle: CodeStyle(
                font: mathBlockFont,
                textColor: .label,
                backgroundColor: UIColor.systemPurple.withAlphaComponent(0.08)
            ),
            mathBlockBackgroundColor: UIColor.systemPurple.withAlphaComponent(0.05),
            mathBlockCornerRadius: 8,
            footnoteReferenceStyle: CodeStyle(
                font: .systemFont(ofSize: 12, weight: .semibold),
                textColor: .systemBlue,
                backgroundColor: .clear
            ),
            footnoteStyle: HeadingStyle(
                font: .systemFont(ofSize: 14, weight: .regular),
                textColor: .label
            ),
            footnoteBackrefColor: .systemBlue
        )
    }

    public init(
        headingStyles: [Int: HeadingStyle],
        headingSpacingBefore: [Int: CGFloat],
        headingSpacing: [Int: CGFloat],
        paragraphStyle: HeadingStyle,
        codeStyle: CodeStyle,
        codeBlockStyle: CodeStyle,
        codeBlockHeaderBackgroundColor: UIColor = UIColor.systemGray.withAlphaComponent(0.3),
        codeBlockBodyBackgroundColor: UIColor = UIColor.systemGray.withAlphaComponent(0.1),
        codeBlockCornerRadius: CGFloat = 12,
        codeBlockHeaderHeight: CGFloat = 32,
        codeBlockPadding: CGFloat = 12,
        linkStyle: LinkStyle,
        strikethroughColor: UIColor,
        blockquoteColor: UIColor,
        blockquoteBackgroundColor: UIColor,
        blockquoteBorderWidth: CGFloat,
        blockquoteBorderColor: UIColor,
        imagePlaceholderColor: UIColor,
        tableStyle: TableStyle,
        taskListStyle: TaskListStyle,
        orderedListStyle: OrderedListStyle = OrderedListStyle(
            font: .systemFont(ofSize: 16, weight: .regular),
            textColor: .label
        ),
        unorderedListStyle: UnorderedListStyle = UnorderedListStyle(
            font: .systemFont(ofSize: 16, weight: .regular),
            textColor: .label
        ),
        mathInlineStyle: CodeStyle,
        mathBlockStyle: CodeStyle,
        mathBlockBackgroundColor: UIColor,
        mathBlockCornerRadius: CGFloat,
        mathDisplayFont: MTFont? = nil,
        footnoteReferenceStyle: CodeStyle,
        footnoteStyle: HeadingStyle,
        footnoteBackrefColor: UIColor
    ) {
        self.headingStyles = headingStyles
        self.headingSpacingBefore = headingSpacingBefore
        self.headingSpacing = headingSpacing
        self.paragraphStyle = paragraphStyle
        self.codeStyle = codeStyle
        self.codeBlockStyle = codeBlockStyle
        self.codeBlockHeaderBackgroundColor = codeBlockHeaderBackgroundColor
        self.codeBlockBodyBackgroundColor = codeBlockBodyBackgroundColor
        self.codeBlockCornerRadius = codeBlockCornerRadius
        self.codeBlockHeaderHeight = codeBlockHeaderHeight
        self.codeBlockPadding = codeBlockPadding
        self.linkStyle = linkStyle
        self.strikethroughColor = strikethroughColor
        self.blockquoteColor = blockquoteColor
        self.blockquoteBackgroundColor = blockquoteBackgroundColor
        self.blockquoteBorderWidth = blockquoteBorderWidth
        self.blockquoteBorderColor = blockquoteBorderColor
        self.imagePlaceholderColor = imagePlaceholderColor
        self.tableStyle = tableStyle
        self.taskListStyle = taskListStyle
        self.orderedListStyle = orderedListStyle
        self.unorderedListStyle = unorderedListStyle
        self.mathInlineStyle = mathInlineStyle
        self.mathBlockStyle = mathBlockStyle
        self.mathBlockBackgroundColor = mathBlockBackgroundColor
        self.mathBlockCornerRadius = mathBlockCornerRadius
        self.mathDisplayFont = mathDisplayFont
        self.footnoteReferenceStyle = footnoteReferenceStyle
        self.footnoteStyle = footnoteStyle
        self.footnoteBackrefColor = footnoteBackrefColor
    }
}
