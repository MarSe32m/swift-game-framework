import GLMSwift

public protocol Renderable {
    func render(renderer: Renderer)
}

public protocol Renderer {
    func drawQuad(position: Point, zPosition: Float, size: Size, color: Color)
    func drawQuad(position: Point, zPosition: Float, zRotation: Float, size: Size, color: Color)
    func drawQuad(position: Point, zPosition: Float, zRotation: Float, size: Size, texture: Texture2D)
    func drawQuad(position: Point, zPosition: Float, zRotation: Float, size: Size, texture: Texture2D, tilingFactor: Float, tintColor: Color, colorBlendFactor: Float)

    func drawQuad(transform: mat4, color: vec4)
    func drawQuad(transform: mat4, texture: Texture2D, tilingFactor: Float, tintColor: vec4, colorBlendFactor: Float)

    //TODO: Draw line
    //TODO: Draw basic shapes etc.
    //TODO: Draw polygons
    //TODO: Draw vertices with custom shader?

    func render(scene: Scene)
    func didResize(width: Int, height: Int)
    
    func commit()

    func setClear(color: Color)
    func clear(color: Color)
    func clear()

    func getDrawCalls() -> Int
    func getQuadCount() -> Int
    func resetGraphicsStats()
}

extension Renderer {
    func commit() {}
    func drawQuad(position: Point, zPosition: Float, zRotation: Float, size: Size, texture: Texture2D) {
        drawQuad(position: position, zPosition: zPosition, zRotation: zRotation, size: size, texture: texture, tilingFactor: 1.0, tintColor: .white, colorBlendFactor: 0.0)
    }
}