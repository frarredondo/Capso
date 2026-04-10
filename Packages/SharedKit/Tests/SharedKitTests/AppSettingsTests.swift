import Foundation
import Testing
@testable import SharedKit

@Suite("AppSettings")
struct AppSettingsTests {
    @Test("Default export location is Desktop")
    func defaultExportLocation() {
        let settings = AppSettings()
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        #expect(settings.exportLocation == desktopURL)
    }

    @Test("Default screenshot format is PNG")
    func defaultScreenshotFormat() {
        let settings = AppSettings()
        #expect(settings.screenshotFormat == .png)
    }

    @Test("Default Quick Access position is bottomLeft")
    func defaultQuickAccessPosition() {
        let settings = AppSettings()
        #expect(settings.quickAccessPosition == .bottomLeft)
    }

    @Test("Default shutter sound is enabled")
    func defaultShutterSound() {
        let settings = AppSettings()
        #expect(settings.playShutterSound == true)
    }

    @Test("Default auto-close interval is 5 seconds")
    func defaultAutoCloseInterval() {
        let settings = AppSettings()
        #expect(settings.quickAccessAutoCloseInterval == 5)
    }

    @Test("Pro features locked by default")
    func proFeaturesLockedByDefault() {
        let settings = AppSettings()
        #expect(settings.isProUnlocked == false)
    }
}
