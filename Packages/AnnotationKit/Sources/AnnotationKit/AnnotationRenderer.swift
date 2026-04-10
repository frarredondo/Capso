import Foundation
import CoreGraphics
import CoreImage

public enum AnnotationRenderer {
    public static func render(
        sourceImage: CGImage,
        objects: [any AnnotationObject],
        cropRect: CGRect? = nil
    ) -> CGImage? {
        let width = sourceImage.width
        let height = sourceImage.height

        guard let ctx = CGContext(
            data: nil,
            width: width, height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else { return nil }

        // Draw source image (no flip needed — CGContext.draw() in a standard
        // bottom-left context already renders the image right-side-up)
        ctx.draw(sourceImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Draw annotations in flipped (top-left) coordinate space to match
        // the canvas's isFlipped=true NSView where objects were created
        ctx.saveGState()
        ctx.translateBy(x: 0, y: CGFloat(height))
        ctx.scaleBy(x: 1, y: -1)

        for object in objects {
            if let pixelate = object as? PixelateObject {
                pixelate.renderWithSource(in: ctx, sourceImage: sourceImage)
            } else {
                object.render(in: ctx)
            }
        }
        ctx.restoreGState()

        guard var outputImage = ctx.makeImage() else { return nil }

        if let crop = cropRect {
            if let cropped = outputImage.cropping(to: crop) {
                outputImage = cropped
            }
        }

        return outputImage
    }
}
