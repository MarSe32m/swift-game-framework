/**
 * Copyright © 2021 Sebastian Toivonen
 * All Rights Reserved.
 *
 * Licensed under Apache License v2.0
 */

public struct Size {
    public var width: Double
    public var height: Double

    public static let zero: Size = Size()

    public init(width: Double = 0.0, height: Double = 0.0) {
        self.width = width
        self.height = height
    }

    public init(_ width: Double, _ height: Double) {
        self.width = width
        self.height = height
    }

    public init(width: Float, height: Float) {
        self.width = Double(width)
        self.height = Double(height)
    }
    
    public init(_ width: Float, _ height: Float) {
        self.width = Double(width)
        self.height = Double(height)
    }

    public init(width: Int, height: Int) {
        self.width = Double(width)
        self.height = Double(height)
    }
    
    public init(_ width: Int, _ height: Int) {
        self.width = Double(width)
        self.height = Double(height)
    }
}