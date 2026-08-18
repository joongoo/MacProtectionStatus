import AppKit

// Picks Korean copy only when the machine running this build script is set
// to Korean; every other locale falls back to English. This only reflects
// the *build* machine's language, not the end user installing the DMG,
// since the background image is baked in at build time.
let isKorean = (Locale.current.language.languageCode?.identifier == "ko")

let width: CGFloat = 660
let height: CGFloat = 400
let scale: CGFloat = 1.0 // create-dmg/Finder render this 1:1 in points, no @2x auto-detection

let pxWidth = width * scale
let pxHeight = height * scale

let image = NSImage(size: NSSize(width: pxWidth, height: pxHeight))
image.lockFocus()

let rect = NSRect(x: 0, y: 0, width: pxWidth, height: pxHeight)

let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.09, green: 0.14, blue: 0.32, alpha: 1.0),
    NSColor(calibratedRed: 0.16, green: 0.24, blue: 0.55, alpha: 1.0),
])
gradient?.draw(in: rect, angle: -60)

// Arrow between the two icon slots
let arrowConfig = NSImage.SymbolConfiguration(pointSize: 44 * scale, weight: .regular)
    .applying(.init(paletteColors: [NSColor.white.withAlphaComponent(0.85)]))
if let arrow = NSImage(systemSymbolName: "arrow.right", accessibilityDescription: nil)?
    .withSymbolConfiguration(arrowConfig) {
    let arrowSize = arrow.size
    let arrowRect = NSRect(
        x: (pxWidth - arrowSize.width) / 2,
        y: (pxHeight - arrowSize.height) / 2 + 24 * scale,
        width: arrowSize.width,
        height: arrowSize.height
    )
    arrow.draw(in: arrowRect, from: .zero, operation: .sourceOver, fraction: 1.0)
}

func drawCenteredText(_ text: String, y: CGFloat, fontSize: CGFloat, weight: NSFont.Weight, color: NSColor, alpha: CGFloat = 1.0) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: fontSize, weight: weight),
        .foregroundColor: color.withAlphaComponent(alpha),
        .paragraphStyle: paragraph,
    ]
    let attrString = NSAttributedString(string: text, attributes: attrs)
    let textRect = NSRect(x: 0, y: y, width: pxWidth, height: fontSize * 1.4)
    attrString.draw(in: textRect)
}

let appName = "MacProtectionStatus"
let titleText = isKorean ? "\(appName) 설치하려면," : "To install \(appName),"
let subtitleText = isKorean ? "아이콘을 Applications 폴더로 드래그하세요" : "drag the icon into the Applications folder"

drawCenteredText(titleText, y: 70 * scale, fontSize: 15 * scale, weight: .semibold, color: .white, alpha: 0.95)
drawCenteredText(subtitleText, y: 46 * scale, fontSize: 12.5 * scale, weight: .regular, color: .white, alpha: 0.75)

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Failed to render PNG")
}

let outputPath = CommandLine.arguments[1]
try! png.write(to: URL(fileURLWithPath: outputPath))
print("Wrote \(outputPath) (\(Int(pxWidth))x\(Int(pxHeight)), \(isKorean ? "ko" : "en"))")
