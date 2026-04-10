// App/Sources/Capture/CaptureOverlayWindow.swift
import AppKit
import CaptureKit

@MainActor
final class CaptureOverlayWindow: NSPanel {
    var onAreaSelected: ((CGRect, NSScreen) -> Void)?
    var onWindowSelected: ((CGWindowID) -> Void)?
    var onCancelled: (() -> Void)?

    private var overlayView: CaptureOverlayView!

    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .screenSaver
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isMovable = false
        self.acceptsMouseMovedEvents = true

        overlayView = CaptureOverlayView(frame: screen.frame)
        overlayView.onSelectionComplete = { [weak self] rect in
            guard let self, let screen = self.screen else { return }
            self.onAreaSelected?(rect, screen)
        }
        overlayView.onWindowSelected = { [weak self] windowID in
            self?.onWindowSelected?(windowID)
        }
        overlayView.onCancel = { [weak self] in
            self?.onCancelled?()
        }

        self.contentView = overlayView
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    func activate(mode: CaptureOverlayMode = .area) {
        NSApp.activate(ignoringOtherApps: true)
        makeKeyAndOrderFront(nil)
        makeFirstResponder(overlayView)
        overlayView.setMode(mode)
        overlayView.resetSelection()
    }

    func deactivate() {
        // Ensure cursor is restored even if the overlay view didn't do it
        overlayView.restoreCursorIfNeeded()
        orderOut(nil)
    }
}
