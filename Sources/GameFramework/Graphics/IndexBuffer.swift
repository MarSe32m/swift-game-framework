/**
 * Copyright © 2021 Sebastian Toivonen
 * All Rights Reserved.
 *
 * Licensed under Apache License v2.0
 */

import GLFWSwift
import GLMSwift

internal class IndexBuffer {
    private var rendererID: UInt32 = 0
    public var count: Int {
        indices.count
    }

    private var indices: [UInt32]

    public init(indices: [UInt32]) {
        self.indices = indices

        //MARK: Legacy OpenGL
        glGenBuffers(1, &rendererID)
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), rendererID)
        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), GLsizeiptr(count * MemoryLayout<UInt32>.stride), indices, GLenum(GL_STATIC_DRAW))

        //MARK: Modern OpenGL
        //glCreateBuffers(1, &rendererID)
        //glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), rendererID)
        //glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), GLsizeiptr(count * MemoryLayout<UInt32>.stride), indices, GLenum(GL_STATIC_DRAW))
    }

    func bind() {
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), rendererID)
    }

    func unbind() {
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), 0)
    }

    deinit {
        glDeleteBuffers(1, &rendererID)
    }
}