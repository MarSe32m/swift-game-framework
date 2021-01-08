import GLFWSwift
import GLMSwift
import Foundation

internal class Shader {
    public var name: String = ""
    var rendererID: UInt32 = 0

    public init(name: String, path: String) {
        do {
            let source = try readFile(filePath: path)
            let shaderSources: [GLenum: String] = preProcess(source: source)
            compile(shaderSources)
        } catch {
            fatalError("Failed to read shader file!")
        }
        //TODO: Get the name of the shader from the file path
    }

    public convenience init(name: String, vertexName: String, fragmentName: String) {
        guard let vertexPath = Bundle.main.path(forResource: vertexName, ofType: "glsl"),
              let fragmentPath = Bundle.main.path(forResource: fragmentName, ofType: "glsl") else {
                  preconditionFailure("Failed to load shader name: \(name)")
        }
        self.init(name: name, vertexPath: vertexPath, fragmentPath: fragmentPath)
    }

    public convenience init(name: String, vertexPath: String, fragmentPath: String) {
        guard let vertexSource = try? String(contentsOfFile: vertexPath, encoding: .utf8),
              let fragmentSource = try? String(contentsOfFile: fragmentPath, encoding: .utf8) else {
                  preconditionFailure("Failed to load shader sources, vertexPath: \(vertexPath), fragmentPath: \(fragmentPath)")
        }
        self.init(name: name, vertexSource: vertexSource, fragmentSource: fragmentSource)
    }

    public init(name: String, vertexSource: String, fragmentSource: String) {
        self.name = name
        var sources = [GLenum: String]()
        sources[GLenum(GL_VERTEX_SHADER)] = vertexSource
        sources[GLenum(GL_FRAGMENT_SHADER)] = fragmentSource
        compile(sources)
    }

    public static func shaderType(from type: String) -> GLenum {
        if type == "vertex" { return GLenum(GL_VERTEX_SHADER) }
        if type == "fragment" { return GLenum(GL_FRAGMENT_SHADER) }
        fatalError("Unknown shader type: \(type)")
    }

    public func bind() {
        glUseProgram(rendererID)
    }

    public func unbind() {
        glUseProgram(0)
    }

    public func set(_ integer: Int32, name: String) {
        uploadUniform(integer, name: name)
    }

    public func set(_ integerArray: [Int32], name: String) {
        uploadUniform(integerArray, name: name)
    }

    public func set(_ float: Float, name: String) {
        uploadUniform(float, name: name)
    }

    public func set(_ vector3: vec3, name: String) {
        uploadUniform(vector3, name: name)
    }

    public func set(_ vector4: vec4, name: String) {
        uploadUniform(vector4, name: name)
    }

    public func set(_ matrix3: mat3, name: String) {
        var matrix = matrix3
        uploadUniform(&matrix, name: name)
    }

    public func set(_ matrix4: mat4, name: String) {
        var matrix = matrix4
        uploadUniform(&matrix, name: name)
    }

    private func uploadUniform(_ value: Int32, name: String) {
        let location = glGetUniformLocation(rendererID, name)
        glUniform1i(location, value)
    }
    
    private func uploadUniform(_ values: [Int32], name: String) {
        let location = glGetUniformLocation(rendererID, name)
        glUniform1iv(location, GLint(values.count), values)
    }

    private func uploadUniform(_ value: Float, name: String) {
        let location = glGetUniformLocation(rendererID, name)
        glUniform1f(location, value)
    }

    private func uploadUniform(_ value: vec2, name: String) {
        let location = glGetUniformLocation(rendererID, name)
        glUniform2f(location, value.x, value.y)
    }

    private func uploadUniform(_ value: vec3, name: String) {
        let location = glGetUniformLocation(rendererID, name)
        glUniform3f(location, value.x, value.y, value.z)
    }
    
    private func uploadUniform(_ value: vec4, name: String) {
        let location = glGetUniformLocation(rendererID, name)
        glUniform4f(location, value.x, value.y, value.z, value.w)
    }

    private func uploadUniform(_ matrix: inout mat3, name: String) {
        let location = glGetUniformLocation(rendererID, name)
        glUniformMatrix3fv(location, 1, GLboolean(GL_FALSE), &matrix.m11)
    }

    private func uploadUniform(_ matrix: inout mat4, name: String) {
        let location = glGetUniformLocation(rendererID, name)
        glUniformMatrix4fv(location, 1, GLboolean(GL_FALSE), &matrix.m11)
    }

    private func readFile(filePath: String) throws -> String {
        return try String(contentsOfFile: filePath)
    }

    private func preProcess(source: String) -> [GLenum: String] {
        var shaderSources = [GLenum : String]()
        var sourceCopy = source
        let typeToken = "#type"
        let typeTokenLength = typeToken.count

        var position = sourceCopy.range(of: typeToken)?.lowerBound ?? sourceCopy.startIndex

        while position < sourceCopy.endIndex {
            position = sourceCopy.range(of: typeToken)?.lowerBound ?? sourceCopy.startIndex
            if position != sourceCopy.startIndex {
                sourceCopy.removeSubrange(sourceCopy.startIndex...position)
                position = sourceCopy.startIndex
            }

            let endOfLine = sourceCopy.firstIndex(of: "\r\n") ?? sourceCopy.firstIndex(of: "\n") ?? sourceCopy.endIndex
            precondition(endOfLine != sourceCopy.endIndex, "Syntax error")

            let begin = sourceCopy.index(position, offsetBy: typeTokenLength)
            var type = String(sourceCopy[begin..<endOfLine])
            type.removeAll(where: {$0 == " "})

            let nextLinePos = sourceCopy.index(after: endOfLine)
            precondition(nextLinePos != sourceCopy.endIndex, "Syntax error")
            sourceCopy.removeSubrange(sourceCopy.startIndex..<nextLinePos)

            position = sourceCopy.range(of: typeToken)?.lowerBound ?? sourceCopy.endIndex
            shaderSources[Shader.shaderType(from: type)] = position == sourceCopy.endIndex ?
            String(sourceCopy[sourceCopy.startIndex..<sourceCopy.endIndex]) :
            String(sourceCopy[sourceCopy.startIndex..<position])
            sourceCopy.removeSubrange(sourceCopy.startIndex..<position)
        }
        return shaderSources
    }

    private func compile(_ shaderSources: [GLenum: String]) {
        rendererID = glCreateProgram()
        var glShaderIDs: [GLenum] = [0, 0]
        var glShaderIDIndex = 0
        var infoLog = [GLchar](repeating: 0, count: 512)

        for (type, source) in shaderSources {
            // Build and compile our shader program
            let shader = glCreateShader(type)
            source.withCString {
                var string: UnsafePointer<GLchar>? = $0
                glShaderSource(shader, 1, &string, nil)
            }
            glCompileShader(shader)

            var isCompiled: GLint = 0
            glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &isCompiled)

            guard isCompiled == GL_TRUE else {
                glGetShaderInfoLog(shader, 512, nil, &infoLog)
                glDeleteShader(shader)
                fatalError(String(cString: infoLog))
            }

            glAttachShader(rendererID, shader)
            glShaderIDs[glShaderIDIndex] = shader
            glShaderIDIndex += 1
        }
        // Link shaders
        glLinkProgram(rendererID)

        var isLinked: GLint = 0
        glGetProgramiv(rendererID, GLenum(GL_LINK_STATUS), &isLinked)
        guard isLinked == GL_TRUE else {
            glGetProgramInfoLog(rendererID, 512, nil, &infoLog)
            fatalError(String(cString: infoLog))
        }

        for id in glShaderIDs {
            glDetachShader(rendererID, id)
            glDeleteShader(id)
        }
    }

    deinit {
        glDeleteShader(rendererID)
    }
}

internal let fragmentShaderSource = """
#version 330 core

layout(location = 0) out vec4 color;

in vec4 v_Color;
in vec2 v_TexCoord;
in float v_TexIndex;
in float v_TilingFactor;
in float v_ColorBlendFactor;

uniform sampler2D u_Textures[32];

void main()
{   
    vec4 texColor = v_Color;
    switch(int(v_TexIndex))
    {
        case 0: texColor  *= texture(u_Textures[0], v_TexCoord * v_TilingFactor); break;
        case 1: texColor  = texture(u_Textures[1], v_TexCoord * v_TilingFactor); break;
        case 2: texColor  = texture(u_Textures[2], v_TexCoord * v_TilingFactor); break;
        case 3: texColor  = texture(u_Textures[3], v_TexCoord * v_TilingFactor); break;
        case 4: texColor  = texture(u_Textures[4], v_TexCoord * v_TilingFactor); break;
        case 5: texColor  = texture(u_Textures[5], v_TexCoord * v_TilingFactor); break;
        case 6: texColor  = texture(u_Textures[6], v_TexCoord * v_TilingFactor); break;
        case 7: texColor  = texture(u_Textures[7], v_TexCoord * v_TilingFactor); break;
        case 8: texColor  = texture(u_Textures[8], v_TexCoord * v_TilingFactor); break;
        case 9: texColor  = texture(u_Textures[9], v_TexCoord * v_TilingFactor); break;
        case 10: texColor = texture(u_Textures[10], v_TexCoord * v_TilingFactor); break;
        case 11: texColor = texture(u_Textures[11], v_TexCoord * v_TilingFactor); break;
        case 12: texColor = texture(u_Textures[12], v_TexCoord * v_TilingFactor); break;
        case 13: texColor = texture(u_Textures[13], v_TexCoord * v_TilingFactor); break;
        case 14: texColor = texture(u_Textures[14], v_TexCoord * v_TilingFactor); break;
        case 15: texColor = texture(u_Textures[15], v_TexCoord * v_TilingFactor); break;
        case 16: texColor = texture(u_Textures[16], v_TexCoord * v_TilingFactor); break;
        case 17: texColor = texture(u_Textures[17], v_TexCoord * v_TilingFactor); break;
        case 18: texColor = texture(u_Textures[18], v_TexCoord * v_TilingFactor); break;
        case 19: texColor = texture(u_Textures[19], v_TexCoord * v_TilingFactor); break;
        case 20: texColor = texture(u_Textures[20], v_TexCoord * v_TilingFactor); break;
        case 21: texColor = texture(u_Textures[21], v_TexCoord * v_TilingFactor); break;
        case 22: texColor = texture(u_Textures[22], v_TexCoord * v_TilingFactor); break;
        case 23: texColor = texture(u_Textures[23], v_TexCoord * v_TilingFactor); break;
        case 24: texColor = texture(u_Textures[24], v_TexCoord * v_TilingFactor); break;
        case 25: texColor = texture(u_Textures[25], v_TexCoord * v_TilingFactor); break;
        case 26: texColor = texture(u_Textures[26], v_TexCoord * v_TilingFactor); break;
        case 27: texColor = texture(u_Textures[27], v_TexCoord * v_TilingFactor); break;
        case 28: texColor = texture(u_Textures[28], v_TexCoord * v_TilingFactor); break;
        case 29: texColor = texture(u_Textures[29], v_TexCoord * v_TilingFactor); break;
        case 30: texColor = texture(u_Textures[30], v_TexCoord * v_TilingFactor); break;
        case 31: texColor = texture(u_Textures[31], v_TexCoord * v_TilingFactor); break;
    }

    float colorBlendFactor = clamp(v_ColorBlendFactor, 0, 1);
    color = texColor * mix(vec4(1), v_Color, colorBlendFactor);
    //color = texColor;//vec4(mix(texColor.xyz, v_Color.xyz, v_Color.a), texColor.a);
}
"""

internal let vertexShaderSource = """
#version 330 core

layout(location = 0) in vec3 a_Position;
layout(location = 1) in vec4 a_Color;
layout(location = 2) in vec2 a_TexCoord;
layout(location = 3) in float a_TexIndex;
layout(location = 4) in float a_TilingFactor;
layout(location = 5) in float a_ColorBlendFactor;
layout(location = 6) in mat4 a_Transform;

uniform mat4 u_ViewProjection;

out vec4 v_Color;
out vec2 v_TexCoord;
out float v_TexIndex;
out float v_TilingFactor;
out float v_ColorBlendFactor;

void main()
{
    v_Color = a_Color;
    v_TexCoord = a_TexCoord;
    v_TexIndex = a_TexIndex;
    v_TilingFactor = a_TilingFactor;
    v_ColorBlendFactor = a_ColorBlendFactor;
    gl_Position = u_ViewProjection * a_Transform * vec4(a_Position, 1.0);
}
"""