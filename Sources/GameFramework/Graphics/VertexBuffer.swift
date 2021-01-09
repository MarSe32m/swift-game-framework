/**
 * Copyright © 2021 Sebastian Toivonen
 * All Rights Reserved.
 *
 * Licensed under Apache License v2.0
 */

import GLFWSwift
import GLMSwift

internal enum ShaderDataType {
    case float
    case float2
    case float3 
    case float4
    case matrix3
    case matrix4
    case integer
    case integer2
    case integer3
    case integer4
    case boolean

    //Type size in bytes
    public var typeSize: Int {
        switch self {
            case .float:    return 4
            case .float2:   return 4 * 2
            case .float3:   return 4 * 3
            case .float4:   return 4 * 4
            case .matrix3:  return 4 * 3 * 3
            case .matrix4:  return 4 * 4 * 4
            case .integer:  return 4
            case .integer2: return 4 * 2
            case .integer3: return 4 * 3
            case .integer4: return 4 * 4
            case .boolean:  return 1
        }
    }
}



internal struct BufferElement {
    public let name: String
    public let type: ShaderDataType
    public var offset: Int = 0
    public var normalized: Bool

    public let size: Int
    public let componentCount: Int

    public init(name: String, type: ShaderDataType, normalized: Bool = false) {
        self.name = name
        self.type = type
        self.normalized = normalized
        self.size = type.typeSize
        self.componentCount = {
            switch type {
                case .float, .integer, .boolean:    return 1
                case .float2, .integer2:            return 2
                case .float3, .integer3, .matrix3:  return 3 // For matrix3 its 3 vectors (which are the matrix' components :)
                case .float4, .integer4, .matrix4:  return 4 // For matrix4 its 4 vectors (which are the matrix' components :)
            }
        }()
    }
} 


internal struct BufferLayout {
    public var elements: [BufferElement]
    public private(set) var stride: Int = 0

    public init(elements: [BufferElement] = []) {
        self.elements = elements
        calculateOffsetsAndStride()
    }

    public mutating func set(elements: [BufferElement]) {
        self.elements = elements
    }

    private mutating func calculateOffsetsAndStride() {
        stride = 0
        for i in 0..<elements.count {
            elements[i].offset = stride
            stride += elements[i].size
        }
    }
}

internal final class VertexBuffer {
    private var rendererID: UInt32 = 0
    var bufferLayout: BufferLayout?

    public init(size: Int = 0, vertices: [Float] = []) {
        if vertices.isEmpty {
            precondition(size > 0, "Can't create a vertex buffer with a size of \(size)")
            //MARK: Legacy OpenGL
            glGenBuffers(1, &rendererID)
            glBindBuffer(GLenum(GL_ARRAY_BUFFER), rendererID)
            glBufferData(GLenum(GL_ARRAY_BUFFER), GLsizeiptr(size), nil, GLenum(GL_DYNAMIC_DRAW))

            //MARK: Modern OpenGL
            //glCreateBuffers(1, &rendererID)
            //glBindBuffer(GLenum(GL_ARRAY_BUFFER), rendererID)
            //glBufferData(GLenum(GL_ARRAY_BUFFER), GLsizeiptr(size), nil, GLenum(GL_DYNAMIC_DRAW))
        } else {
            let _size = size == 0 ? vertices.count : size
            precondition(size == 0 || size == vertices.count, "Vertex count wasn't equal to the size")
            //MARK: Legacy OpenGL
            glGenBuffers(1, &rendererID)
            glBindBuffer(GLenum(GL_ARRAY_BUFFER), rendererID)
            glBufferData(GLenum(GL_ARRAY_BUFFER), GLsizeiptr(_size), vertices, GLenum(GL_STATIC_DRAW))
            //MARK: Modern OpenGL
            //glCreateBuffers(1, &rendererID)
            //glBindBuffer(GLenum(GL_ARRAY_BUFFER), rendererID)
            //glBufferData(GLenum(GL_ARRAY_BUFFER), GLsizeiptr(_size), vertices, GLenum(GL_STATIC_DRAW))
        }
    }

    public func bind() {
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), rendererID)
    }

    public func unbind() {
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), 0)
    }

    public func setData(_ data: UnsafeRawPointer, size: Int) {
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), rendererID)
        glBufferSubData(GLenum(GL_ARRAY_BUFFER), 0, GLsizeiptr(size), data)
    }

    deinit {
        glDeleteBuffers(1, &rendererID)
    }    
}