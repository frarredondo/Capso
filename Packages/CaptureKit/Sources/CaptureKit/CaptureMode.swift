// Packages/CaptureKit/Sources/CaptureKit/CaptureMode.swift
import Foundation
import CoreGraphics

public enum CaptureMode: String, Sendable {
    case area
    case fullscreen
    case window
}

public struct CaptureResult: Sendable {
    public let image: CGImage
    public let mode: CaptureMode
    public let captureRect: CGRect
    public let windowName: String?
    public let appName: String?
    public let timestamp: Date

    public init(
        image: CGImage,
        mode: CaptureMode,
        captureRect: CGRect,
        windowName: String? = nil,
        appName: String? = nil,
        timestamp: Date = Date()
    ) {
        self.image = image
        self.mode = mode
        self.captureRect = captureRect
        self.windowName = windowName
        self.appName = appName
        self.timestamp = timestamp
    }
}
