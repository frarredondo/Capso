import Foundation
import CoreGraphics
@preconcurrency import ScreenCaptureKit

public struct WindowInfo: Identifiable, Sendable {
    public let id: CGWindowID
    public let title: String
    public let appName: String
    public let frame: CGRect
    public let isOnScreen: Bool
    public let windowLayer: Int

    public init(from scWindow: SCWindow) {
        self.id = scWindow.windowID
        self.title = scWindow.title ?? ""
        self.appName = scWindow.owningApplication?.applicationName ?? ""
        self.frame = scWindow.frame
        self.isOnScreen = scWindow.isOnScreen
        self.windowLayer = scWindow.windowLayer
    }
}

public struct DisplayInfo: Identifiable, Sendable {
    public let id: CGDirectDisplayID
    public let width: Int
    public let height: Int
    public let frame: CGRect

    public init(from scDisplay: SCDisplay) {
        self.id = scDisplay.displayID
        self.width = scDisplay.width
        self.height = scDisplay.height
        self.frame = scDisplay.frame
    }
}

public enum ContentEnumerator {
    public static func windows() async throws -> [WindowInfo] {
        let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)
        return content.windows
            .filter { window in
                // Only include normal application windows (layer 0).
                // Status bar items, floating panels, overlays, etc. have layer > 0.
                window.windowLayer == 0
                && window.frame.width > 100 && window.frame.height > 50
                && window.isOnScreen
                && window.owningApplication != nil
                && window.title != nil
                && !window.title!.isEmpty
            }
            .map { WindowInfo(from: $0) }
    }

    public static func displays() async throws -> [DisplayInfo] {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
        return content.displays.map { DisplayInfo(from: $0) }
    }

    public static func scWindow(for windowID: CGWindowID) async throws -> SCWindow? {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
        return content.windows.first { $0.windowID == windowID }
    }

    public static func scDisplay(for displayID: CGDirectDisplayID) async throws -> SCDisplay? {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
        return content.displays.first { $0.displayID == displayID }
    }

    public static func mainDisplay() async throws -> SCDisplay? {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
        return content.displays.first { $0.displayID == CGMainDisplayID() }
    }
}
