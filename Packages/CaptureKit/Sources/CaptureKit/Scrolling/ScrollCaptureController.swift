// Packages/CaptureKit/Sources/CaptureKit/Scrolling/ScrollCaptureController.swift
import CoreGraphics
import Foundation
import Vision
@preconcurrency import ScreenCaptureKit

public struct ScrollCaptureConfig: Sendable {
    public let captureRect: CGRect
    public let displayID: CGDirectDisplayID
    public let mode: ScrollMode
    public let maxHeight: Int

    public init(
        captureRect: CGRect,
        displayID: CGDirectDisplayID,
        mode: ScrollMode = .manual,
        maxHeight: Int = 30_000
    ) {
        self.captureRect = captureRect
        self.displayID = displayID
        self.mode = mode
        self.maxHeight = maxHeight
    }
}

public enum ScrollMode: Sendable {
    case auto
    case manual
}

public struct ScrollCaptureProgress: Sendable {
    public let currentHeight: Int
    public let maxHeight: Int
    public let frameCount: Int
}

public final class ScrollCaptureController: @unchecked Sendable {
    private let config: ScrollCaptureConfig
    private let stitcher = ScrollStitcher()
    private var isCancelled = false
    private var frameCount = 0

    /// A/B frame model
    private var shotA: CGImage?

    /// Cached ScreenCaptureKit objects (created once, reused)
    private var cachedFilter: SCContentFilter?
    private var cachedStreamConfig: SCStreamConfiguration?

    public var currentMergedImage: CGImage? { stitcher.mergedImage }

    public init(config: ScrollCaptureConfig) {
        self.config = config
    }

    public func start(
        onProgress: @escaping @Sendable (ScrollCaptureProgress) -> Void,
        onComplete: @escaping @Sendable (CGImage?) -> Void
    ) {
        Task.detached(priority: .utility) { [self] in
            let result = await self.runCaptureLoop(onProgress: onProgress)
            onComplete(result)
        }
    }

    public func stop() {
        isCancelled = true
    }

    // MARK: - Capture Loop

    private func runCaptureLoop(
        onProgress: @escaping @Sendable (ScrollCaptureProgress) -> Void
    ) async -> CGImage? {
        // Capture initial frame
        guard let firstFrame = await captureFrame() else {
            return nil
        }
        stitcher.setInitialFrame(firstFrame)
        shotA = firstFrame
        frameCount = 1

        onProgress(ScrollCaptureProgress(
            currentHeight: stitcher.totalHeight,
            maxHeight: config.maxHeight,
            frameCount: frameCount
        ))

        var consecutiveNoChange = 0
        var consecutiveFailures = 0
        var firstOffsetSign: Int? = nil

        // Main capture loop — runs until user clicks Done or stop condition
        captureLoop: while !isCancelled {
            if stitcher.totalHeight >= config.maxHeight {
                break
            }

            // Poll interval
            try? await Task.sleep(for: .milliseconds(150))
            guard !isCancelled else { break }

            // Capture frame B
            guard let shotB = await captureFrame() else {
                consecutiveFailures += 1
                if consecutiveFailures >= 15 { break }
                continue
            }

            // Quick byte-level check: skip if identical (user not scrolling)
            guard let dataA = shotA?.dataProvider?.data,
                  let dataB = shotB.dataProvider?.data else {
                continue
            }
            let lenA = CFDataGetLength(dataA)
            let lenB = CFDataGetLength(dataB)
            if lenA == lenB, memcmp(CFDataGetBytePtr(dataA)!, CFDataGetBytePtr(dataB)!, lenA) == 0 {
                // Identical — user hasn't scrolled, keep waiting
                continue
            }

            // Frames are different — detect offset with Vision
            let offset = detectOffset(imageA: shotA!, imageB: shotB)

            if offset == nil {
                consecutiveFailures += 1
                if consecutiveFailures >= 15 { break captureLoop }
                // Still update shotA so next comparison is fresh
                shotA = shotB
                continue
            }

            let rawOffset = offset!
            let absOffset = abs(rawOffset)

            // Too small offset = noise, not a real scroll
            if absOffset < 3 {
                consecutiveNoChange += 1
                if consecutiveNoChange >= 10 { break captureLoop }
                continue
            }

            // Detect direction reversal (elastic bounce = end of content)
            let sign = rawOffset > 0 ? 1 : -1
            if let first = firstOffsetSign {
                if sign != first {
                    break captureLoop
                }
            } else {
                firstOffsetSign = sign
            }

            // Stitch the new frame
            let result = stitcher.stitch(newFrame: shotB, detectedOffset: absOffset)

            switch result {
            case .stitched(let rows):
                consecutiveNoChange = 0
                consecutiveFailures = 0
                frameCount += 1
                onProgress(ScrollCaptureProgress(
                    currentHeight: stitcher.totalHeight,
                    maxHeight: config.maxHeight,
                    frameCount: frameCount
                ))

            case .noChange:
                consecutiveNoChange += 1
                if consecutiveNoChange >= 10 { break captureLoop }

            case .reversedScroll:
                break captureLoop

            case .alignmentFailed:
                consecutiveFailures += 1
                if consecutiveFailures >= 15 { break captureLoop }
            }

            // A = B for next cycle
            shotA = shotB
        }

        return stitcher.mergedImage
    }

    // MARK: - Frame Capture

    private func captureFrame() async -> CGImage? {
        do {
            if cachedFilter == nil {
                let content = try await SCShareableContent.excludingDesktopWindows(
                    false, onScreenWindowsOnly: true
                )
                guard let display = content.displays.first(where: {
                    $0.displayID == config.displayID
                }) ?? content.displays.first else {
                    return nil
                }

                // Exclude all Capso windows (our overlay panels)
                let myBundleID = Bundle.main.bundleIdentifier ?? ""
                let myWindows = content.windows.filter {
                    $0.owningApplication?.bundleIdentifier == myBundleID
                }

                let filter = SCContentFilter(display: display, excludingWindows: myWindows)
                let streamConfig = SCStreamConfiguration()
                streamConfig.captureResolution = .best
                streamConfig.showsCursor = false
                streamConfig.sourceRect = config.captureRect
                let scale = CGFloat(filter.pointPixelScale)
                streamConfig.width = Int(config.captureRect.width * scale)
                streamConfig.height = Int(config.captureRect.height * scale)

                cachedFilter = filter
                cachedStreamConfig = streamConfig
            }

            guard let filter = cachedFilter, let cfg = cachedStreamConfig else {
                return nil
            }

            return try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: cfg
            )
        } catch {
            return nil
        }
    }

    // MARK: - Vision Offset Detection

    /// Detect Y offset between two frames using VNTranslationalImageRegistrationRequest.
    /// Each call creates a fresh VNImageRequestHandler (stateless, reliable).
    private func detectOffset(imageA: CGImage, imageB: CGImage) -> Int? {
        let request = VNTranslationalImageRegistrationRequest(targetedCGImage: imageA)
        let handler = VNImageRequestHandler(cgImage: imageB, options: [:])

        do {
            try handler.perform([request])
        } catch {
            return nil
        }

        guard let observation = request.results?.first
                as? VNImageTranslationAlignmentObservation else {
            return nil
        }

        let ty = observation.alignmentTransform.ty
        return Int(round(ty))
    }
}
