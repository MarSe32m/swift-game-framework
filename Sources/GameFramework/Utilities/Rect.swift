/**
 * Copyright © 2021 Sebastian Toivonen
 * All Rights Reserved.
 *
 * Licensed under Apache License v2.0
 */

public struct Rect {
    public var origin: Point
    public var size: Size

    public var width: Double {
        size.width
    }

    public var height: Double {
        size.height
    }

    public var minX: Double {
        return (size.width >= 0 ? origin.x : origin.x + size.width)
    }

    public var midX: Double {
        return (size.width + origin.x) / 2
    }
    
    public var maxX: Double {
        return (size.width >= 0 ? origin.x + size.width : origin.x)
    }
    
    public var minY: Double {
        return (size.height >= 0 ? origin.y : origin.y + size.height)
    }
    
    public var midY: Double {
        return (size.height + origin.y) / 2
    }
    
    public var maxY: Double {
        return (size.height >= 0 ? origin.y + size.height : origin.y)
    }

    public init(origin: Point = .zero, size: Size = .zero) {
        self.origin = origin
        self.size = size
    }

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.origin = Point(x, y)
        self.size = Size(width, height)
    }
    
    public init(x: Int, y: Int, width: Int, height: Int) {
        self.origin = Point(x, y)
        self.size = Size(width, height)
    }

    public init(x: Float, y: Float, width: Float, height: Float) {
        self.origin = Point(x, y)
        self.size = Size(width, height)
    }
}