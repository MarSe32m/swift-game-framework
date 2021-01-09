/**
 * Copyright © 2021 Sebastian Toivonen
 * All Rights Reserved.
 *
 * Licensed under Apache License v2.0
 */

import GLMSwift

public struct KeyEvent {
    public let keyCode: KeyCode?
    public let keyID: Int
    public let repeated: Bool
}

public struct MouseButtonEvent {
    public let mouseButtonCode: MouseCode?
    public let buttonID: Int
    public let position: Point
}

internal struct _KeyEvent {
    public let keyCode: Int32
    public let repeated: Bool
}

internal struct _MouseButtonEvent {
    public let mouseButton: Int32
    public let position: Point
}

internal enum Event {
    case none

    //MARK: Window events
    case windowClose
    case windowResize(Size)
    case windowFocus
    case windowLostFocus
    case windowMoved(Point)

    //MARK: Keyboard events
    case keyPressed(_KeyEvent)
    case keyReleased(_KeyEvent)
    case keyTyped(_KeyEvent)

    //MARK: Mouse button events
    case mouseButtonPressed(_MouseButtonEvent)
    case mouseButtonReleased(_MouseButtonEvent)
    case mouseMoved(Point)
    case mouseScrolled(Point)

    ////MARK: Touch events, TODO: When making available on iOS and macOS
    //case touchesBegan([UITouch], UIEvent)
    //case touchesMoved([UITouch], UIEvent)
    //case touchesEnded([UITouch], UIEvent)
    //case touchesCancelles([UITouch], UIEvent)
}