import AppKit
import AVFoundation
import Observation
@preconcurrency import ScreenCaptureKit

@Observable
@MainActor
public final class PermissionManager {
    public private(set) var screenRecordingGranted: Bool = false
    public private(set) var cameraGranted: Bool = false
    public private(set) var microphoneGranted: Bool = false

    public init() {}

    // MARK: - Screen Recording

    public func checkScreenRecordingPermission() async {
        do {
            _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
            screenRecordingGranted = true
        } catch {
            screenRecordingGranted = false
        }
    }

    // MARK: - Camera

    public func requestCameraPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            cameraGranted = true
        case .notDetermined:
            cameraGranted = await AVCaptureDevice.requestAccess(for: .video)
        default:
            cameraGranted = false
        }
    }

    // MARK: - Microphone

    public func requestMicrophonePermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized:
            microphoneGranted = true
        case .notDetermined:
            microphoneGranted = await AVCaptureDevice.requestAccess(for: .audio)
        default:
            microphoneGranted = false
        }
    }

    // MARK: - Open System Settings

    public func openScreenRecordingSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        NSWorkspace.shared.open(url)
    }

    public func openCameraSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera")!
        NSWorkspace.shared.open(url)
    }

    public func openMicrophoneSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!
        NSWorkspace.shared.open(url)
    }
}
