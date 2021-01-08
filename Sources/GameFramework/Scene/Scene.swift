open class Scene: Renderable {
    public var size: Size {
        didSet {
            camera?.setOrthoProjection(width: Float(size.width), height: Float(size.height))
            _defaultCamera.setOrthoProjection(width: Float(size.width), height: Float(size.height))
        }
    }

    open var shouldCullNonVisibleNodes: Bool = true
    open var backgroundColor: Color = .gray
    public internal(set) var window: Window?

    open var camera: Camera?
    internal var _defaultCamera: OrthographicCamera = OrthographicCamera(width: 0, height: 0)

    public init(size: Size) {
        self.size = size
        _defaultCamera.setOrthoProjection(width: Float(size.width), height: Float(size.height))
    }

    internal func _didMove(_ view: Window) {
        _defaultCamera.setOrthoProjection(width: Float(view.width), height: Float(view.height))
        self.window = view
        didMove(view)
    }

    open func didMove(_ to: Window) {}
    open func willMove(_ from: Window) {}
    open func update(deltaTime: Double) {}
    open func fixedUpdate(deltaTime: Double) {}
    open func render(renderer: Renderer) {}

    open func keyDown(_ event: KeyEvent) {} 
    open func keyUp(_ event: KeyEvent) {}
    open func keyTyped(_ event: KeyEvent) {}

    open func mouseDown(_ event: MouseButtonEvent) {}
    open func mouseUp(_ event: MouseButtonEvent) {}
    open func mouseMoved(_ position: Point) {}
    open func mouseDragged(_ position: Point) {}
    open func mouseScrolled(_ scroll: Point) {}

    open func windowClosed(_ window: Window) {}
    open func windowResized(_ window: Window, size: Size) {}
    open func windowFocused(_ window: Window) {}
    open func windowLostFocus(_ window: Window) {}
    open func windowMoved(_ window: Window, position: Point) {}
}