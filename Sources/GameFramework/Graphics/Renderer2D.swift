import GLMSwift
import GLFWSwift
import Dispatch

fileprivate let maxQuads = 500
fileprivate let maxVertices = maxQuads * 4
fileprivate let maxIndices = maxQuads * 6
fileprivate let maxTextureSlots = 32
fileprivate let textureCoords: [vec2] = [vec2(0.0, 0.0), vec2(1.0, 0.0), vec2(1.0, 1.0), vec2(0.0, 1.0)]

internal final class Renderer2D: Renderer {
    public struct Statistics {
        var drawCalls = 0
        var quadCount = 0
        
        var lastFrameDrawCalls = 0
        var lastFrameQuadCount = 0

        var totalVertexCount: Int {
            quadCount * 4
        }

        var totalIndexCount: Int {
            quadCount * 6
        }

        public mutating func reset() {
            lastFrameDrawCalls = drawCalls
            lastFrameQuadCount = quadCount
            drawCalls = 0
            quadCount = 0
        }
    }

    internal struct QuadVertex {
        var position: vec3
        var color: vec4
        var texCoord: vec2
        var texIndex: Float
        var tilingFactor: Float
        var colorBlendFactor: Float
        var matrix: mat4
    }

    internal struct Renderer2DData {
        public var quadVertexArray: VertexArray!
        public var quadVertexBuffer: VertexBuffer!
        public var textureShader: Shader!
        public var whiteTexture: Texture2D!

        public var quadIndexCount = 0
        public var quadVertexBufferBase: UnsafeMutablePointer<QuadVertex>!
        public var quadVertexBufferPtr: UnsafeMutablePointer<QuadVertex>!

        public var textureSlots: [Texture2D?] = (0..<maxTextureSlots).map {_ in nil}
        var textureSlotIndex = 1 //0 = white texture

        var quadVertexPositions: [vec4] = [vec4(), vec4(), vec4(), vec4()]

        public var stats = Renderer2D.Statistics()
    }
    
    @usableFromInline
    internal var data = Renderer2DData()
    private var alreadyShutdown: Bool = false

    public init() {
        //TODO: Implement Renderer2D(Metal/Vulkan/DirectX...)
        // For example on iOS and macOS we will use SpriteKit as our Rendering backend (Maybe metal some day)
        // So we will not be doing exactly this
        data.quadVertexArray = VertexArray()
        data.quadVertexBuffer = VertexBuffer(size: maxVertices * MemoryLayout<QuadVertex>.stride)
        data.quadVertexBuffer.bufferLayout = BufferLayout(elements: [
            BufferElement(name: "a_Position", type: .float3),
            BufferElement(name: "a_Color", type: .float4),
            BufferElement(name: "a_TexCoord", type: .float2),
            BufferElement(name: "a_TexIndex", type: .float),
            BufferElement(name: "a_TilingFactor", type: .float),
            BufferElement(name: "a_ColorBlendFactor", type: .float),
            BufferElement(name: "a_Transform", type: .matrix4)
        ])
        data.quadVertexArray.add(vertexBuffer: data.quadVertexBuffer)
        data.quadVertexBufferBase = UnsafeMutablePointer<QuadVertex>.allocate(capacity: maxVertices)
        data.quadVertexBufferBase.initialize(repeating: QuadVertex(position: vec3(0.0, 0.0, 0.0), 
                                                                   color: vec4(1.0, 1.0, 1.0, 1.0), 
                                                                   texCoord: vec2(0.0, 0.0), 
                                                                   texIndex: 1.0, 
                                                                   tilingFactor: 1.0,
                                                                   colorBlendFactor: 0.0,
                                                                   matrix: mat4(1)), count: maxVertices)
        data.quadVertexBufferPtr = data.quadVertexBufferBase

        var quadIndices = [UInt32]()

        var offset: UInt32 = 0
        var i = 0
        while i < maxIndices {
            quadIndices.append(offset + 0)
            quadIndices.append(offset + 1)
            quadIndices.append(offset + 2)
            quadIndices.append(offset + 2)
            quadIndices.append(offset + 3)
            quadIndices.append(offset + 0)
            i += 6
            offset += 4
        }

        let quadIB = IndexBuffer(indices: quadIndices)
        data.quadVertexArray.set(indexBuffer: quadIB)
        data.whiteTexture = Texture2D(width: 1, height: 1)
        var whiteTextureData: UInt32 = 0xffffffff
        withUnsafeMutablePointer(to: &whiteTextureData) { ptr in
            ptr.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<UInt32>.stride) { bytePtr in 
                data.whiteTexture.setData(bytePtr, size: MemoryLayout<UInt32>.stride)
            }
        }

        var samplers = [Int32]()
        for i: UInt32 in 0..<UInt32(maxTextureSlots) {
            samplers.append(Int32(i))
        }

        //data.textureShader = Shader(name: "Texture", vertexName: "simpleVert", fragmentName: "simpleFrag")
        data.textureShader = Shader(name: "Texture", vertexSource: vertexShaderSource, fragmentSource: fragmentShaderSource)
        data.textureShader.bind()
        data.textureShader.set(samplers, name: "u_Textures")

        data.textureSlots[0] = data.whiteTexture

        data.quadVertexPositions[0] = vec4(-0.5, -0.5, 0.0, 1.0)
        data.quadVertexPositions[1] = vec4( 0.5, -0.5, 0.0, 1.0)
        data.quadVertexPositions[2] = vec4( 0.5,  0.5, 0.0, 1.0)
        data.quadVertexPositions[3] = vec4(-0.5,  0.5, 0.0, 1.0)

        for i in 0..<maxVertices {
            data.quadVertexBufferBase[i].position = data.quadVertexPositions[i % 4].xyz
            data.quadVertexBufferPtr[i].texCoord = textureCoords[i % 4]
        }

        glEnable(GLenum(GL_BLEND))
        glEnable(GLenum(GL_DEPTH_TEST))
        glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA))
        glEnable(GLenum(GL_MULTISAMPLE))
    }

    deinit {
        shutdown()
    }

    internal func shutdown() {
        if alreadyShutdown { return }
        alreadyShutdown = true
        data.quadVertexBufferBase.deallocate()
    }

    @inline(__always)
    internal final func beginScene(camera: Camera) {
        data.textureShader.bind()
        data.textureShader.set(camera.viewProjection, name: "u_ViewProjection")
        data.quadIndexCount = 0
        data.textureSlotIndex = 1
        data.quadVertexBufferPtr = data.quadVertexBufferBase
    }

    @inline(__always)
    internal func endScene() {
        guard let baseRaw = UnsafeRawPointer(data.quadVertexBufferBase),
              let ptrRaw  = UnsafeRawPointer(data.quadVertexBufferPtr) else {
                  fatalError("Buffer wasn't initialized")
              }
        let dataSize = baseRaw.distance(to: ptrRaw)
        data.quadVertexBuffer.setData(data.quadVertexBufferBase, size: dataSize)
        flush()
    }

    @inline(__always)
    internal func flush() {
        if data.quadIndexCount == 0 { return }
        for i in 0..<data.textureSlotIndex {
            data.textureSlots[i]?.bind(slot: i)
        }
        drawIndexed(vertexArray: data.quadVertexArray, indexCount: data.quadIndexCount)
        data.stats.drawCalls += 1
    }

    @inline(__always)
    public func drawQuad(position: Point, zPosition: Float, size: Size, color: Color) {
        drawQuad(position: vec3(Float(position.x), Float(position.y), zPosition), 
                 size: vec2(Float(size.width), Float(size.height)), 
                 color: vec4(color.red, color.green, color.blue, color.alpha))
    }

    @inline(__always)
    public func drawQuad(position: Point, zPosition: Float, zRotation: Float, size: Size, color: Color) {
        drawRotatedQuad(position: vec3(Float(position.x), Float(position.y), zPosition), 
                        size: vec2(Float(size.width), Float(size.height)), 
                        rotation: zRotation, 
                        color: vec4(color.red, color.green, color.blue, color.alpha))
    }

    @inline(__always)
    public func drawQuad(position: Point, zPosition: Float, zRotation: Float, size: Size, texture: Texture2D, tilingFactor: Float, tintColor: Color, colorBlendFactor: Float) {
        drawRotatedQuad(position: vec3(Float(position.x), Float(position.y), zPosition), 
                        size: vec2(Float(size.width), Float(size.height)), 
                        rotation: zRotation, 
                        texture: texture, 
                        tilingFactor: tilingFactor, 
                        tintColor: vec4(tintColor.red, tintColor.green, tintColor.blue, tintColor.alpha),
                        colorBlendFactor: colorBlendFactor)
    }

    @inline(__always)
    internal func drawQuad(position: vec2, size: vec2, color: vec4) {
        drawQuad(position: vec3(position.x, position.y, 0.0), size: size, color: color)
    }

    @inline(__always)
    internal func drawQuad(position: vec3, size: vec2, color: vec4) {
        let transform = GLMSwift.translation(position) * GLMSwift.scale(vec3(size.x, size.y, 1.0))
        drawQuad(transform: transform, color: color)
    }

    @inline(__always)
    internal func drawQuad(position: vec2, size: vec2, texture: Texture2D, tilingFactor: Float = 1.0, tintColor: vec4 = vec4(1.0, 1.0, 1.0, 1.0)) {
        drawQuad(position: vec3(position.x, position.y, 0.0), size: size, texture: texture, tilingFactor: tilingFactor, tintColor: tintColor)
    }
    
    @inline(__always)
    internal func drawQuad(position: vec3, size: vec2, texture: Texture2D, tilingFactor: Float = 1.0, tintColor: vec4 = vec4(1.0, 1.0, 1.0, 1.0)) {
        let transform = GLMSwift.translation(position) * GLMSwift.scale(vec3(size.x, size.y, 1.0))
        drawQuad(transform: transform, texture: texture, tilingFactor: tilingFactor, tintColor: tintColor)
    }
    
    public func drawQuad(transform: mat4, color: vec4) {
        let quadVertexCount = 4
        let textureIndex: Float = 0.0 // White texture
        let tilingFactor: Float = 1.0

        if data.quadIndexCount >= maxIndices { flushAndReset() }

        for _ in 0..<quadVertexCount {
            //data.quadVertexBufferPtr.pointee.position = data.quadVertexPositions[i].xyz//(transform * data.quadVertexPositions[i]).xyz
            data.quadVertexBufferPtr.pointee.color = color
            //data.quadVertexBufferPtr.pointee.texCoord = textureCoords[i]
            data.quadVertexBufferPtr.pointee.texIndex = textureIndex
            data.quadVertexBufferPtr.pointee.tilingFactor = tilingFactor
            //TODO: The transformation matrix should only be set per quad not per vertex... Find a way to do it
            data.quadVertexBufferPtr.pointee.matrix = transform
            data.quadVertexBufferPtr += 1
        }
        data.quadIndexCount += 6
        data.stats.quadCount += 1
    }

    public func drawQuad(transform: mat4, texture: Texture2D, tilingFactor: Float = 1.0, tintColor: vec4 = vec4(1.0, 1.0, 1.0, 1.0), colorBlendFactor: Float = 0.0) {
        let quadVertexCount = 4

        if data.quadIndexCount >= maxIndices { flushAndReset() }

        var textureIndex: Float = 0.0
        for i in 0..<data.textureSlotIndex {
            if let textureSlot = data.textureSlots[i] {
                if textureSlot == texture {
                    textureIndex = Float(i)
                    break
                }
            }
        }

        if textureIndex == 0.0 {
            if data.textureSlotIndex >= maxTextureSlots { flushAndReset() }
            textureIndex = Float(data.textureSlotIndex)
            data.textureSlots[data.textureSlotIndex] = texture
            data.textureSlotIndex += 1
        }

        for _ in 0..<quadVertexCount {
            //data.quadVertexBufferPtr.pointee.position = data.quadVertexPositions[i].xyz//(transform * data.quadVertexPositions[i]).xyz
            data.quadVertexBufferPtr.pointee.color = tintColor
            //TODO: Maybe these have to be set dynamically if texture atlases are used
            //data.quadVertexBufferPtr.pointee.texCoord = textureCoords[i]
            data.quadVertexBufferPtr.pointee.texIndex = textureIndex
            data.quadVertexBufferPtr.pointee.tilingFactor = tilingFactor
            data.quadVertexBufferPtr.pointee.colorBlendFactor = colorBlendFactor;
            //TODO: The transformation matrix should only be set per quad not per vertex... Find a way to do it
            data.quadVertexBufferPtr.pointee.matrix = transform
            data.quadVertexBufferPtr += 1
        }
        
        data.quadIndexCount += 6
        data.stats.quadCount += 1
    }

    @inline(__always)
    internal func drawRotatedQuad(position: vec2, size: vec2, rotation: Float, color: vec4) {
        drawRotatedQuad(position: vec3(position.x, position.y, 0.0), size: size, rotation: rotation, color: color)
    }
    
    @inline(__always)
    internal func drawRotatedQuad(position: vec3, size: vec2, rotation: Float, color: vec4) {
        let transform = GLMSwift.translation(position) 
                      * GLMSwift.rotation(rotation, vec3(0.0, 0.0, 1.0))
                      * GLMSwift.scale(vec3(size.x, size.y, 1.0))
        drawQuad(transform: transform, color: color)
    }
    
    @inline(__always)
    internal func drawRotatedQuad(position: vec2, size: vec2, rotation: Float, texture: Texture2D, tilingFactor: Float = 1.0, tintColor: vec4 = vec4(1.0), colorBlendFactor: Float = 0.0) {
        drawRotatedQuad(position: vec3(position.x, position.y, 0.0), size: size, rotation: rotation, texture: texture, tilingFactor: tilingFactor, tintColor: tintColor, colorBlendFactor: colorBlendFactor)
    }
    
    @inline(__always)
    internal func drawRotatedQuad(position: vec3, size: vec2, rotation: Float, texture: Texture2D, tilingFactor: Float = 1.0, tintColor: vec4 = vec4(1.0), colorBlendFactor: Float = 0.0) {
        let transform = GLMSwift.translation(position) 
                      * GLMSwift.rotation(rotation, vec3(0.0, 0.0, 1.0))
                      * GLMSwift.scale(vec3(size.x, size.y, 1.0))
        drawQuad(transform: transform, texture: texture, tilingFactor: tilingFactor, tintColor: tintColor, colorBlendFactor: colorBlendFactor)
    }
    
    @inline(__always)
    public func commit() {
        //TODO: Commit the render commands to the queue and swap the pointer to the current render state
    }

    @inline(__always)
    internal func getDrawCalls() -> Int {
        data.stats.lastFrameDrawCalls
    }

    @inline(__always)
    internal func getQuadCount() -> Int {
        data.stats.lastFrameQuadCount
    }

    @inline(__always)
    internal func resetGraphicsStats() {
        data.stats.reset()
    }

    @inlinable
    internal func drawIndexed(vertexArray: VertexArray, indexCount: Int = 0) {
        let count = Int32(indexCount > 0 ? indexCount : vertexArray.indexBuffer!.count)
        vertexArray.bind()
        glDrawElements(GLenum(GL_TRIANGLES), count, GLenum(GL_UNSIGNED_INT), nil)
        glBindTexture(GLenum(GL_TEXTURE_2D), 0)
    }

    public func render(scene: Scene) {
        clear(color: scene.backgroundColor)
        beginScene(camera: scene.camera ?? scene._defaultCamera)
        scene.render(renderer: self)
        endScene()
    }

    public func didResize(width: Int, height: Int) {
        glViewport(0, 0, GLsizei(width), GLsizei(height))
    }

    @inline(__always)
    public func clear(color: Color) {
        setClear(color: color)
        clear()
    }

    @inline(__always)
    public func setClear(color: Color) {
        glClearColor(color.red, color.green, color.blue, color.alpha)
    }

    @inline(__always)
    public func clear() {
        glClear(GLenum(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
    }

    private func flushAndReset() {
        endScene()
        data.quadIndexCount = 0
        data.textureSlotIndex = 1
        data.quadVertexBufferPtr = data.quadVertexBufferBase
    }
}