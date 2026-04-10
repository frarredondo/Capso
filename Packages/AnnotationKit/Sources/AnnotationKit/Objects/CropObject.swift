// Packages/AnnotationKit/Sources/AnnotationKit/Objects/CropObject.swift
import Foundation
import CoreGraphics

/// CropObject is not drawn as an annotation — it defines the crop region.
/// The AnnotationRenderer uses it to crop the final output.
public final class CropObject: @unchecked Sendable {
    public var rect: CGRect

    public init(rect: CGRect) {
        self.rect = rect
    }
}
