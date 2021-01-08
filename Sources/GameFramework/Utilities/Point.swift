public struct Point {
    public var x: Double
    public var y: Double

    public static let zero: Point = Point()

    public init(_ x: Double = 0, _ y: Double = 0) {
        self.x = x
        self.y = y
    }

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public init(_ x: Float, _ y: Float) {
        self.x = Double(x)
        self.y = Double(y)
    }

    public init(x: Float, y: Float) {
        self.x = Double(x)
        self.y = Double(y)
    }

    public init(_ x: Int, _ y: Int) {
        self.x = Double(x)
        self.y = Double(y)
    }

    public init(x: Int, y: Int) {
        self.x = Double(x)
        self.y = Double(y)
    }
}