/**
 * Copyright © 2021 Sebastian Toivonen
 * All Rights Reserved.
 *
 * Licensed under Apache License v2.0
 */

import Dispatch

public final class RepeatingTimer {
    private let timeInterval: DispatchTimeInterval
    private let queue: DispatchQueue?

    public var eventHandler: (() -> Void)?

    private lazy var timer: DispatchSourceTimer = {
        let t = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
        t.schedule(deadline: .now() + self.timeInterval, repeating: self.timeInterval)
        t.setEventHandler(handler: { [weak self] in
            self?.eventHandler?()
        })
        return t
    }()

    private enum State {
        case suspended
        case resumed
    }

    private var state: State = .suspended

    public init(delta: Double, queue: DispatchQueue? = nil) {
        self.timeInterval = DispatchTimeInterval.nanoseconds(Int(delta * 1_000_000_000.0))
        self.queue = queue
    }

    public init(timeInterval: DispatchTimeInterval, queue: DispatchQueue? = nil) {
        self.timeInterval = timeInterval
        self.queue = queue
    }

    deinit {
        timer.setEventHandler {}
        timer.cancel()
        resume()
        eventHandler = nil
    }

    public func resume() {
        if state == .resumed {
            return
        }
        state = .resumed
        timer.resume()
    }

    public func suspend() {
        if state == .suspended {
            return
        }
        state = .suspended
        timer.suspend()
    }
}