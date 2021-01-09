/**
 * Copyright © 2021 Sebastian Toivonen
 * All Rights Reserved.
 *
 * Licensed under Apache License v2.0
 */

import GLFWSwift

internal final class VertexArray {
    private var rendererID: UInt32 = 0
    private var vertexBufferIndex: UInt32 = 0
    private(set) var vertexBuffers: [VertexBuffer] = []
    private(set) var indexBuffer: IndexBuffer?

    public init() {
        //MARK: Legacy OpenGL
        glGenVertexArrays(1, &rendererID)

        //MARK: Modern OpenGL
        //glCreateVertexArrays(1, &rendererID)
    }

    public func bind() {
        glBindVertexArray(rendererID)
    }

    public func unbind() {
        glBindVertexArray(0)
    }

    public func add(vertexBuffer: VertexBuffer) {
        guard let bufferLayout = vertexBuffer.bufferLayout, !bufferLayout.elements.isEmpty else {
            precondition(false, "Vertex Buffer has no layout")
            return
        }

        glBindVertexArray(rendererID)
        vertexBuffer.bind()

        for element in bufferLayout.elements {
            switch element.type {
                case .float, .float2, .float3, .float4,
                     .integer, .integer2, .integer3, .integer4,
                     .boolean:
                     glEnableVertexAttribArray(vertexBufferIndex)
                     glVertexAttribPointer(vertexBufferIndex,
                                           GLint(element.componentCount),
                                           shaderDataTypeToOpenGLBaseType(type: element.type),
                                           GLboolean(element.normalized ? GL_TRUE : GL_FALSE),
                                           GLsizei(bufferLayout.stride),
                                           UnsafeRawPointer(bitPattern: element.offset))
                    vertexBufferIndex += 1
                case .matrix3, .matrix4:
                    for i in 0..<element.componentCount {
                        glEnableVertexAttribArray(vertexBufferIndex)
                        glVertexAttribPointer(vertexBufferIndex,
                                              GLint(element.componentCount),
                                              shaderDataTypeToOpenGLBaseType(type: element.type),
                                              GLboolean(element.normalized ? GL_TRUE : GL_FALSE),
                                              GLsizei(bufferLayout.stride),
                                              UnsafeRawPointer(bitPattern: element.offset + MemoryLayout<Float>.stride * element.componentCount * i))
                        //glVertexAttribDivisor(vertexBufferIndex, 1)
                        vertexBufferIndex += 1
                    }
            }
        }
        vertexBuffers.append(vertexBuffer)
    }

    public func set(indexBuffer: IndexBuffer) {
        glBindVertexArray(rendererID)
        indexBuffer.bind()
        self.indexBuffer = indexBuffer
    }

    deinit {
        glDeleteVertexArrays(1, &rendererID)
    }
}

fileprivate func shaderDataTypeToOpenGLBaseType(type: ShaderDataType) -> GLenum {
    switch type { 
        case .float:    return GLenum(GL_FLOAT)
        case .float2:   return GLenum(GL_FLOAT)
        case .float3:   return GLenum(GL_FLOAT)
        case .float4:   return GLenum(GL_FLOAT)
        case .matrix3:  return GLenum(GL_FLOAT)
        case .matrix4:  return GLenum(GL_FLOAT)
        case .integer:  return GLenum(GL_INT)
        case .integer2: return GLenum(GL_INT)
        case .integer3: return GLenum(GL_INT)
        case .integer4: return GLenum(GL_INT)
        case .boolean:  return GLenum(GL_BOOL)
    }
}