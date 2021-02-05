/**
 * Copyright © 2021 Sebastian Toivonen
 * All Rights Reserved.
 *
 * Licensed under Apache License v2.0
 */

import GLFWSwift
import stb_image

public final class Texture2D: Equatable {
    public private(set) var width: Int32 = 0
    public private(set) var height: Int32 = 0 
    public private(set) var textureID: UInt32 = 0

    private var path: String = ""
    private var internalFormat: Int32 = 0
    private var dataFormat: Int32 = 0

    public init(width: Int, height: Int) {
        self.internalFormat = GL_RGBA8
        self.dataFormat = GL_RGBA
        self.width = Int32(width)
        self.height = Int32(height)

        //MARK: OpenGL old
        glGenTextures(1, &textureID)
        glBindTexture(GLenum(GL_TEXTURE_2D), textureID)
        glTexStorage2D(GLenum(GL_TEXTURE_2D), 1, GLenum(internalFormat), GLsizei(width), GLsizei(height))

        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GLint(GL_LINEAR))
		glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GLint(GL_NEAREST))

		glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GLint(GL_REPEAT))
		glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GLint(GL_REPEAT))

        //MARK: OpenGL modern
        /*
        glCreateTextures(GLenum(GL_TEXTURE_2D), 1, &textureID)
        glTextureStorage2D(textureID, 1, GLenum(internalFormat), GLsizei(width), GLsizei(height))

		glTextureParameteri(textureID, GLenum(GL_TEXTURE_MIN_FILTER), GLint(GL_LINEAR))
		glTextureParameteri(textureID, GLenum(GL_TEXTURE_MAG_FILTER), GLint(GL_NEAREST))

		glTextureParameteri(textureID, GLenum(GL_TEXTURE_WRAP_S), GLint(GL_REPEAT))
		glTextureParameteri(textureID, GLenum(GL_TEXTURE_WRAP_T), GLint(GL_REPEAT))
        */
    }

    /// Example path: 
    /// let path = Bundle.main.path(forResource: "texture", ofType: "png")!
    /// let texture = Texture2D(path: path)
    public init(path: String) {
        self.path = path

        var channels: Int32 = 0
        stbi_set_flip_vertically_on_load(1)
        guard let data = stbi_load(path, &width, &height, &channels, 0) else {
            fatalError("Failed to load image from path: \(path)")
        }
        
        if channels == 4 {
            internalFormat = GL_RGBA8
            dataFormat = GL_RGBA
        } else if channels == 3 {
            internalFormat = GL_RGB8
            dataFormat = GL_RGB
        } else {
            fatalError("Format not supported")
        }

        //MARK: Legacy OpenGL
        glGenTextures(1, &textureID)
        glBindTexture(GLenum(GL_TEXTURE_2D), textureID)
        glTexStorage2D(GLenum(GL_TEXTURE_2D), 1, GLenum(internalFormat), GLsizei(width), GLsizei(height))

        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GLint(GL_LINEAR))
		glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GLint(GL_NEAREST))

		glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GLint(GL_REPEAT))
		glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GLint(GL_REPEAT))

        //MARK: OpenGL modern
        /*
        glCreateTextures(GLenum(GL_TEXTURE_2D), 1, &textureID)
		glTextureStorage2D(textureID, 1, GLenum(internalFormat), GLsizei(width), GLsizei(height))

		glTextureParameteri(textureID, GLenum(GL_TEXTURE_MIN_FILTER), GLint(GL_LINEAR))
		glTextureParameteri(textureID, GLenum(GL_TEXTURE_MAG_FILTER), GLint(GL_NEAREST))

		glTextureParameteri(textureID, GLenum(GL_TEXTURE_WRAP_S), GLint(GL_REPEAT))
		glTextureParameteri(textureID, GLenum(GL_TEXTURE_WRAP_T), GLint(GL_REPEAT))
        */

        setData(data, size: Int(width * height * (dataFormat == GL_RGBA ? 4 : 3)))
		stbi_image_free(data);
    }

    internal func setData(_ data: inout [UInt8]) {
        setData(&data, size: data.count)
    }

    internal func setData(_ data: UnsafeMutablePointer<UInt8>, size: Int) {
        let bpp = Int32(dataFormat == GL_RGBA ? 4 : 3)
        precondition(size == Int(width * height * bpp), "Data must be the entire texture!")
        
        //MARK: Legacy OpenGL
        glBindTexture(GLenum(GL_TEXTURE_2D), textureID)
        glTexSubImage2D(GLenum(GL_TEXTURE_2D), 0, 0, 0, GLsizei(width), GLsizei(height), GLenum(dataFormat), GLenum(GL_UNSIGNED_BYTE), data)
        
        //MARK: Modern OpenGL
        //glTextureSubImage2D(textureID, 0, 0, 0, GLsizei(width), GLsizei(height), GLenum(dataFormat), GLenum(GL_UNSIGNED_BYTE), data)
    }

    internal func bind(slot: Int = 0) {
        //MARK: Legacy OpenGL
        glActiveTexture(GLuint(GL_TEXTURE0) + GLuint(slot))
        glBindTexture(GLenum(GL_TEXTURE_2D), textureID)

        //MARK: Modern OpenGL
        //glBindTextureUnit(GLuint(slot), textureID)
    }

    public static func == (lhs: Texture2D, rhs: Texture2D) -> Bool {
        lhs.textureID == rhs.textureID
    }

    deinit {
        glDeleteTextures(1, &textureID)
    }
}