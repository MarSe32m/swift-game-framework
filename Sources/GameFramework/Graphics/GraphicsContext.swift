import GLFWSwift

internal final class GraphicsContext {
    internal var windowHandle: OpaquePointer
    
    public var vendor: String = "Undefined"
    public var renderer: String = "Undefined"
    public var graphicsVersion: String = "Undefined"

    public init(window: OpaquePointer) {
        self.windowHandle = window
        glfwMakeContextCurrent(windowHandle)
        let status = gladLoadGL()
        precondition(status != 0, "Failed to initialize GLAD")

        vendor = String(cString: glGetString(GLenum(GL_VENDOR))!)
        renderer = String(cString: glGetString(GLenum(GL_RENDERER))!)
        graphicsVersion = String(cString: glGetString(GLenum(GL_VERSION))!)

        print("OpenGL version: \(GLVersion.major).\(GLVersion.minor)")
        print(vendor)
        print(renderer)
        print(graphicsVersion)
    }

    @inline(__always)
    public final func swapBuffers() {
        glfwSwapBuffers(windowHandle)
    }
}