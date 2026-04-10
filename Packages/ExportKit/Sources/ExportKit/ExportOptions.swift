// Packages/ExportKit/Sources/ExportKit/ExportOptions.swift
import Foundation
import SharedKit

public enum ExportFormat: String, Sendable {
    case mp4
    case gif
}

public struct ExportOptions: Sendable {
    public let format: ExportFormat
    public let quality: ExportQuality
    public let destination: URL

    public init(format: ExportFormat, quality: ExportQuality, destination: URL) {
        self.format = format
        self.quality = quality
        self.destination = destination
    }
}

public enum ExportError: Error, Sendable {
    case sourceFileNotFound
    case exportSessionFailed(String)
    case frameExtractionFailed
    case gifCreationFailed
    case cancelled
}
