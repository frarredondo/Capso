import Foundation
import CoreGraphics
import CoreImage

public final class PixelateObject: AnnotationObject, @unchecked Sendable {
    public let id = ObjectID()
    public var style: StrokeStyle
    public var rect: CGRect
    public var blockSize: CGFloat = 12

    public init(rect: CGRect, blockSize: CGFloat = 12) {
        self.rect = rect
        self.style = StrokeStyle()
        self.blockSize = blockSize
    }

    public var bounds: CGRect { rect }

    public func hitTest(point: CGPoint, threshold: CGFloat) -> Bool {
        rect.insetBy(dx: -threshold, dy: -threshold).contains(point)
    }

    public func render(in ctx: CGContext) {
        ctx.saveGState()
        ctx.setFillColor(CGColor(gray: 0.5, alpha: 0.3))
        ctx.fill(rect)
        ctx.setStrokeColor(CGColor(gray: 0.5, alpha: 0.2))
        ctx.setLineWidth(0.5)
        var x = rect.minX
        while x <= rect.maxX {
            ctx.move(to: CGPoint(x: x, y: rect.minY))
            ctx.addLine(to: CGPoint(x: x, y: rect.maxY))
            x += blockSize
        }
        var y = rect.minY
        while y <= rect.maxY {
            ctx.move(to: CGPoint(x: rect.minX, y: y))
            ctx.addLine(to: CGPoint(x: rect.maxX, y: y))
            y += blockSize
        }
        ctx.strokePath()
        ctx.restoreGState()
    }

    /// Apply actual pixelation using CIFilter on the source image region.
    /// `rect` is in image coordinates (top-left origin, matching source image pixel dimensions).
    /// The CGContext is assumed to be in a flipped coordinate system (isFlipped NSView).
    public func renderWithSource(in ctx: CGContext, sourceImage: CGImage) {
        guard rect.width > 0, rect.height > 0 else { return }

        let imgH = CGFloat(sourceImage.height)

        // CGImage.cropping uses bottom-left origin — flip Y
        let cropRect = CGRect(
            x: rect.origin.x,
            y: imgH - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        ).intersection(CGRect(x: 0, y: 0, width: CGFloat(sourceImage.width), height: imgH))

        guard !cropRect.isEmpty, let cropped = sourceImage.cropping(to: cropRect) else { return }

        // Apply pixelate filter
        let ciImage = CIImage(cgImage: cropped)
        let filter = CIFilter(name: "CIPixellate")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(blockSize, forKey: kCIInputScaleKey)

        let ciCtx = CIContext()
        guard let output = filter.outputImage,
              let pixelated = ciCtx.createCGImage(output, from: ciImage.extent) else { return }

        // Draw pixelated result — flip for CGContext.draw in flipped coordinate system
        ctx.saveGState()
        ctx.translateBy(x: rect.origin.x, y: rect.origin.y + rect.height)
        ctx.scaleBy(x: 1, y: -1)
        ctx.draw(pixelated, in: CGRect(origin: .zero, size: rect.size))
        ctx.restoreGState()
    }

    public func move(by delta: CGSize) {
        rect.origin.x += delta.width
        rect.origin.y += delta.height
    }

    public func copy() -> any AnnotationObject {
        PixelateObject(rect: rect, blockSize: blockSize)
    }
}
