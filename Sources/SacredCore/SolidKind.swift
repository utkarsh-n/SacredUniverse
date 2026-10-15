import Foundation

public struct Point3D: Codable, Equatable, Hashable, Sendable {
    public var x: Double
    public var y: Double
    public var z: Double

    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }

    public func distance(to other: Point3D) -> Double {
        let dx = x - other.x
        let dy = y - other.y
        let dz = z - other.z
        return sqrt(dx * dx + dy * dy + dz * dz)
    }

    public var radius: Double {
        sqrt(x * x + y * y + z * z)
    }
}

public struct Edge3D: Codable, Equatable, Hashable, Sendable {
    public var a: Int
    public var b: Int

    public init(a: Int, b: Int) {
        self.a = a
        self.b = b
    }
}

public enum SolidKind: String, Codable, CaseIterable, Sendable {
    case tetrahedron
    case cube
    case octahedron
    case dodecahedron
    case icosahedron

    public var label: String {
        switch self {
        case .tetrahedron: "Tetrahedron"
        case .cube: "Cube"
        case .octahedron: "Octahedron"
        case .dodecahedron: "Dodecahedron"
        case .icosahedron: "Icosahedron"
        }
    }

    public var vertexCount: Int {
        switch self {
        case .tetrahedron: 4
        case .cube: 8
        case .octahedron: 6
        case .dodecahedron: 20
        case .icosahedron: 12
        }
    }

    public var edgeCount: Int {
        switch self {
        case .tetrahedron: 6
        case .cube, .octahedron: 12
        case .dodecahedron, .icosahedron: 30
        }
    }

    public var faceCount: Int {
        switch self {
        case .tetrahedron: 4
        case .cube: 6
        case .octahedron: 8
        case .dodecahedron: 12
        case .icosahedron: 20
        }
    }

    public var faceSides: Int {
        switch self {
        case .tetrahedron, .octahedron, .icosahedron: 3
        case .cube: 4
        case .dodecahedron: 5
        }
    }

    /// Sum of the planar interior angles across all faces, in degrees.
    /// This is distinct from a solid angle, which is measured in steradians.
    public var totalFaceAngles: Double {
        Double(faceCount) * SacredMath.polygonInteriorSum(sides: faceSides)
    }

    /// Real regular-solid vertices normalized to a common circumradius of one.
    public var vertices: [Point3D] {
        let points: [Point3D]
        switch self {
        case .tetrahedron:
            points = [
                Point3D(x: 1, y: 1, z: 1),
                Point3D(x: 1, y: -1, z: -1),
                Point3D(x: -1, y: 1, z: -1),
                Point3D(x: -1, y: -1, z: 1)
            ]
        case .cube:
            points = Self.cubeVertices
        case .octahedron:
            points = [
                Point3D(x: 1, y: 0, z: 0), Point3D(x: -1, y: 0, z: 0),
                Point3D(x: 0, y: 1, z: 0), Point3D(x: 0, y: -1, z: 0),
                Point3D(x: 0, y: 0, z: 1), Point3D(x: 0, y: 0, z: -1)
            ]
        case .dodecahedron:
            let phi = (1 + sqrt(5.0)) / 2
            points = Self.cubeVertices + Self.cyclicVertices(short: 1 / phi, long: phi)
        case .icosahedron:
            let phi = (1 + sqrt(5.0)) / 2
            points = Self.cyclicVertices(short: 1, long: phi)
        }
        return points.map { point in
            let radius = point.radius
            return Point3D(x: point.x / radius, y: point.y / radius, z: point.z / radius)
        }
    }

    /// Unique undirected edges, found by the smallest vertex separation.
    public var edges: [Edge3D] {
        let points = vertices
        var nearestDistance = Double.infinity
        for a in points.indices {
            for b in (a + 1)..<points.count {
                nearestDistance = min(nearestDistance, points[a].distance(to: points[b]))
            }
        }
        let tolerance = nearestDistance * 1e-8
        var result: [Edge3D] = []
        for a in points.indices {
            for b in (a + 1)..<points.count {
                if abs(points[a].distance(to: points[b]) - nearestDistance) < tolerance {
                    result.append(Edge3D(a: a, b: b))
                }
            }
        }
        return result
    }

    private static var cubeVertices: [Point3D] {
        [-1.0, 1.0].flatMap { x in
            [-1.0, 1.0].flatMap { y in
                [-1.0, 1.0].map { z in Point3D(x: x, y: y, z: z) }
            }
        }
    }

    private static func cyclicVertices(short: Double, long: Double) -> [Point3D] {
        [-1.0, 1.0].flatMap { a in
            [-1.0, 1.0].flatMap { b in
                [
                    Point3D(x: 0, y: a * short, z: b * long),
                    Point3D(x: a * short, y: b * long, z: 0),
                    Point3D(x: a * long, y: 0, z: b * short)
                ]
            }
        }
    }
}
