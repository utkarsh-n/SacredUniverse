import Foundation
import XCTest
@testable import SacredCore

final class SacredCoreTests: XCTestCase {
    func testDecimalDigitalRootsAndReductionSequence() {
        XCTAssertEqual(SacredMath.digitalRoot(0), 0)
        XCTAssertEqual(SacredMath.digitalRoot(9), 9)
        XCTAssertEqual(SacredMath.digitalRoot(72), 9)
        XCTAssertEqual(SacredMath.digitalRoot(86_400), 9)
        XCTAssertEqual(SacredMath.digitReductionSteps(86_400), [86_400, 18, 9])
        XCTAssertEqual(SacredMath.digitReductionSteps(999), [999, 27, 9])
    }

    func testDigitalRootDependsOnNumeralBase() {
        XCTAssertEqual(SacredMath.digitalRoot(360, base: 10), 9)
        XCTAssertEqual(SacredMath.digitalRoot(360, base: 8), 3)
        XCTAssertEqual(SacredMath.digitReductionSteps(360, base: 8), [360, 10, 3])
        XCTAssertEqual(SacredMath.digitalRoot(360, base: 2), 1)
        XCTAssertEqual(SacredMath.digitalRoot(360, base: 16), 15)
        XCTAssertEqual(SacredMath.digitalRoot(86_400, base: 8), 6)
    }

    func testDigitalRootMatchesRepeatedSumForManyValuesAndBases() {
        for base in [2, 3, 8, 10, 16, 36] {
            for number in stride(from: 0, through: 10_000, by: 37) {
                XCTAssertEqual(
                    SacredMath.digitalRoot(number, base: base),
                    SacredMath.digitReductionSteps(number, base: base).last,
                    "number \(number), base \(base)"
                )
            }
        }
    }

    func testNegativeAndExtremeIntegersDoNotOverflow() {
        XCTAssertEqual(SacredMath.digitalRoot(-999), 9)
        XCTAssertEqual(SacredMath.digitReductionSteps(-999), [-999, 27, 9])
        XCTAssertEqual(SacredMath.digitReductionSteps(-4), [-4, 4])
        XCTAssertEqual(SacredMath.digitalRoot(Int.min), 8)
        XCTAssertEqual(SacredMath.digitReductionSteps(Int.min), [Int.min, 89, 17, 8])
        XCTAssertEqual(SacredMath.digitalRoot(Int.max), 7)
        XCTAssertEqual(SacredMath.digitalRoot(Int.max, base: Int.max), 1)
        XCTAssertEqual(SacredMath.digitalRoot(Int.min, base: Int.max), 2)
    }

    func testInvalidArithmeticBases() {
        for base in [-1, 0, 1] {
            XCTAssertEqual(SacredMath.digitalRoot(360, base: base), 0)
            XCTAssertTrue(SacredMath.digitReductionSteps(360, base: base).isEmpty)
        }
    }

    func testPolygonInteriorAngles() {
        XCTAssertEqual(SacredMath.polygonInteriorSum(sides: 3), 180)
        XCTAssertEqual(SacredMath.polygonInteriorSum(sides: 4), 360)
        XCTAssertEqual(SacredMath.polygonInteriorSum(sides: 5), 540)
        XCTAssertEqual(SacredMath.polygonInteriorSum(sides: 12), 1_800)
        XCTAssertEqual(SacredMath.polygonInteriorAngle(sides: 3), 60)
        XCTAssertEqual(SacredMath.polygonInteriorAngle(sides: 6), 120)
        XCTAssertEqual(SacredMath.polygonInteriorAngle(sides: 12), 150)
    }

    func testSamePolygonHasDifferentNumericalSumInDifferentUnits() {
        let degrees = SacredMath.polygonInteriorSum(sides: 5)
        XCTAssertEqual(AngleUnit.degrees.value(fromDegrees: degrees), 540)
        XCTAssertEqual(AngleUnit.radians.value(fromDegrees: degrees), 3 * .pi, accuracy: 1e-12)
        XCTAssertEqual(AngleUnit.turns.value(fromDegrees: degrees), 1.5, accuracy: 1e-12)
        XCTAssertEqual(AngleUnit.radians.value(fromDegrees: 360), 2 * .pi, accuracy: 1e-12)
        XCTAssertEqual(AngleUnit.turns.value(fromDegrees: 360), 1)
    }

    func testPolygonVerticesAreRegularAndStartAtTop() {
        for sides in 3...40 {
            let points = SacredMath.regularPolygon(sides: sides)
            XCTAssertEqual(points.count, sides)
            XCTAssertEqual(points[0].x, 0, accuracy: 1e-12)
            XCTAssertEqual(points[0].y, 1, accuracy: 1e-12)
            let expectedEdge = 2 * sin(.pi / Double(sides))
            for index in points.indices {
                let next = points[(index + 1) % sides]
                XCTAssertEqual(hypot(points[index].x, points[index].y), 1, accuracy: 1e-12)
                XCTAssertEqual(hypot(points[index].x - next.x, points[index].y - next.y), expectedEdge, accuracy: 1e-12)
            }
        }
    }

    func testInvalidAndHugePolygonCountsAreBounded() {
        for sides in [Int.min, -1, 0, 1, 2] {
            XCTAssertEqual(SacredMath.polygonInteriorSum(sides: sides), 0)
            XCTAssertEqual(SacredMath.polygonInteriorAngle(sides: sides), 0)
            XCTAssertTrue(SacredMath.regularPolygon(sides: sides).isEmpty)
        }
        XCTAssertTrue(SacredMath.polygonInteriorSum(sides: Int.max).isFinite)
        XCTAssertEqual(SacredMath.regularPolygon(sides: Int.max).count, SacredMath.maximumPointCount)
    }

    func testModularTimesTable() {
        let table = SacredMath.timesTable(multiplier: 2, modulus: 10)
        XCTAssertEqual(table.map(\.0), Array(0..<10))
        XCTAssertEqual(table.map(\.1), [0, 2, 4, 6, 8, 0, 2, 4, 6, 8])
        XCTAssertEqual(SacredMath.timesTable(multiplier: -1, modulus: 5).map(\.1), [0, 4, 3, 2, 1])
        XCTAssertEqual(SacredMath.timesTable(multiplier: 0, modulus: 7).map(\.1), Array(repeating: 0, count: 7))
        XCTAssertEqual(SacredMath.timesTable(multiplier: Int.min, modulus: 1).map(\.1), [0])
    }

    func testTimesTableBoundsAndExtremeMultipliers() {
        XCTAssertTrue(SacredMath.timesTable(multiplier: 2, modulus: 0).isEmpty)
        XCTAssertTrue(SacredMath.timesTable(multiplier: 2, modulus: -10).isEmpty)
        let table = SacredMath.timesTable(multiplier: Int.min, modulus: Int.max)
        XCTAssertEqual(table.count, SacredMath.maximumPointCount)
        XCTAssertTrue(table.allSatisfy { $0.0 >= 0 && $0.1 >= 0 && $0.1 < table.count })
    }

    func testPrecessionUsesApproximateMeasuredPeriodRatherThanExact72Years() {
        let degreesIn72Years = SacredMath.precessionDegrees(years: 72)
        XCTAssertEqual(degreesIn72Years, 1.005742666459724, accuracy: 1e-12)
        XCTAssertNotEqual(degreesIn72Years, 1, accuracy: 1e-4)
        XCTAssertEqual(SacredMath.precessionDegrees(years: 25_772), 360, accuracy: 1e-12)
        XCTAssertEqual(SacredMath.precessionDegrees(years: 51_544), 720, accuracy: 1e-12)
        XCTAssertEqual(SacredMath.precessionDegrees(years: -25_772), -360, accuracy: 1e-12)
        XCTAssertEqual(SacredMath.precessionDegrees(years: 72, period: 25_920), 1, accuracy: 1e-12)
        XCTAssertEqual(SacredMath.arcsecondsPerYear(period: 25_772), 50.28713332298618, accuracy: 1e-10)
    }

    func testPrecessionRejectsInvalidInputs() {
        for period in [0.0, -1, Double.infinity, Double.nan] {
            XCTAssertEqual(SacredMath.precessionDegrees(years: 72, period: period), 0)
            XCTAssertEqual(SacredMath.arcsecondsPerYear(period: period), 0)
        }
        XCTAssertEqual(SacredMath.precessionDegrees(years: .infinity), 0)
        XCTAssertEqual(SacredMath.precessionDegrees(years: .nan), 0)
    }

    func testDayConstantAndCircleSeed() {
        XCTAssertEqual(SacredMath.secondsPerDay, 24 * 60 * 60)
        let points = SacredMath.circles(seedCount: 7, radius: 2)
        XCTAssertEqual(points.count, 7)
        XCTAssertEqual(points[0], Point2D(x: 0, y: 0))
        XCTAssertEqual(points[1].x, 0, accuracy: 1e-12)
        XCTAssertEqual(points[1].y, 2, accuracy: 1e-12)
        for index in 1..<7 {
            XCTAssertEqual(hypot(points[index].x, points[index].y), 2, accuracy: 1e-12)
            let next = points[index == 6 ? 1 : index + 1]
            XCTAssertEqual(hypot(points[index].x - next.x, points[index].y - next.y), 2, accuracy: 1e-12)
        }
    }

    func testCircleSeedBoundsAndInvalidRadius() {
        XCTAssertEqual(SacredMath.circles(seedCount: Int.min).count, 1)
        XCTAssertEqual(SacredMath.circles(seedCount: Int.max).count, 7)
        for radius in [0.0, -1, Double.infinity, Double.nan] {
            XCTAssertTrue(SacredMath.circles(seedCount: 7, radius: radius).isEmpty)
        }
    }

    func testAllRegularSolidMeshesHaveCorrectCountsAndEqualEdges() {
        for solid in SolidKind.allCases {
            let points = solid.vertices
            let edges = solid.edges
            XCTAssertEqual(points.count, solid.vertexCount, solid.label)
            XCTAssertEqual(edges.count, solid.edgeCount, solid.label)
            XCTAssertEqual(Set(points).count, points.count, solid.label)
            XCTAssertEqual(Set(edges).count, edges.count, solid.label)
            let edgeLength = points[edges[0].a].distance(to: points[edges[0].b])
            for point in points {
                XCTAssertEqual(point.radius, 1, accuracy: 1e-12, solid.label)
            }
            for edge in edges {
                XCTAssertTrue(points.indices.contains(edge.a), solid.label)
                XCTAssertTrue(points.indices.contains(edge.b), solid.label)
                XCTAssertLessThan(edge.a, edge.b, solid.label)
                XCTAssertEqual(points[edge.a].distance(to: points[edge.b]), edgeLength, accuracy: 1e-12, solid.label)
            }
        }
    }

    func testAllRegularSolidsHaveEulerCharacteristicTwo() {
        for solid in SolidKind.allCases {
            XCTAssertEqual(solid.vertexCount - solid.edgeCount + solid.faceCount, 2, solid.label)
            XCTAssertEqual(solid.faceCount * solid.faceSides, 2 * solid.edgeCount, solid.label)
            let degrees = solid.vertices.indices.map { vertex in
                solid.edges.filter { $0.a == vertex || $0.b == vertex }.count
            }
            XCTAssertEqual(Set(degrees).count, 1, solid.label)
        }
    }

    func testAllRegularSolidsHaveExpectedFaceAngleTotals() {
        let expected: [SolidKind: Double] = [
            .tetrahedron: 720, .cube: 2_160, .octahedron: 1_440,
            .dodecahedron: 6_480, .icosahedron: 3_600
        ]
        for solid in SolidKind.allCases {
            XCTAssertEqual(solid.totalFaceAngles, expected[solid])
            XCTAssertEqual(SacredMath.digitalRoot(Int(solid.totalFaceAngles)), 9)
        }
    }

    func testCodableModelsRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let point = Point3D(x: 0.2, y: -0.3, z: 0.9)
        XCTAssertEqual(try decoder.decode(Point3D.self, from: encoder.encode(point)), point)
        let point2 = Point2D(x: 0.5, y: -0.7)
        XCTAssertEqual(try decoder.decode(Point2D.self, from: encoder.encode(point2)), point2)
        let edge = Edge3D(a: 2, b: 7)
        XCTAssertEqual(try decoder.decode(Edge3D.self, from: encoder.encode(edge)), edge)
        XCTAssertEqual(try decoder.decode(SolidKind.self, from: encoder.encode(SolidKind.icosahedron)), .icosahedron)
        XCTAssertEqual(try decoder.decode(AngleUnit.self, from: encoder.encode(AngleUnit.radians)), .radians)
    }
}
