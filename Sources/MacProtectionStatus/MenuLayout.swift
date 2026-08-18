import CoreGraphics

/// Shared width for every custom menu row so the card grid, header rows, and
/// wrapped description text all line up and none of them force the menu wider
/// than intended, leaving the card grid looking like it doesn't fill the menu.
enum MenuLayout {
    static let contentWidth: CGFloat = 460
}
