import GameFramework
import Foundation
import GLMSwift

class TestScene: Scene {
    var squarePosition = Point(x: 0, y: 0)
    var velocity = Vector2<Double>(0, 0)
    let cam = OrthographicCamera(width: 1280, height: 720)
    var zRotation: Double = 0

    let pathFace = Bundle.main.path(forResource: "awesomeface", ofType: "png") ?? "NO PATH!"
    var texture2: Texture2D!

    override func didMove(_ to: Window) {
        camera = cam
        texture2 = Texture2D(path: pathFace)
    }

    override func update(deltaTime: Double) {
        velocity = Vector2<Double>(0, 0)
        if Application.shared.input.isKeyPressed(key: .w) {
            velocity.y += 1
        }
        if Application.shared.input.isKeyPressed(key: .s) {
            velocity.y -= 1
        }
        if Application.shared.input.isKeyPressed(key: .d) {
            velocity.x += 1
        }
        if Application.shared.input.isKeyPressed(key: .a) {
            velocity.x -= 1
        }
        let length = sqrt(velocity.x * velocity.x + velocity.y * velocity.y)

        if length != 0 {
            squarePosition.x += velocity.x / length * 500 * deltaTime
            squarePosition.y += velocity.y / length * 500 * deltaTime
        }
        
        cam.position.x += (Float(squarePosition.x) - cam.position.x) * 3 * Float(deltaTime)
        cam.position.y += (Float(squarePosition.y) - cam.position.y) * 3 * Float(deltaTime)
        zRotation += deltaTime
    }

    override func fixedUpdate(deltaTime: Double) {
        
    }

    override func windowResized(_ window: Window, size: Size) {
        self.size = size
    }

    override func render(renderer: Renderer) {
        // Do some node culling?
        renderer.drawQuad(position: Point(0, 0), zPosition: 0.8, zRotation: 0, size: Size(width: 300, height: 300), color: Color(red: 0, green: 1.0, blue: 0.4, alpha: 1))
        renderer.drawQuad(position: squarePosition, zPosition: 0.9, zRotation: Float(zRotation), size: Size(width: 300, height: 300), texture: texture2)
    }
}

let application = Application()
application.debug = true
let scene = TestScene(size: Size(width: 1280, height: 720))
application.present(scene)
application.setFramesPerSecond(144)
application.run()