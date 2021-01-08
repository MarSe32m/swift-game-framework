import GLFWSwift
import GLMSwift

public protocol Input {
    func isKeyPressed(key: KeyCode) -> Bool
    func isMouseButtonPressed(button: MouseCode) -> Bool
    func mousePosition() -> Point
    func mouseX() -> Double
    func mouseY() -> Double
}

#if os(Windows)
internal final class WindowsInput: Input {
    public func isKeyPressed(key: KeyCode) -> Bool {
        let windowHandle = Application.shared._window.windowHandle
        let state = glfwGetKey(windowHandle, Int32(key.rawValue))
        return state == GLFW_PRESS || state == GLFW_REPEAT
    }
    public func isMouseButtonPressed(button: MouseCode) -> Bool {
        let windowHandle = Application.shared._window.windowHandle
        let state = glfwGetMouseButton(windowHandle, Int32(button.rawValue))
        return state == GLFW_PRESS
    }
    public func mousePosition() -> Point {
        let windowHandle = Application.shared._window.windowHandle
        var point = Point()
        glfwGetCursorPos(windowHandle, &point.x, &point.y)
        return point
    }
    public func mouseX() -> Double {
        mousePosition().x
    }
    public func mouseY() -> Double {
        mousePosition().y
    }
}
#else
#warning("Game framework not implemented on the current platform.")
#endif