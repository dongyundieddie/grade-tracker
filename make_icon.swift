import Cocoa
// usage: swift make_icon.swift out.png   — draws a 1024×1024 app icon
let size: CGFloat = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1024, pixelsHigh: 1024, bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let inset: CGFloat = 60
let rect = NSRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)
let path = NSBezierPath(roundedRect: rect, xRadius: 190, yRadius: 190)
NSGradient(colors: [NSColor(red: 0.20, green: 0.42, blue: 0.95, alpha: 1), NSColor(red: 0.42, green: 0.30, blue: 0.90, alpha: 1)])!
    .draw(in: path, angle: -60)
// bar chart glyph
NSColor.white.withAlphaComponent(0.95).setFill()
let bw: CGFloat = 120, gap: CGFloat = 46, baseY: CGFloat = 250
let heights: [CGFloat] = [210, 320, 440]
let total = CGFloat(heights.count) * bw + CGFloat(heights.count - 1) * gap
var x = (size - total) / 2
for h in heights { NSBezierPath(roundedRect: NSRect(x: x, y: baseY, width: bw, height: h), xRadius: 26, yRadius: 26).fill(); x += bw + gap }
// "A" mark above
let para = NSMutableParagraphStyle(); para.alignment = .center
let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 210, weight: .heavy), .foregroundColor: NSColor.white, .paragraphStyle: para]
("A+" as NSString).draw(in: NSRect(x: 0, y: 700, width: size, height: 250), withAttributes: attrs)
NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
