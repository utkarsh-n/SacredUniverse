import Foundation

public struct Point2D: Codable, Equatable, Hashable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public enum AngleUnit: String, Codable, CaseIterable, Sendable {
    case degrees
    case radians
    case turns

    public var label: String {
        switch self {
        case .degrees: "Degrees"
        case .radians: "Radians"
        case .turns: "Turns"
        }
    }

    public func value(fromDegrees degrees: Double) -> Double {
        switch self {
        case .degrees: degrees
        case .radians: degrees * (.pi / 180)
        case .turns: degrees / 360
        }
    }
}

/// Mathematical models for the app's experiments. Numerical patterns involving
/// digit sums depend on the numeral base and the chosen measurement unit.
public enum SacredMath {
    public static let secondsPerDay = 86_400
    public static let maximumPointCount = 4_096

    /// The repeated digit sum of the magnitude of `number`, in the given base.
    /// Zero stays zero. Bases below two are invalid and return zero.
    public static func digitalRoot(_ number: Int, base: Int = 10) -> Int {
        guard base >= 2 else { return 0 }
        let magnitude = number.magnitude
        guard magnitude > 0 else { return 0 }
        return Int(1 + (magnitude - 1) % UInt(base - 1))
    }

    /// Includes the supplied integer, then each sum of its unsigned digits.
    /// Keeping the supplied integer first also represents `Int.min` exactly.
    /// Bases below two are invalid and return an empty sequence.
    public static func digitReductionSteps(_ number: Int, base: Int = 10) -> [Int] {
        guard base >= 2 else { return [] }
        let radix = UInt(base)
        var steps = [number]
        var current = number.magnitude
        while current >= radix {
            var remaining = current
            var sum: UInt = 0
            repeat {
                sum += remaining % radix
                remaining /= radix
            } while remaining > 0
            steps.append(Int(sum))
            current = sum
        }
        if number < 0, steps.count == 1 {
            steps.append(Int(current))
        }
        return steps
    }

    /// Sum of the interior angles of a planar simple polygon, in degrees.
    public static func polygonInteriorSum(sides: Int) -> Double {
        guard sides >= 3 else { return 0 }
        return (Double(sides) - 2) * 180
    }

    /// Interior angle of a regular planar polygon, in degrees.
    public static func polygonInteriorAngle(sides: Int) -> Double {
        guard sides >= 3 else { return 0 }
        return polygonInteriorSum(sides: sides) / Double(sides)
    }

    /// Unit-radius regular polygon, starting at its top vertex in Cartesian
    /// coordinates. Invalid side counts return no points; allocation is bounded.
    public static func regularPolygon(sides: Int) -> [Point2D] {
        guard sides >= 3 else { return [] }
        let count = min(sides, maximumPointCount)
        return (0..<count).map { index in
            let angle = .pi / 2 + 2 * .pi * Double(index) / Double(count)
            return Point2D(x: cos(angle), y: sin(angle))
        }
    }

    /// Connect each residue `n` to `multiplier × n (mod modulus)`.
    /// Negative multipliers wrap normally. The modulus is capped to bound memory.
    public static func timesTable(multiplier: Int, modulus: Int) -> [(Int, Int)] {
        guard modulus > 0 else { return [] }
        let count = min(modulus, maximumPointCount)
        let remainder = multiplier % count
        let factor = remainder < 0 ? remainder + count : remainder
        return (0..<count).map { ($0, ($0 * factor) % count) }
    }

    /// A constant-period teaching model of axial precession, in degrees.
    /// The default 25,772-year period is approximate; real precession varies.
    /// This returns an unwrapped angle so full cycles remain visible.
    public static func precessionDegrees(years: Double, period: Double = 25_772) -> Double {
        guard years.isFinite, period.isFinite, period > 0 else { return 0 }
        let angle = years * (360 / period)
        return angle.isFinite ? angle : 0
    }

    public static func arcsecondsPerYear(period: Double) -> Double {
        guard period.isFinite, period > 0 else { return 0 }
        let rate = 1_296_000 / period
        return rate.isFinite ? rate : 0
    }

    /// Centers for the seven equal circles of a seed pattern. The first is the
    /// center, followed by neighbors separated by 60 degrees, one radius away.
    public static func circles(seedCount: Int, radius: Double = 1) -> [Point2D] {
        guard radius.isFinite, radius > 0 else { return [] }
        let count = min(max(seedCount, 1), 7)
        return (0..<count).map { index in
            guard index > 0 else { return Point2D(x: 0, y: 0) }
            let angle = .pi / 2 + Double(index - 1) * (.pi / 3)
            return Point2D(x: radius * cos(angle), y: radius * sin(angle))
        }
    }
}
