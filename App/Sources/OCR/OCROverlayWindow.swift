// App/Sources/OCR/OCROverlayWindow.swift
import AppKit
import SwiftUI
import OCRKit

@MainActor
final class OCROverlayWindow: NSPanel {
    var onClose: (() -> Void)?

    init(image: CGImage, regions: [TextRegion]) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 550),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        self.level = .floating
        self.title = "OCR — Text Recognition"
        self.isMovableByWindowBackground = false
        self.minSize = NSSize(width: 600, height: 400)
        self.center()

        let view = OCROverlayView(
            image: image,
            regions: regions,
            onClose: { [weak self] in
                self?.close()
            }
        )

        self.contentView = NSHostingView(rootView: view)
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        makeKeyAndOrderFront(nil)
    }

    override func close() {
        onClose?()
        super.close()
    }
}
