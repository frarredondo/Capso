// Packages/EffectsKit/Sources/EffectsKit/ClickMonitor.swift
@preconcurrency import Foundation
import CoreGraphics

public final class ClickMonitor: @unchecked Sendable {
    public var onClick: (@Sendable (CGPoint) -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var runLoop: CFRunLoop?
    private var thread: Thread?

    public init() {}

    public func start() {
        guard eventTap == nil else { return }

        let mask: CGEventMask = (1 << CGEventType.leftMouseDown.rawValue)
            | (1 << CGEventType.rightMouseDown.rawValue)

        // Store self as unmanaged pointer for the C callback
        let userInfo = Unmanaged.passRetained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: { _, _, event, userInfo -> Unmanaged<CGEvent>? in
                guard let userInfo else { return Unmanaged.passUnretained(event) }
                let monitor = Unmanaged<ClickMonitor>.fromOpaque(userInfo).takeUnretainedValue()
                let location = event.location
                monitor.onClick?(location)
                return Unmanaged.passUnretained(event)
            },
            userInfo: userInfo
        ) else {
            Unmanaged<ClickMonitor>.fromOpaque(userInfo).release()
            return
        }

        self.eventTap = tap

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source

        let bgThread = Thread { [weak self] in
            guard let source, let self else { return }
            let rl = CFRunLoopGetCurrent()
            self.runLoop = rl
            CFRunLoopAddSource(rl, source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            CFRunLoopRun()
        }
        bgThread.name = "com.capso.clickmonitor"
        bgThread.start()
        self.thread = bgThread
    }

    public func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let rl = runLoop {
            CFRunLoopStop(rl)
        }
        if eventTap != nil {
            let userInfo = Unmanaged.passUnretained(self).toOpaque()
            Unmanaged<ClickMonitor>.fromOpaque(userInfo).release()
        }
        eventTap = nil
        runLoopSource = nil
        runLoop = nil
        thread = nil
    }

    deinit {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let rl = runLoop {
            CFRunLoopStop(rl)
        }
    }
}
