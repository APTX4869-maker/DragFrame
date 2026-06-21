import CoreGraphics

public enum CoordinateConverter {
    public static func appKitPoint(
        fromQuartz point: CGPoint,
        primaryScreenMaxY: CGFloat
    ) -> CGPoint {
        CGPoint(x: point.x, y: primaryScreenMaxY - point.y)
    }
}

