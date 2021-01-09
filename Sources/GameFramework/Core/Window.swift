/**
 * Copyright © 2021 Sebastian Toivonen
 * All Rights Reserved.
 *
 * Licensed under Apache License v2.0
 */

import GLFWSwift
import GLMSwift

internal struct WindowProperties {
    internal let title: String
    internal var width: Int
    internal var height: Int
    internal var isFullScreen: Bool

    internal init(title: String = "Sebbu Game Framework", width: Int = 1280, height: Int = 720, isFullScreen: Bool = false) {
        self.title = title
        self.width = width
        self.height = height
        self.isFullScreen = isFullScreen
    }

    internal var eventCallback: ((Event) -> Void)!
}

public protocol Window: AnyObject {
    var title: String { get set }
    var width: Int { get set }
    var height: Int { get set }
    var vsync: Bool { get set }

    func close()
    func focus()
    func maximize()
    func restore()
    func set(width: Int, height: Int)
}

internal protocol WindowInternals {
    var windowHandle: OpaquePointer { get }
    init(properties: inout WindowProperties)
    func didResize(to: Size)
    func update()
    func shutdown()
}
#if os(Windows)
import WinSDK

internal final class WindowsWindow: Window, WindowInternals {
    internal let windowHandle: OpaquePointer
    internal var title: String {
        didSet { glfwSetWindowTitle(windowHandle, title) }
    }

    private var _width: Int32
    private var _height: Int32

    internal var width: Int {
        get { Int(_width) }

        set (newValue) {
            _width = Int32(newValue)
            glfwSetWindowSize(windowHandle, _width, _height)
        }    
    }

    internal var height: Int {
        get { Int(_height) }

        set (newValue) {
            _height = Int32(newValue)
            glfwSetWindowSize(windowHandle, _width, _height)
        }    
    }

    internal var context: GraphicsContext

    internal var vsync: Bool = false {
        didSet (newValue) {
            if newValue {
                glfwSwapInterval(1)
            } else {
                glfwSwapInterval(0)
            }
        }
    }

    private var isShutdown = false
    private static var windowCount = 0

    internal init(properties: inout WindowProperties) {
        title = properties.title
        _width = Int32(properties.width)
        _height = Int32(properties.height)

        if WindowsWindow.windowCount == 0 {
            if glfwInit() == 0 {
                fatalError("Failed to initialize GLFW!")
            } 

            glfwSetErrorCallback { (error, description) in
                print(error, String(cString: description!))
            }
        }

        guard SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_HIGHEST) else {
            fatalError("Couldn't set current thread priority to the highest?")
        }

        glfwWindowHint(GLFW_SAMPLES, 4)
        guard let window = glfwCreateWindow(Int32(properties.width), Int32(properties.height), title, properties.isFullScreen ? glfwGetPrimaryMonitor() : nil, nil) else {
            fatalError("Failed to create window!")
        }
        WindowsWindow.windowCount += 1
        windowHandle = window

        context = GraphicsContext(window: windowHandle)
        glfwSetWindowUserPointer(windowHandle, &properties)
        glfwSwapInterval(0)
        guard properties.eventCallback != nil else {
            fatalError("Properties event callback is nil")
        }

        //MARK: GLFW callbacks
        glfwSetWindowSizeCallback(window) { window, width, height in 
            guard let properties = glfwGetWindowUserPointer(window)?.load(as: WindowProperties.self) else {
                print("Failed to cast properties from windowUserPointer...", #file, #line)
                return
            } 
            properties.eventCallback(.windowResize(Size(width: Double(width), height: Double(height))))
        }

        glfwSetWindowCloseCallback(window) { window in
            guard let properties = glfwGetWindowUserPointer(window)?.load(as: WindowProperties.self) else {
                print("Failed to cast properties from windowUserPointer...", #file, #line)
                return
            } 
            properties.eventCallback(.windowClose)
        }

        glfwSetWindowPosCallback(window) { window, x, y in 
            guard let properties = glfwGetWindowUserPointer(window)?.load(as: WindowProperties.self) else {
                print("Failed to cast properties from windowUserPointer...", #file, #line)
                return
            }
            properties.eventCallback(.windowMoved(Point(Float(x), Float(y))))
        }

        glfwSetWindowFocusCallback(window) { window, focused in 
            guard let properties = glfwGetWindowUserPointer(window)?.load(as: WindowProperties.self) else {
                print("Failed to cast properties from windowUserPointer...", #file, #line)
                return
            }
            properties.eventCallback(focused == 1 ? .windowFocus : .windowLostFocus)
        }

        glfwSetKeyCallback(window) { window, key, scanecode, action, mods in 
            guard let properties = glfwGetWindowUserPointer(window)?.load(as: WindowProperties.self) else {
                print("Failed to cast properties from windowUserPointer...", #file, #line)
                return
            }
            switch action {
                case GLFW_PRESS:
                    properties.eventCallback(.keyPressed(_KeyEvent(keyCode: key, repeated: false)))
                case GLFW_RELEASE:
                    properties.eventCallback(.keyReleased(_KeyEvent(keyCode: key, repeated: false)))
                case GLFW_REPEAT:
                    properties.eventCallback(.keyPressed(_KeyEvent(keyCode: key, repeated: true)))    
                default:
                    break
            }
        }
        
        glfwSetCharCallback(window) { window, key in 
            guard let properties = glfwGetWindowUserPointer(window)?.load(as: WindowProperties.self) else {
                print("Failed to cast properties from windowUserPointer...", #file, #line)
                return
            }
            properties.eventCallback(.keyTyped(_KeyEvent(keyCode: Int32(key), repeated: false)))
        }


        glfwSetMouseButtonCallback(window) { window, button, action, mods in
            guard let properties = glfwGetWindowUserPointer(window)?.load(as: WindowProperties.self) else {
                print("Failed to cast properties from windowUserPointer...", #file, #line)
                return
            }
            let position = Application.shared.input.mousePosition()
            switch action {
                case GLFW_PRESS:
                    properties.eventCallback(.mouseButtonPressed(_MouseButtonEvent(mouseButton: button, position: position)))
                case GLFW_RELEASE:
                    properties.eventCallback(.mouseButtonReleased(_MouseButtonEvent(mouseButton: button, position: position)))    
                default:
                    break
            }
        }

        glfwSetScrollCallback(window) { window, xOffset, yOffset in 
            guard let properties = glfwGetWindowUserPointer(window)?.load(as: WindowProperties.self) else {
                print("Failed to cast properties from windowUserPointer...", #file, #line)
                return
            }
            properties.eventCallback(.mouseScrolled(Point(xOffset, yOffset)))
        }

        glfwSetCursorPosCallback(window) { window, x, y in 
            guard let properties = glfwGetWindowUserPointer(window)?.load(as: WindowProperties.self) else {
                print("Failed to cast properties from windowUserPointer...", #file, #line)
                return
            }
            properties.eventCallback(.mouseMoved(Point(x, y)))
        }
    }

    internal final func didResize(to newSize: Size) {
        width = Int(newSize.width)
        height = Int(newSize.height)
        glViewport(0, 0, Int32(width), Int32(height))
    }

    internal final func update() {
        glfwPollEvents()
        context.swapBuffers()
    }

    public final func close() {
        glfwSetWindowShouldClose(windowHandle, GLFW_TRUE)
        Application.shared.close()
    }

    public final func focus() {
        glfwFocusWindow(windowHandle)
    }

    public final func maximize() {
        glfwMaximizeWindow(windowHandle)
    }

    public final func restore() {
        glfwRestoreWindow(windowHandle)
    }

    public final func set(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    internal final func shutdown() {
        isShutdown = true
        glfwDestroyWindow(windowHandle)
        WindowsWindow.windowCount -= 1
        if WindowsWindow.windowCount == 0 {
            glfwTerminate()
        }
    }

    deinit {
        if !isShutdown {
            shutdown()
        }
    }
}
#else
#error("Window not implemented on this platform")
#endif