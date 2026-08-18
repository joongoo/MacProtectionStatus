import AppKit

/// Menu row that lays statuses out as a 3-column card grid: icon with a
/// status badge, a short title, and a fully-visible (never truncated) detail
/// line per card. Row height grows to fit whichever card in the row has the
/// most text.
final class SecurityGridView: NSView {
    private static let columns = 3
    private static let spacing: CGFloat = 8
    private static let inset: CGFloat = 12

    init(statuses: [StatusItem], width: CGFloat = MenuLayout.contentWidth) {
        let cardWidth = (width - Self.inset * 2 - Self.spacing * CGFloat(Self.columns - 1)) / CGFloat(Self.columns)
        let rowCount = (statuses.count + Self.columns - 1) / Self.columns

        let cards = statuses.map { SecurityCardView(item: $0, width: cardWidth) }
        var rowHeights: [CGFloat] = []
        for row in 0..<rowCount {
            let rowCards = cards[(row * Self.columns)..<min((row + 1) * Self.columns, cards.count)]
            rowHeights.append(rowCards.map(\.fittingCardHeight).max() ?? 0)
        }
        let height = Self.inset * 2 + rowHeights.reduce(0, +) + Self.spacing * CGFloat(max(0, rowCount - 1))

        super.init(frame: NSRect(x: 0, y: 0, width: width, height: height))

        var y = height - Self.inset
        for row in 0..<rowCount {
            let rowHeight = rowHeights[row]
            y -= rowHeight
            for col in 0..<Self.columns {
                let index = row * Self.columns + col
                guard index < cards.count else { continue }
                let card = cards[index]
                let x = Self.inset + CGFloat(col) * (cardWidth + Self.spacing)
                card.frame = NSRect(x: x, y: y, width: cardWidth, height: rowHeight)
                addSubview(card)
            }
            y -= Self.spacing
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class SecurityCardView: NSView {
    let fittingCardHeight: CGFloat

    init(item: StatusItem, width: CGFloat) {
        let textInset: CGFloat = 8
        let textWidth = width - textInset * 2

        let titleLabel = NSTextField(wrappingLabelWithString: item.shortTitle)
        titleLabel.font = NSFont.systemFont(ofSize: 11.5, weight: .semibold)
        titleLabel.alignment = .center
        titleLabel.preferredMaxLayoutWidth = textWidth

        let detailLabel = NSTextField(wrappingLabelWithString: item.detail)
        detailLabel.font = NSFont.systemFont(ofSize: 9.5)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.alignment = .center
        detailLabel.preferredMaxLayoutWidth = textWidth

        let iconBlockHeight: CGFloat = 33
        let topPadding: CGFloat = 9
        let titleTopGap: CGFloat = 6
        let detailTopGap: CGFloat = 3
        let bottomPadding: CGFloat = 8

        fittingCardHeight = topPadding + iconBlockHeight + titleTopGap + titleLabel.fittingSize.height
            + detailTopGap + detailLabel.fittingSize.height + bottomPadding

        super.init(frame: .zero)

        let iconColor: NSColor = item.ok ? .controlAccentColor : .systemOrange
        let icon = NSImageView()
        icon.image = NSImage(systemSymbolName: item.symbolName, accessibilityDescription: nil)
        icon.contentTintColor = iconColor
        icon.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        icon.translatesAutoresizingMaskIntoConstraints = false

        let badge = NSImageView()
        badge.image = NSImage(
            systemSymbolName: item.ok ? "checkmark.circle.fill" : "exclamationmark.circle.fill",
            accessibilityDescription: nil
        )
        badge.contentTintColor = item.ok ? .systemGreen : .systemOrange
        badge.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 11, weight: .bold)
        badge.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(icon)
        addSubview(badge)
        addSubview(titleLabel)
        addSubview(detailLabel)

        NSLayoutConstraint.activate([
            icon.topAnchor.constraint(equalTo: topAnchor, constant: topPadding),
            icon.centerXAnchor.constraint(equalTo: centerXAnchor),
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24),

            badge.trailingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 6),
            badge.bottomAnchor.constraint(equalTo: icon.bottomAnchor, constant: 3),
            badge.widthAnchor.constraint(equalToConstant: 12),
            badge.heightAnchor.constraint(equalToConstant: 12),

            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: topPadding + iconBlockHeight + titleTopGap),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: textInset),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -textInset),

            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: detailTopGap),
            detailLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: textInset),
            detailLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -textInset),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
