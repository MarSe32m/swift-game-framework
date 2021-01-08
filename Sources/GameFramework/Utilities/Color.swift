public struct Color {
    public var red: Float
    public var green: Float
    public var blue: Float
    public var alpha: Float

    public init(red: Float, green: Float, blue: Float, alpha: Float) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    //TODO: More colors
    public static let white: Color = .init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    public static let lightGray: Color = .init(red: 0.75, green: 0.75, blue: 0.75, alpha: 1.0)
    public static let gray: Color  = .init(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
    public static let darkGray: Color = .init(red: 0.25, green: 0.25, blue: 0.25, alpha: 1.0)
    public static let black: Color = .init(red: 0, green: 0, blue: 0, alpha: 1.0)
}