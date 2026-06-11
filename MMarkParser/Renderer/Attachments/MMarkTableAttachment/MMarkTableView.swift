import UIKit

// MARK: - Custom Table Layout

@available(iOS 15.0, *)
final class MMarkTableLayout: UICollectionViewLayout {
    weak var tableView: MMarkTableView?
    private var layoutAttributes: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    private var contentSize: CGSize = .zero

    override func prepare() {
        super.prepare()
        guard let tableView = tableView, let collectionView = collectionView else { return }

        guard !tableView.columnWidths.isEmpty, !tableView.rowHeights.isEmpty else { return }

        layoutAttributes.removeAll()
        var yOffset: CGFloat = 0
        let numberOfSections = collectionView.numberOfSections

        for section in 0..<numberOfSections {
            var xOffset: CGFloat = 0
            let numberOfItems = collectionView.numberOfItems(inSection: section)
            let rowHeight = section < tableView.rowHeights.count ? tableView.rowHeights[section] : 28

            for item in 0..<numberOfItems {
                let indexPath = IndexPath(item: item, section: section)
                let columnWidth = item < tableView.columnWidths.count ? tableView.columnWidths[item] : 60

                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = CGRect(x: xOffset, y: yOffset, width: columnWidth, height: rowHeight)
                layoutAttributes[indexPath] = attributes

                xOffset += columnWidth
            }
            yOffset += rowHeight
        }

        let totalWidth = tableView.columnWidths.reduce(0, +)
        let totalHeight = tableView.rowHeights.reduce(0, +)
        contentSize = CGSize(width: totalWidth, height: totalHeight)
    }

    override var collectionViewContentSize: CGSize {
        return contentSize
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return layoutAttributes.values.filter { $0.frame.intersects(rect) }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return layoutAttributes[indexPath]
    }
}

// MARK: - MMarkTableView

@available(iOS 15.0, *)
public final class MMarkTableView: UIView {

    public var headerCells: [NSAttributedString] = []
    public var dataRows: [[NSAttributedString]] = []
    public var alignments: [NSTextAlignment] = []

    public struct CellSizeConstraint {
        public var minWidth: CGFloat = 36
        public var maxWidth: CGFloat = 96
        public var minHeight: CGFloat = 28

        public init() {}
    }

    public static var cellConstraint = CellSizeConstraint()

    public struct MMarkTableConfig {
        public var headerBackgroundColor: UIColor = .systemGray5
        public var rowBackgroundColor: UIColor = .systemBackground
        public var alternatingRowColors: Bool = true
        public var headerFont: UIFont = .boldSystemFont(ofSize: 12)
        public var cellFont: UIFont = .systemFont(ofSize: 12)
        public var textColor: UIColor = .label
        public var cellPadding: CGFloat = 8
        public var headerHeight: CGFloat = 32
        public var rowHeight: CGFloat = 28
        public var separatorColor: UIColor = .systemGray4
        public var separatorWidth: CGFloat = 0.5
        public var cornerRadius: CGFloat = 8

        public init() {}
    }

    public static var defaultConfig = MMarkTableConfig()
    public var config: MMarkTableConfig = .init()

    fileprivate var columnWidths: [CGFloat] = []
    fileprivate var rowHeights: [CGFloat] = []

    private var collectionView: UICollectionView!

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupCollectionView()
    }

    public convenience init(model: MMarkTableModel) {
        self.init(frame: CGRect(origin: .zero, size: model.size))
        self.config = model.tableConfig
        self.headerCells = model.headerCells
        self.dataRows = model.dataRows
        self.alignments = model.alignments
        self.columnWidths = model.columnWidths
        self.rowHeights = model.rowHeights
        layer.borderColor = config.separatorColor.cgColor
        layer.borderWidth = config.separatorWidth
        layer.cornerRadius = config.cornerRadius
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCollectionView() {
        let layout = MMarkTableLayout()
        layout.tableView = self
        collectionView = UICollectionView(frame: bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isScrollEnabled = true
        collectionView.register(MMarkTableCell.self, forCellWithReuseIdentifier: MMarkTableCell.reuseIdentifier)
        collectionView.register(MMarkTableHeaderCell.self, forCellWithReuseIdentifier: MMarkTableHeaderCell.reuseIdentifier)
        addSubview(collectionView)

        layer.borderColor = config.separatorColor.cgColor
        layer.borderWidth = config.separatorWidth
        layer.cornerRadius = config.cornerRadius
        layer.masksToBounds = true
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.frame = bounds
    }

    public override var intrinsicContentSize: CGSize {
        return CGSize(width: frame.width, height: frame.height)
    }

    func setColumnWidths(_ widths: [CGFloat], rowHeights heights: [CGFloat]) {
        columnWidths = widths
        rowHeights = heights
        collectionView.reloadData()
    }
}

@available(iOS 15.0, *)
extension MMarkTableView: UICollectionViewDataSource, UICollectionViewDelegate {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1 + dataRows.count
    }
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return headerCells.count
    }
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let isHeader = indexPath.section == 0
        let colWidth = columnWidths[indexPath.item]
        let alignment = indexPath.item < alignments.count ? alignments[indexPath.item] : .left
        let isLastColumn = indexPath.item == headerCells.count - 1
        let isLastRow = indexPath.section == collectionView.numberOfSections - 1
        if isHeader {
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MMarkTableHeaderCell.reuseIdentifier, for: indexPath
            ) as? MMarkTableHeaderCell else {
                return UICollectionViewCell()
            }
            cell.configure(attributedText: headerCells[indexPath.item], config: config, columnWidth: colWidth, alignment: alignment, isLastColumn: isLastColumn, isLastRow: isLastRow)
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MMarkTableCell.reuseIdentifier, for: indexPath
            ) as? MMarkTableCell else {
                return UICollectionViewCell()
            }
            let isAlternate = config.alternatingRowColors && indexPath.section % 2 == 0
            let bgColor = isAlternate
                ? config.rowBackgroundColor.withAlphaComponent(0.5)
                : config.rowBackgroundColor
            cell.configure(attributedText: dataRows[indexPath.section - 1][indexPath.item],
                           config: config, columnWidth: colWidth,
                           backgroundColor: bgColor,
                           alignment: alignment,
                           isLastColumn: isLastColumn, isLastRow: isLastRow)
            return cell
        }
    }
}

// MARK: - MMarkTableCell

@available(iOS 15.0, *)
public final class MMarkTableCell: UICollectionViewCell {
    public static let reuseIdentifier = "MMarkTableCell"
    private let textView = UITextView()
    private let rightSeparator = UIView()
    private let bottomSeparator = UIView()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        textView.font = .systemFont(ofSize: 12)
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.backgroundColor = .clear
        contentView.addSubview(textView)
        rightSeparator.backgroundColor = .systemGray4
        bottomSeparator.backgroundColor = .systemGray4
        contentView.addSubview(rightSeparator)
        contentView.addSubview(bottomSeparator)
    }
    required init?(coder: NSCoder) { fatalError() }
    public func configure(attributedText: NSAttributedString, config: MMarkTableView.MMarkTableConfig,
                           columnWidth: CGFloat, backgroundColor: UIColor,
                           alignment: NSTextAlignment = .left,
                           isLastColumn: Bool = false, isLastRow: Bool = false) {
        let padding = config.cellPadding
        let textWidth = max(0, columnWidth - padding * 2)
        textView.attributedText = attributedText
        textView.textAlignment = alignment
        contentView.backgroundColor = backgroundColor
        textView.frame = CGRect(x: padding, y: 0, width: textWidth, height: bounds.height)
        // Vertical center
        let fitSize = textView.sizeThatFits(CGSize(width: textWidth, height: .greatestFiniteMagnitude))
        let topInset = max(0, (bounds.height - fitSize.height) / 2)
        textView.textContainerInset = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
        let sw = config.separatorWidth
        rightSeparator.backgroundColor = config.separatorColor
        bottomSeparator.backgroundColor = config.separatorColor
        rightSeparator.frame = CGRect(x: columnWidth - sw, y: 0, width: sw, height: bounds.height)
        bottomSeparator.frame = CGRect(x: 0, y: bounds.height - sw, width: columnWidth, height: sw)
        rightSeparator.isHidden = isLastColumn || sw <= 0
        bottomSeparator.isHidden = isLastRow || sw <= 0
    }
}

// MARK: - MMarkTableHeaderCell

@available(iOS 15.0, *)
public final class MMarkTableHeaderCell: UICollectionViewCell {
    public static let reuseIdentifier = "MMarkTableHeaderCell"
    private let textView = UITextView()
    private let rightSeparator = UIView()
    private let bottomSeparator = UIView()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        textView.font = .boldSystemFont(ofSize: 12)
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.backgroundColor = .clear
        contentView.addSubview(textView)
        rightSeparator.backgroundColor = .systemGray4
        bottomSeparator.backgroundColor = .systemGray4
        contentView.addSubview(rightSeparator)
        contentView.addSubview(bottomSeparator)
    }
    required init?(coder: NSCoder) { fatalError() }
    public func configure(attributedText: NSAttributedString, config: MMarkTableView.MMarkTableConfig,
                           columnWidth: CGFloat, alignment: NSTextAlignment = .left,
                           isLastColumn: Bool = false, isLastRow: Bool = false) {
        let padding = config.cellPadding
        let textWidth = max(0, columnWidth - padding * 2)
        textView.attributedText = attributedText
        textView.textAlignment = alignment
        contentView.backgroundColor = config.headerBackgroundColor
        textView.frame = CGRect(x: padding, y: 0, width: textWidth, height: bounds.height)
        // Vertical center
        let fitSize = textView.sizeThatFits(CGSize(width: textWidth, height: .greatestFiniteMagnitude))
        let topInset = max(0, (bounds.height - fitSize.height) / 2)
        textView.textContainerInset = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
        let sw = config.separatorWidth
        rightSeparator.backgroundColor = config.separatorColor
        bottomSeparator.backgroundColor = config.separatorColor
        rightSeparator.frame = CGRect(x: columnWidth - sw, y: 0, width: sw, height: bounds.height)
        bottomSeparator.frame = CGRect(x: 0, y: bounds.height - sw, width: columnWidth, height: sw)
        rightSeparator.isHidden = isLastColumn || sw <= 0
        bottomSeparator.isHidden = isLastRow || sw <= 0
    }
}
