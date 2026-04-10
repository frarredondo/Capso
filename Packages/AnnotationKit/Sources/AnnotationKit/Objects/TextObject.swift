import Foundation
import CoreGraphics
import AppKit

public final class TextObject: AnnotationObject, @unchecked Sendable {
    public let id = ObjectID()
    public var style: StrokeStyle
    public var text: String
    public var origin: CGPoint
    public var fontSize: CGFloat
    public var fontName: String

    public init(text: String, origin: CGPoint, fontSize: CGFloat = 48, fontName: String = ".AppleSystemUIFont", style: StrokeStyle = StrokeStyle()) {
        self.text = text
        self.origin = origin
        self.fontSize = fontSize
        self.fontName = fontName
        self.style = style
    }

    private var attributes: [NSAttributedString.Key: Any] {
        let font = NSFont(name: fontName, size: fontSize) ?? NSFont.systemFont(ofSize: fontSize, weight: .medium)
        return [
            .font: font,
            .foregroundColor: style.color.nsColor.withAlphaComponent(style.opacity),
        ]
    }

    public var bounds: CGRect {
        let size = (text as NSString).size(withAttributes: attributes)
        return CGRect(origin: origin, size: size)
    }

    public func hitTest(point: CGPoint, threshold: CGFloat) -> Bool {
        bounds.insetBy(dx: -threshold, dy: -threshold).contains(point)
    }

    public func render(in ctx: CGContext) {
        let nsCtx = NSGraphicsContext(cgContext: ctx, flipped: true)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsCtx
        (text as NSString).draw(at: origin, withAttributes: attributes)
        NSGraphicsContext.restoreGraphicsState()
    }

    public func move(by delta: CGSize) {
        origin.x += delta.width
        origin.y += delta.height
    }

    public func copy() -> any AnnotationObject {
        TextObject(text: text, origin: origin, fontSize: fontSize, fontName: fontName, style: style)
    }
}
