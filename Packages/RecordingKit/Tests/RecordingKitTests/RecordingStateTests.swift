// Packages/RecordingKit/Tests/RecordingKitTests/RecordingStateTests.swift
import Testing
import Foundation
@testable import RecordingKit

@Suite("RecordingState")
struct RecordingStateTests {
    @Test("RecordingState has expected cases")
    func states() {
        let states: [RecordingState] = [.idle, .preparing, .recording, .paused, .stopping]
        #expect(states.count == 5)
    }

    @Test("RecordingState isActive")
    func isActive() {
        #expect(RecordingState.recording.isActive == true)
        #expect(RecordingState.paused.isActive == true)
        #expect(RecordingState.idle.isActive == false)
        #expect(RecordingState.preparing.isActive == false)
        #expect(RecordingState.stopping.isActive == false)
    }

    @Test("RecordingFormat has two cases")
    func formats() {
        let formats: [RecordingFormat] = [.video, .gif]
        #expect(formats.count == 2)
    }

    @Test("RecordingConfig defaults")
    func configDefaults() {
        let config = RecordingConfig(
            captureRect: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            displayID: 1
        )
        #expect(config.format == .video)
        #expect(config.fps == 30)
        #expect(config.captureSystemAudio == true)
        #expect(config.captureMicrophone == false)
        #expect(config.showCursor == true)
    }
}
