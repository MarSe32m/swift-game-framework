import GLMSwift

public protocol Camera {
    var projection: mat4 { get }
    var position: vec3 { get set }
    var rotation: Float { get set }
    var zPosition: Float { get set }
    var xScale: Float { get set }
    var yScale: Float { get set }
    var viewProjection: mat4 { get }
    init(projection: mat4)

    func setOrthoProjection(width: Float, height: Float)
    func setOrthoProjection(left: Float, right: Float, bottom: Float, top: Float, zNear: Float, zFar: Float)
}

public final class OrthographicCamera: Camera {
    public private(set) var projection: mat4 { 
        didSet { needRecalculation = true }
    }

    private var _projection: mat4 = mat4(1)

    public var position: vec3 = vec3(0, 0, 0) {
        didSet { needRecalculation = true }
    }

    public var rotation: Float = 0 {
        didSet { needRecalculation = true }
    }

    public var zPosition: Float = 0 {
        didSet { position.z = zPosition }
    }

    public var xScale: Float = 1 {
        didSet { needRecalculation = true }
    }

    public var yScale: Float = 1 {
        didSet { needRecalculation = true }
    }

    private var needRecalculation: Bool = true

    internal private(set) var view: mat4 = mat4(1)

    private var _viewProjection: mat4 = mat4(1)

    public var viewProjection: mat4 {
        if !needRecalculation {
            return _viewProjection
        }
        needRecalculation = false
        recalculateViewMatrix()
        return _viewProjection
    }

    public init(projection: mat4) {
        self.projection = projection
    }

    public convenience init(width: Float, height: Float) {
        self.init(left: -width / 2, right: width / 2, bottom: -height / 2, top: height / 2, zNear: -1000.0, zFar: 1000.0)
    }

    public convenience init(left: Float, right: Float, bottom: Float, top: Float, zNear: Float = -1.0, zFar: Float = 1.0) {
        self.init(projection: GLMSwift.ortho(left, right, bottom, top, zNear, zFar))
        _viewProjection = projection * view
    }

    public func setOrthoProjection(width: Float, height: Float) {
        projection = GLMSwift.ortho(-width / 2, width / 2, -height / 2, height / 2, -1000.0, 1000.0)
    }

    public func setOrthoProjection(left: Float, right: Float, bottom: Float, top: Float, zNear: Float = -1.0, zFar: Float = 1.0) {
        projection = GLMSwift.ortho(left, right, bottom, top, zNear, zFar)
    }

    private func recalculateViewMatrix() {
        let transform = GLMSwift.translation(position) * GLMSwift.rotation(rotation, vec3(0, 0, 1)) * GLMSwift.scale(xScale: xScale, yScale: yScale, zScale: 1)
        view = transform.inverse
        _viewProjection = projection * view
    }
}