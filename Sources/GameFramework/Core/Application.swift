import GLFWSwift
import Foundation
import Dispatch
import GLMSwift

public final class Application {
    public private(set) static var shared: Application!
    public let name: String

    public var window: Window!
    public private(set) var fps: Int = 60

    internal var _window: WindowInternals!
    
    private var renderer: Renderer!
    private var running = true
    private var minimized = false

    private var windowProperties: WindowProperties

    public var debug = false

    private var _updates = 0
    private var _FPS = 0

    /// The amount of ´fixed updates´ executed during the last second
    /// This value should be the same as the fps specified eg. 60 my default
    public private(set) var fixedUpdates = 0

    /// The amount of frames rendered (and updates executed) during the last second
    /// Rendering is capped at 1000 fps
    public private(set) var framesRendered = 0

    public var elapsedTime: Double = 0.0

    private var framesPerSecond = 1.0 / 60.0

    public let input: Input

    public var scene: Scene?

    public init(name: String = "Sebbu Game Framework", width: Int = 1280, height: Int = 720, fullScreen: Bool = false) {
        precondition(Application.shared == nil, "Application already exists!")
        print("Ola senor!")
        self.name = name
        self.windowProperties = WindowProperties(title: name, width: width, height: height, isFullScreen: fullScreen)
        #if os(Windows)
        self.input = WindowsInput()
        #else
        #error("Platform not supported yet")
        #endif

        self.windowProperties.eventCallback = eventCallback
        Application.shared = self

        #if os(Windows)
        let windowsWindow = WindowsWindow(properties: &windowProperties)
        self.window = windowsWindow
        self._window = windowsWindow
        #else
        #error("Platform not yet supported")
        #endif
        renderer = Renderer2D()

        self.scene = Scene(size: Size(width: width, height: height))
    }

    public final func run() {
        let repeatingTimer = RepeatingTimer(timeInterval: .nanoseconds(1_000_000), queue: .main)
        //var currentTime = glfwGetTime()
        var currentTime = DispatchTime.now().uptimeNanoseconds
        var lastTime = currentTime
        var accumulatedTime = 0.0
        var timeSinceLastFPS = 0.0

        repeatingTimer.eventHandler = { [self] in
            currentTime = DispatchTime.now().uptimeNanoseconds
            let delta = Double(currentTime - lastTime) / 1_000_000_000.0
            lastTime = currentTime
            elapsedTime += delta
            accumulatedTime += delta
            
            scene?.update(deltaTime: delta)
            
            if accumulatedTime >= framesPerSecond {
                accumulatedTime -= framesPerSecond
                _updates += 1
                scene?.fixedUpdate(deltaTime: framesPerSecond)
            }
            
            if !minimized {
                //TODO: Rendering should happen on a separate thread if possible.
                // On mobile devices this might be unnecessary but we will see
                if let scene = scene {
                    renderer.render(scene: scene)
                    renderer.commit()
                }
                _FPS += 1
            }
            renderer.resetGraphicsStats()
            _window.update()

            timeSinceLastFPS += delta
            if timeSinceLastFPS >= 1 {
                timeSinceLastFPS -= 1
                fixedUpdates = _updates
                framesRendered = _FPS
                
                _updates = 0
                _FPS = 0

                if debug {
                    let fpsString = "UPS: \(fixedUpdates), FPS: \(framesRendered), drawCalls: \(renderer.getDrawCalls()), quadCount: \(renderer.getQuadCount())"
                    window.title = fpsString
                }
            }
        }
        repeatingTimer.resume()
        
        while running {
            RunLoop.main.run(until: Date().addingTimeInterval(1.0))
        }
        repeatingTimer.suspend()
        _window.shutdown()
    }

    public final func present(_ scene: Scene?) {
        DispatchQueue.main.async { [self] in
            guard let newScene = scene else { return }
            self.scene?.willMove(self.window)
            self.scene?.window = nil
            self.scene = newScene
            newScene._didMove(self.window)
        }
    }

    public final func close() {
        DispatchQueue.main.async {
            self.scene?.willMove(self.window)
            self.scene?.windowClosed(self.window)
            self.running = false
        }
    }

    public final func setFramesPerSecond(_ fps: Int) {
        self.fps = fps
        framesPerSecond = 1.0 / Double(fps)
    }

    private func eventCallback(_ event: Event) {
        
        //TODO: Touch events
        switch event {
            case .none: preconditionFailure("We got a none event? This is kinda weird! Please contact the author of this engine...")
            case .windowClose: close()
            case .windowResize(let newSize):
                minimized = newSize.width == 0 && newSize.height == 0
                renderer.didResize(width: Int(newSize.width), height: Int(newSize.height))
                _window.didResize(to: newSize)
                scene?.windowResized(window, size: newSize)
            case .windowFocus:
                scene?.windowFocused(window)
            case .windowLostFocus:
                scene?.windowLostFocus(window)
            case .windowMoved(let position):
                scene?.windowMoved(window, position: position)
            case .keyPressed(let keyEvent):
                if keyEvent.repeated { return }
                let _keyEvent = KeyEvent(keyCode: KeyCode(rawValue: UInt16(keyEvent.keyCode)), keyID: Int(keyEvent.keyCode), repeated: keyEvent.repeated)
                scene?.keyDown(_keyEvent)
            case .keyReleased(let keyEvent):
                let _keyEvent = KeyEvent(keyCode: KeyCode(rawValue: UInt16(keyEvent.keyCode)), keyID: Int(keyEvent.keyCode), repeated: keyEvent.repeated)
                scene?.keyUp(_keyEvent)
            case .keyTyped(let keyEvent):
                let _keyEvent = KeyEvent(keyCode: KeyCode(rawValue: UInt16(keyEvent.keyCode)), keyID: Int(keyEvent.keyCode), repeated: keyEvent.repeated)
                scene?.keyTyped(_keyEvent)
            case .mouseButtonPressed(let mouseButtonEvent):
                let _mouseEvent = MouseButtonEvent(mouseButtonCode: MouseCode(rawValue: UInt16(mouseButtonEvent.mouseButton)), buttonID: Int(mouseButtonEvent.mouseButton), position: mouseButtonEvent.position)
                scene?.mouseDown(_mouseEvent)
            case .mouseButtonReleased(let mouseButtonEvent):
                let _mouseEvent = MouseButtonEvent(mouseButtonCode: MouseCode(rawValue: UInt16(mouseButtonEvent.mouseButton)), buttonID: Int(mouseButtonEvent.mouseButton), position: mouseButtonEvent.position)
                scene?.mouseUp(_mouseEvent)
            case .mouseMoved(let position):
                mouseMoved(position: position)
            case .mouseScrolled(let scroll):
                scene?.mouseScrolled(scroll)
        }
    }

    private func mouseMoved(position: Point) {
        if input.isMouseButtonPressed(button: .buttonLeft) {
            scene?.mouseDragged(position)
        } else {
            scene?.mouseMoved(position)
        }
    }
}