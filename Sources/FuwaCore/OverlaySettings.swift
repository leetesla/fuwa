import Foundation

public enum OverlayCaptureQuality: String, CaseIterable, Codable, Equatable, Sendable {
    case economy
    case high
    case ultra

    public var maximumPixelCount: Int {
        switch self {
        case .economy:
            4_000_000
        case .high:
            9_000_000
        case .ultra:
            16_000_000
        }
    }
}

public struct OverlayFrame: Codable, Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public var isValid: Bool {
        x.isFinite
            && y.isFinite
            && width.isFinite
            && height.isFinite
            && width >= 160
            && height >= 90
    }
}
