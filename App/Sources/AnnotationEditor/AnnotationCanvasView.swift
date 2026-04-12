// App/Sources/AnnotationEditor/AnnotationCanvasView.swift
import SwiftUI
import AppKit
import AnnotationKit

struct AnnotationCanvasView: NSViewRepresentable {
    let document: AnnotationDocument
    let sourceImage: CGImage
    let currentTool: AnnotationTool
    let currentStyle: AnnotationKit.StrokeStyle
    let zoomScale: CGFloat
    let refreshTrigger: Int
    var onSwitchToSelect: (() -> Void)?

    func makeNSView(context: Context) -> AnnotationCanvasNSView {
        let view = AnnotationCanvasNSView()
        view.document = document
        view.sourceImage = sourceImage
        view.currentTool = currentTool
        view.currentStyle = currentStyle
        view.zoomScale = zoomScale
        view.onObjectCreated = {
            // Continuous-drawing tools stay active after each stroke;
            // one-shot tools (arrow, rect, ellipse, text, pixelate) switch
            // back to select after creation.
            let keepActive: Set<AnnotationTool> = [.counter, .freehand, .highlighter]
            if !keepActive.contains(currentTool) {
                onSwitchToSelect?()
            }
        }
        return view
    }

    func updateNSView(_ nsView: AnnotationCanvasNSView, context: Context) {
        let toolChanged = nsView.currentTool != currentTool
        nsView.currentTool = currentTool
        nsView.currentStyle = currentStyle
        nsView.zoomScale = zoomScale
        nsView.onObjectCreated = {
            let keepActive: Set<AnnotationTool> = [.counter, .freehand, .highlighter]
            if !keepActive.contains(currentTool) {
                onSwitchToSelect?()
            }
        }
        nsView.needsDisplay = true
        if toolChanged {
            nsView.window?.invalidateCursorRects(for: nsView)
        }
    }
}
