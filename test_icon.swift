import AppKit

func generateIcon(progress: Double) -> NSImage {
    let size = NSSize(width: 18, height: 18)
    let image = NSImage(size: size, flipped: false) { rect in
        let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)
        guard let outline = NSImage(systemSymbolName: "mug", accessibilityDescription: nil)?.withSymbolConfiguration(config),
              let fill = NSImage(systemSymbolName: "mug.fill", accessibilityDescription: nil)?.withSymbolConfiguration(config) else {
            return false
        }

        let drawRect = NSRect(x: (18 - outline.size.width) / 2,
                              y: (18 - outline.size.height) / 2,
                              width: outline.size.width,
                              height: outline.size.height)

        let tintedOutline = outline.copy() as! NSImage
        tintedOutline.lockFocus()
        NSColor.labelColor.set()
        NSRect(origin: .zero, size: tintedOutline.size).fill(using: .sourceAtop)
        tintedOutline.unlockFocus()
        
        tintedOutline.draw(in: drawRect)

        if progress <= 0 {
            let redLine = NSBezierPath()
            redLine.move(to: NSPoint(x: drawRect.minX + 3, y: drawRect.minY + 2))
            redLine.line(to: NSPoint(x: drawRect.maxX - 3, y: drawRect.minY + 2))
            NSColor.systemRed.setStroke()
            redLine.lineWidth = 1.5
            redLine.lineCapStyle = .round
            redLine.stroke()
        } else {
            NSGraphicsContext.current?.saveGraphicsState()
            
            let fillHeight = drawRect.height * progress
            let clipRect = NSRect(x: 0, y: 0, width: 18, height: drawRect.minY + fillHeight)
            NSBezierPath(rect: clipRect).addClip()
            
            let tintedFill = fill.copy() as! NSImage
            tintedFill.lockFocus()
            NSColor.systemBlue.set()
            NSRect(origin: .zero, size: tintedFill.size).fill(using: .sourceAtop)
            tintedFill.unlockFocus()
            
            tintedFill.draw(in: drawRect)
            
            NSGraphicsContext.current?.restoreGraphicsState()
        }
        return true
    }
    image.isTemplate = false
    return image
}

let img1 = generateIcon(progress: 0.0)
let img2 = generateIcon(progress: 0.5)
print("Success")
