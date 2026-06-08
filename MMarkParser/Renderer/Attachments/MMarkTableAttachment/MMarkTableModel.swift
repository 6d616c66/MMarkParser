import UIKit

// MARK: - MMarkTableModel

@available(iOS 15.0, *)
public class MMarkTableModel: MMarkBaseModel {
    public let columnWidths: [CGFloat]
    public let rowHeights: [CGFloat]
    public let headerCells: [NSAttributedString]
    public let dataRows: [[NSAttributedString]]
    public let alignments: [NSTextAlignment]
    public let tableConfig: MMarkTableView.MMarkTableConfig

    public init(size: CGSize, columnWidths: [CGFloat], rowHeights: [CGFloat],
                headerCells: [NSAttributedString], dataRows: [[NSAttributedString]],
                alignments: [NSTextAlignment] = [],
                tableConfig: MMarkTableView.MMarkTableConfig = .init()) {
        self.columnWidths = columnWidths
        self.rowHeights = rowHeights
        self.headerCells = headerCells
        self.dataRows = dataRows
        self.alignments = alignments
        self.tableConfig = tableConfig
        super.init(size: size)
    }

    /// 工厂方法：根据 headerCells、dataRows、containerWidth 计算 size 并创建模型
    public static func create(headerCells: [NSAttributedString], dataRows: [[NSAttributedString]],
                               alignments: [NSTextAlignment] = [], width: CGFloat,
                               configuration: MMarkStyleConfiguration = .defaultStyle) -> MMarkTableModel {
        var config = MMarkTableView.MMarkTableConfig()
        config.headerBackgroundColor = configuration.tableStyle.headerBackgroundColor
        config.separatorColor = configuration.tableStyle.borderColor
        config.separatorWidth = configuration.tableStyle.borderWidth
        config.cornerRadius = configuration.tableStyle.cornerRadius
        let constraint = MMarkTableView.CellSizeConstraint()
        let padding = config.cellPadding

        var columnWidths: [CGFloat] = Array(repeating: constraint.minWidth, count: headerCells.count)
        var rowHeights: [CGFloat] = []
        var headerRowHeight = config.headerHeight

        for (colIndex, header) in headerCells.enumerated() {
            let textSize = header.boundingRect(
                with: CGSize(width: constraint.maxWidth - padding * 2, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            ).size
            columnWidths[colIndex] = max(columnWidths[colIndex], min(max(textSize.width + padding * 2, constraint.minWidth), constraint.maxWidth))
            headerRowHeight = max(headerRowHeight, textSize.height + padding * 2)
        }
        rowHeights.append(headerRowHeight)

        for row in dataRows {
            var maxRowHeight = config.rowHeight
            for (colIndex, cellText) in row.enumerated() {
                let textSize = cellText.boundingRect(
                    with: CGSize(width: constraint.maxWidth - padding * 2, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                ).size
                columnWidths[colIndex] = max(columnWidths[colIndex], min(max(textSize.width + padding * 2, constraint.minWidth), constraint.maxWidth))
                maxRowHeight = max(maxRowHeight, textSize.height + padding * 2)
            }
            rowHeights.append(max(maxRowHeight, constraint.minHeight))
        }

        let totalWidth = columnWidths.reduce(0, +)
        let totalHeight = rowHeights.reduce(0, +)
        let size = CGSize(width: totalWidth, height: totalHeight)

        return MMarkTableModel(size: size, columnWidths: columnWidths, rowHeights: rowHeights, headerCells: headerCells, dataRows: dataRows, alignments: alignments, tableConfig: config)
    }
}
