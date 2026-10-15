import SwiftUI
import SacredCore

/// A quiet, directly manipulable instrument. All motion comes from the shared lab parameters.
struct SacredStage: View {
    let kind: LabKind
    let parameters: LabParameters
    var onAngleChange: ((Double) -> Void)? = nil
    var onRotation: ((Double, Double) -> Void)? = nil

    @State private var rotationOrigin: (yaw: Double, pitch: Double)?

    @ViewBuilder var body: some View {
        let scene = drawing
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilitySummary)
            .accessibilityIdentifier("sacredStage")

        if kind == .circle, let onAngleChange {
            scene
                .accessibilityHint("Drag the glowing point around the circle, or use the Angle control.")
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment: onAngleChange(min(360, parameters.angle + 5))
                    case .decrement: onAngleChange(max(0, parameters.angle - 5))
                    @unknown default: break
                    }
                }
        } else if kind == .solids, let onRotation {
            scene
                .accessibilityHint("Drag to rotate the solid, or use the rotation controls.")
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment: onRotation(parameters.yaw + .pi / 12, parameters.pitch)
                    case .decrement: onRotation(parameters.yaw - .pi / 12, parameters.pitch)
                    @unknown default: break
                    }
                }
        } else {
            scene
        }
    }

    private var drawing: some View {
        GeometryReader { geometry in
            Canvas { original, size in
                var context = original
                drawField(in: &context, size: size)
                switch kind {
                case .roots: drawRoots(in: &context, size: size)
                case .circle: drawCircle(in: &context, size: size)
                case .polygons: drawPolygon(in: &context, size: size)
                case .solids: drawSolid(in: &context, size: size)
                case .time: drawTime(in: &context, size: size)
                case .precession: drawPrecession(in: &context, size: size)
                case .scale: drawScale(in: &context, size: size)
                case .pyramid: drawPyramid(in: &context, size: size)
                }
            }
            .contentShape(Rectangle())
            .gesture(directManipulation(size: geometry.size),
                     including: (kind == .circle || kind == .solids) ? .all : .none)
        }
        .aspectRatio(1.15, contentMode: .fit)
        .background(Ink.bg, in: RoundedRectangle(cornerRadius: 28))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(Ink.gold.opacity(0.14), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .onChange(of: kind) { _, _ in rotationOrigin = nil }
    }

    private func directManipulation(size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                switch kind {
                case .circle:
                    let center = CGPoint(x: size.width / 2, y: size.height * 0.47)
                    let dx = value.location.x - center.x
                    let dy = center.y - value.location.y
                    guard hypot(dx, dy) > 18 else { return }
                    let degrees = atan2(dy, dx) * 180 / .pi
                    onAngleChange?(degrees < 0 ? degrees + 360 : degrees)
                case .solids:
                    if rotationOrigin == nil {
                        rotationOrigin = (parameters.yaw, parameters.pitch)
                    }
                    if let origin = rotationOrigin {
                        onRotation?(origin.yaw + value.translation.width * 0.009,
                                    min(1.48, max(-1.48, origin.pitch - value.translation.height * 0.007)))
                    }
                default: break
                }
            }
            .onEnded { _ in rotationOrigin = nil }
    }

    private func drawField(in context: inout GraphicsContext, size: CGSize) {
        let bounds = CGRect(origin: .zero, size: size)
        context.fill(Path(bounds), with: .linearGradient(
            Gradient(colors: [Ink.panel.opacity(0.7), Ink.bg]),
            startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))

        for index in 0..<58 {
            let x = CGFloat(pseudoRandom(index * 3 + 1)) * size.width
            let y = CGFloat(pseudoRandom(index * 3 + 2)) * size.height
            let radius: CGFloat = index % 11 == 0 ? 1.2 : 0.55
            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)),
                         with: .color(Ink.text.opacity(index % 11 == 0 ? 0.32 : 0.13)))
        }
        let center = CGPoint(x: size.width / 2, y: size.height * 0.47)
        let glowRadius = size.width * 0.5
        context.fill(Path(ellipseIn: CGRect(x: center.x - glowRadius, y: center.y - glowRadius,
                                           width: glowRadius * 2, height: glowRadius * 2)),
                     with: .radialGradient(Gradient(colors: [Ink.gold.opacity(0.065), .clear]),
                                           center: center, startRadius: 0, endRadius: glowRadius))
        var horizontal = Path()
        horizontal.move(to: CGPoint(x: 25, y: center.y))
        horizontal.addLine(to: CGPoint(x: size.width - 25, y: center.y))
        var vertical = Path()
        vertical.move(to: CGPoint(x: center.x, y: 24))
        vertical.addLine(to: CGPoint(x: center.x, y: size.height - 24))
        context.stroke(horizontal, with: .color(Ink.text.opacity(0.035)), style: StrokeStyle(lineWidth: 0.5, dash: [2, 6]))
        context.stroke(vertical, with: .color(Ink.text.opacity(0.035)), style: StrokeStyle(lineWidth: 0.5, dash: [2, 6]))
    }

    private func drawRoots(in context: inout GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height * 0.43)
        let radius = min(size.width * 0.31, size.height * 0.34)
        let base = max(2, min(parameters.base, 16))
        let count = base - 1
        let root = reduced(parameters.number, base: base)
        ring(center, radius: radius, color: Ink.gold.opacity(0.16), in: &context)
        ring(center, radius: radius * 0.81, color: Ink.gold.opacity(0.055), in: &context)

        let points = (1...count).map { item in
            point(center, radius: radius, angle: -.pi / 2 + Double(item - 1) / Double(count) * 2 * .pi)
        }
        if count > 2 {
            var web = Path()
            for index in points.indices {
                web.move(to: points[index])
                web.addLine(to: points[(index * 2 + 1) % count])
            }
            context.stroke(web, with: .color(Ink.gold.opacity(0.085)), lineWidth: 0.8)
        }
        if root > 0, points.indices.contains(root - 1) {
            let selected = points[root - 1]
            line(center, selected, color: Ink.cyan.opacity(0.6), width: 1.2, in: &context)
            glow(selected, radius: 21, color: Ink.gold, in: &context)
        }
        for (index, node) in points.enumerated() {
            let selected = index + 1 == root
            context.fill(Path(ellipseIn: CGRect(x: node.x - 14, y: node.y - 14, width: 28, height: 28)),
                         with: .color(selected ? Ink.gold : Ink.panel))
            ring(node, radius: 14, color: selected ? Ink.gold : Ink.gold.opacity(0.24), in: &context)
            text(String(index + 1, radix: base).uppercased(), at: node, size: 13,
                 color: selected ? Ink.bg : Ink.muted, in: &context)
        }
        text(String(root, radix: base).uppercased(), at: center, size: 54, color: Ink.gold,
             serif: true, in: &context)
        text("DIGITAL ROOT", at: CGPoint(x: center.x, y: center.y + 36), size: 8,
             color: Ink.muted, in: &context)

        let chain = reductionChain(parameters.number, base: base)
        text(chain.map { String($0, radix: base).uppercased() }.joined(separator: "  →  "),
             at: CGPoint(x: center.x, y: size.height * 0.87), size: 16, color: Ink.cyan, in: &context)
        text("BASE \(base) · REPEATED DIGIT SUM", at: CGPoint(x: center.x, y: size.height * 0.95),
             size: 8, color: Ink.muted, in: &context)
    }

    private func drawCircle(in context: inout GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height * 0.47)
        let radius = min(size.width * 0.32, size.height * 0.34)
        let degrees = min(360, max(0, parameters.angle))
        let angle = -degrees * .pi / 180
        ring(center, radius: radius, color: Ink.gold.opacity(0.2), in: &context)
        ring(center, radius: radius * 0.93, color: Ink.gold.opacity(0.06), in: &context)
        for tick in 0..<72 {
            let a = Double(tick) / 72 * 2 * .pi
            let major = tick % 6 == 0
            line(point(center, radius: radius + 7, angle: a),
                 point(center, radius: radius + (major ? 16 : 11), angle: a),
                 color: Ink.gold.opacity(major ? 0.5 : 0.2), width: major ? 1 : 0.65, in: &context)
        }
        for (label, a) in [("0°", 0.0), ("90°", -.pi / 2), ("180°", -.pi), ("270°", -.pi * 1.5)] {
            text(label, at: point(center, radius: radius + 29, angle: a), size: 10,
                 color: Ink.muted, in: &context)
        }
        var sector = Path()
        sector.move(to: center)
        sector.addArc(center: center, radius: radius, startAngle: .zero,
                      endAngle: .degrees(-degrees), clockwise: true)
        sector.closeSubpath()
        context.fill(sector, with: .color(Ink.gold.opacity(0.08)))
        var arc = Path()
        arc.addArc(center: center, radius: radius, startAngle: .zero,
                   endAngle: .degrees(-degrees), clockwise: true)
        context.stroke(arc, with: .color(Ink.gold), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        line(center, point(center, radius: radius, angle: 0), color: Ink.gold.opacity(0.3), in: &context)
        let handle = point(center, radius: radius, angle: angle)
        line(center, handle, color: Ink.cyan.opacity(0.85), width: 1.6, in: &context)
        glow(handle, radius: 20, color: Ink.cyan, in: &context)
        dot(handle, radius: 6, color: Ink.cyan, in: &context)
        dot(center, radius: 3, color: Ink.gold, in: &context)
        let readout: String
        switch parameters.unit {
        case .degrees: readout = String(format: "%.0f°", degrees)
        case .radians: readout = String(format: "%.2f rad", degrees * .pi / 180)
        case .turns: readout = String(format: "%.2f turns", degrees / 360)
        }
        text(readout, at: CGPoint(x: center.x, y: center.y + radius * 0.48),
             size: 26, color: Ink.text, serif: true, in: &context)
        text("ONE TURN · MANY LANGUAGES", at: CGPoint(x: center.x, y: size.height * 0.96),
             size: 8, color: Ink.muted, in: &context)
    }

    private func drawPolygon(in context: inout GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height * 0.44)
        let radius = min(size.width * 0.32, size.height * 0.34)
        let count = max(3, min(12, parameters.sides))
        let points = SacredMath.regularPolygon(sides: count).map {
            CGPoint(x: center.x + $0.x * radius, y: center.y - $0.y * radius)
        }
        ring(center, radius: radius, color: Ink.gold.opacity(0.1), dashed: true, in: &context)
        for index in 1..<(count - 1) {
            var triangle = Path()
            triangle.move(to: points[0]); triangle.addLine(to: points[index])
            triangle.addLine(to: points[index + 1]); triangle.closeSubpath()
            context.fill(triangle, with: .color((index.isMultiple(of: 2) ? Ink.cyan : Ink.gold).opacity(0.06)))
            context.stroke(triangle, with: .color(Ink.cyan.opacity(0.24)), lineWidth: 0.8)
            let centroid = CGPoint(x: (points[0].x + points[index].x + points[index + 1].x) / 3,
                                   y: (points[0].y + points[index].y + points[index + 1].y) / 3)
            text("180°", at: centroid, size: count > 8 ? 8 : 10, color: Ink.cyan.opacity(0.85), in: &context)
        }
        var boundary = Path()
        boundary.addLines(points); boundary.closeSubpath()
        context.stroke(boundary, with: .color(Ink.gold), style: StrokeStyle(lineWidth: 1.8, lineJoin: .round))
        for (index, vertex) in points.enumerated() {
            dot(vertex, radius: index == 0 ? 5 : 3.5, color: index == 0 ? Ink.cyan : Ink.gold, in: &context)
        }
        glow(points[0], radius: 15, color: Ink.cyan, in: &context)
        text("\(count - 2) TRIANGLES", at: CGPoint(x: center.x, y: size.height * 0.85),
             size: 9, color: Ink.muted, in: &context)
        text("\(count - 2) × 180° = \((count - 2) * 180)°", at: CGPoint(x: center.x, y: size.height * 0.94),
             size: 19, color: Ink.gold, serif: true, in: &context)
    }

    private func drawSolid(in context: inout GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height * 0.43)
        let radius = min(size.width * 0.31, size.height * 0.32)
        let vertices = parameters.solid.vertices
        let scale = vertices.map { sqrt($0.x * $0.x + $0.y * $0.y + $0.z * $0.z) }.max() ?? 1
        let yaw = parameters.yaw
        let pitch = parameters.pitch
        let projected: [(point: CGPoint, depth: Double)] = vertices.map { vertex in
            let x = (vertex.x * cos(yaw) + vertex.z * sin(yaw)) / max(scale, 0.001)
            let z = (-vertex.x * sin(yaw) + vertex.z * cos(yaw)) / max(scale, 0.001)
            let y = vertex.y / max(scale, 0.001)
            let turnedY = y * cos(pitch) - z * sin(pitch)
            let turnedZ = y * sin(pitch) + z * cos(pitch)
            let perspective = 3.5 / (3.5 - turnedZ)
            return (CGPoint(x: center.x + x * radius * perspective,
                            y: center.y - turnedY * radius * perspective), turnedZ)
        }
        let shadow = CGRect(x: center.x - radius * 0.7, y: center.y + radius * 0.93,
                            width: radius * 1.4, height: radius * 0.2)
        context.fill(Path(ellipseIn: shadow), with: .radialGradient(
            Gradient(colors: [Ink.gold.opacity(0.12), .clear]), center: CGPoint(x: center.x, y: shadow.midY),
            startRadius: 0, endRadius: radius * 0.8))
        ring(center, radius: radius * 1.12, color: Ink.gold.opacity(0.07), dashed: true, in: &context)
        let edges = parameters.solid.edges.sorted { edgeA, edgeB in
            guard projected.indices.contains(edgeA.a), projected.indices.contains(edgeA.b),
                  projected.indices.contains(edgeB.a), projected.indices.contains(edgeB.b) else { return false }
            return projected[edgeA.a].depth + projected[edgeA.b].depth < projected[edgeB.a].depth + projected[edgeB.b].depth
        }
        for edge in edges {
            guard projected.indices.contains(edge.a), projected.indices.contains(edge.b) else { continue }
            let depth = (projected[edge.a].depth + projected[edge.b].depth) / 2
            let front = depth > 0
            line(projected[edge.a].point, projected[edge.b].point,
                 color: (front ? Ink.gold : Ink.cyan).opacity(0.25 + (depth + 1) * 0.32),
                 width: front ? 1.8 : 0.9, in: &context)
        }
        for vertex in projected.sorted(by: { $0.depth < $1.depth }) {
            dot(vertex.point, radius: vertex.depth > 0 ? 3.7 : 2,
                color: (vertex.depth > 0 ? Ink.gold : Ink.cyan).opacity(0.45 + (vertex.depth + 1) * 0.25), in: &context)
            if vertex.depth > 0.5 { glow(vertex.point, radius: 10, color: Ink.gold.opacity(0.4), in: &context) }
        }
        text("DRAG TO TURN", at: CGPoint(x: center.x, y: size.height * 0.85), size: 8, color: Ink.muted, in: &context)
        text("\(vertices.count) vertices     \(parameters.solid.edges.count) edges",
             at: CGPoint(x: center.x, y: size.height * 0.94), size: 13, color: Ink.cyan, in: &context)
    }

    private func drawTime(in context: inout GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height * 0.45)
        let radius = min(size.width * 0.32, size.height * 0.33)
        let hours = min(24, max(0, parameters.hours))
        ring(center, radius: radius, color: Ink.gold.opacity(0.3), in: &context)
        ring(center, radius: radius * 0.78, color: Ink.cyan.opacity(0.08), in: &context)
        for hour in 0..<24 {
            let a = Double(hour) / 24 * 2 * .pi - .pi / 2
            line(point(center, radius: radius - 8, angle: a), point(center, radius: radius + 3, angle: a),
                 color: Ink.gold.opacity(hour.isMultiple(of: 6) ? 0.75 : 0.35), in: &context)
            if hour.isMultiple(of: 3) {
                text("\(hour)", at: point(center, radius: radius + 20, angle: a), size: 10,
                     color: hour.isMultiple(of: 6) ? Ink.gold : Ink.muted, in: &context)
            }
        }
        var arc = Path()
        arc.addArc(center: center, radius: radius, startAngle: .degrees(-90),
                   endAngle: .degrees(hours * 15 - 90), clockwise: false)
        context.stroke(arc, with: .color(Ink.gold), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        let endpoint = point(center, radius: radius * 0.9, angle: hours / 24 * 2 * .pi - .pi / 2)
        line(center, endpoint, color: Ink.cyan, width: 1.5, in: &context)
        dot(center, radius: 5, color: Ink.gold, in: &context)
        glow(endpoint, radius: 16, color: Ink.cyan, in: &context)
        dot(endpoint, radius: 4, color: Ink.cyan, in: &context)
        text(String(format: "%.0f°", hours * 15), at: CGPoint(x: center.x, y: center.y + radius * 0.46),
             size: 26, color: Ink.text, serif: true, in: &context)
        text("24 HOURS · ONE ROTATION", at: CGPoint(x: center.x, y: size.height * 0.9),
             size: 9, color: Ink.muted, in: &context)
        text("1 h = 15°", at: CGPoint(x: center.x, y: size.height * 0.97), size: 12, color: Ink.cyan, in: &context)
    }

    private func drawPrecession(in context: inout GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height * 0.61)
        let earthRadius = size.width * 0.2
        let period = parameters.idealized ? 25_920.0 : 25_772.0
        let phase = parameters.years / period * 2 * .pi - .pi / 2
        let coneCenter = CGPoint(x: center.x, y: center.y - earthRadius * 1.85)
        let coneRadius = earthRadius * 0.79
        let tip = CGPoint(x: coneCenter.x + cos(phase) * coneRadius,
                          y: coneCenter.y + sin(phase) * coneRadius * 0.34)
        let coneBounds = CGRect(x: coneCenter.x - coneRadius, y: coneCenter.y - coneRadius * 0.34,
                                width: coneRadius * 2, height: coneRadius * 0.68)
        var cone = Path()
        cone.move(to: center)
        cone.addLine(to: CGPoint(x: coneBounds.minX, y: coneCenter.y))
        cone.addLine(to: CGPoint(x: coneBounds.maxX, y: coneCenter.y))
        cone.closeSubpath()
        context.fill(cone, with: .color(Ink.gold.opacity(0.055)))
        context.stroke(Path(ellipseIn: coneBounds), with: .color(Ink.gold.opacity(0.55)),
                       style: StrokeStyle(lineWidth: 1.2, dash: [3, 4]))
        line(center, CGPoint(x: center.x, y: coneCenter.y - 15), color: Ink.muted.opacity(0.3),
             dash: [3, 5], in: &context)
        line(center, tip, color: Ink.gold, width: 2, in: &context)
        let south = CGPoint(x: center.x - (tip.x - center.x) * 0.45,
                            y: center.y - (tip.y - center.y) * 0.45)
        line(center, south, color: Ink.gold.opacity(0.6), width: 1.2, in: &context)

        let earth = CGRect(x: center.x - earthRadius, y: center.y - earthRadius,
                           width: earthRadius * 2, height: earthRadius * 2)
        context.fill(Path(ellipseIn: earth), with: .radialGradient(
            Gradient(colors: [Ink.cyan.opacity(0.24), Ink.cyan.opacity(0.07), Ink.bg]),
            center: CGPoint(x: center.x - earthRadius * 0.45, y: center.y - earthRadius * 0.5),
            startRadius: 0, endRadius: earthRadius * 1.8))
        ring(center, radius: earthRadius, color: Ink.cyan.opacity(0.6), in: &context)
        for offset in [-0.55, 0.0, 0.55] {
            let y = center.y + offset * earthRadius
            let halfWidth = earthRadius * sqrt(1 - offset * offset)
            context.stroke(Path(ellipseIn: CGRect(x: center.x - halfWidth, y: y - 8,
                                                  width: halfWidth * 2, height: 16)),
                           with: .color(Ink.cyan.opacity(0.16)), lineWidth: 0.7)
        }
        for fraction in [0.33, 0.7] {
            context.stroke(Path(ellipseIn: CGRect(x: center.x - earthRadius * fraction,
                                                  y: center.y - earthRadius,
                                                  width: earthRadius * fraction * 2, height: earthRadius * 2)),
                           with: .color(Ink.cyan.opacity(0.13)), lineWidth: 0.7)
        }
        line(center, tip, color: Ink.gold.opacity(0.7), width: 1.6, in: &context)
        glow(tip, radius: 15, color: Ink.gold, in: &context)
        dot(tip, radius: 4, color: Ink.gold, in: &context)
        text("AXIS TRACES A SLOW CIRCLE", at: CGPoint(x: size.width / 2, y: size.height * 0.07),
             size: 8, color: Ink.muted, in: &context)
        text("23.44° tilt", at: CGPoint(x: size.width * 0.79, y: size.height * 0.41),
             size: 10, color: Ink.gold, in: &context)
        text(parameters.idealized ? "25,920 y · idealized" : "≈25,772 y · present estimate",
             at: CGPoint(x: size.width / 2, y: size.height * 0.94), size: 11, color: Ink.cyan, in: &context)
    }

    private func drawScale(in context: inout GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height * 0.39)
        let fieldRadius = size.width * 0.3
        let distance = max(1, parameters.moonDistance)
        let diameter = 2 * atan(3474.8 / (2 * distance)) * 180 / .pi
        let moonRadius = fieldRadius * min(1.4, diameter)
        let sunDiameter = 0.532893
        let sunRadius = fieldRadius * sunDiameter
        ring(center, radius: fieldRadius, color: Ink.gold.opacity(0.16), dashed: true, in: &context)
        let moonBounds = CGRect(x: center.x - moonRadius, y: center.y - moonRadius,
                                width: moonRadius * 2, height: moonRadius * 2)
        context.fill(Path(ellipseIn: moonBounds), with: .radialGradient(
            Gradient(colors: [Ink.text.opacity(0.9), Ink.gold.opacity(0.75), Ink.gold.opacity(0.35)]),
            center: CGPoint(x: center.x - moonRadius * 0.4, y: center.y - moonRadius * 0.45),
            startRadius: 1, endRadius: moonRadius * 1.8))
        for (x, y, r) in [(-0.35, -0.2, 0.18), (0.24, 0.1, 0.25), (-0.2, 0.4, 0.12), (0.32, -0.35, 0.09)] {
            let crater = CGRect(x: center.x + x * moonRadius - r * moonRadius,
                                y: center.y + y * moonRadius - r * moonRadius,
                                width: r * moonRadius * 2, height: r * moonRadius * 2)
            context.fill(Path(ellipseIn: crater), with: .color(Ink.bg.opacity(0.11)))
        }
        // Both sizes use the same one-degree field; the Sun is a fixed reference, not a second disk.
        ring(center, radius: sunRadius, color: Ink.cyan.opacity(0.95), width: 2, in: &context)
        text("SUN OUTLINE ≈0.533°", at: CGPoint(x: center.x, y: size.height * 0.08),
             size: 10, color: Ink.cyan, in: &context)
        let bracketY = center.y + fieldRadius + 15
        dimension(CGPoint(x: center.x - fieldRadius, y: bracketY),
                  CGPoint(x: center.x + fieldRadius, y: bracketY), color: Ink.gold.opacity(0.5), in: &context)
        text("FIXED 1° FIELD OF VIEW", at: CGPoint(x: center.x, y: bracketY + 16),
             size: 8, color: Ink.muted, in: &context)
        let groundY = size.height * 0.87
        var earthArc = Path()
        earthArc.move(to: CGPoint(x: 0, y: groundY + 12))
        earthArc.addQuadCurve(to: CGPoint(x: size.width, y: groundY + 12),
                              control: CGPoint(x: size.width / 2, y: groundY - 12))
        context.stroke(earthArc, with: .color(Ink.cyan.opacity(0.55)), lineWidth: 1.1)
        dot(CGPoint(x: center.x, y: groundY - 2), radius: 3, color: Ink.cyan, in: &context)
        line(CGPoint(x: center.x, y: groundY - 6), CGPoint(x: center.x - moonRadius, y: center.y + moonRadius * 0.4),
             color: Ink.cyan.opacity(0.12), dash: [3, 4], in: &context)
        line(CGPoint(x: center.x, y: groundY - 6), CGPoint(x: center.x + moonRadius, y: center.y + moonRadius * 0.4),
             color: Ink.cyan.opacity(0.12), dash: [3, 4], in: &context)
        text(String(format: "Moon disk %.3f°", diameter), at: CGPoint(x: center.x, y: size.height * 0.95),
             size: 16, color: Ink.gold, serif: true, in: &context)
        text("EARTH OBSERVER", at: CGPoint(x: size.width * 0.79, y: groundY + 4),
             size: 7, color: Ink.cyan, in: &context)
    }

    private func drawPyramid(in context: inout GraphicsContext, size: CGSize) {
        let height = max(1, parameters.pyramidHeight)
        let base = 230.4
        // A single scale keeps the square's width and circle's radius directly comparable.
        let factor = min(size.width * 0.76 / max(base, height * 2), size.height * 0.65 / (height * 2))
        let center = CGPoint(x: size.width / 2, y: size.height * 0.48)
        let groundY = center.y + height * factor * 0.5
        let apex = CGPoint(x: center.x, y: groundY - height * factor)
        let left = CGPoint(x: center.x - base * factor / 2, y: groundY)
        let right = CGPoint(x: center.x + base * factor / 2, y: groundY)
        let circleCenter = CGPoint(x: center.x, y: groundY - height * factor * 0.4)
        let radius = height * factor
        ring(circleCenter, radius: radius, color: Ink.cyan.opacity(0.28), dashed: true, in: &context)
        var triangle = Path()
        triangle.move(to: left); triangle.addLine(to: apex); triangle.addLine(to: right); triangle.closeSubpath()
        context.fill(triangle, with: .linearGradient(Gradient(colors: [Ink.gold.opacity(0.18), Ink.gold.opacity(0.03)]),
                                                    startPoint: apex, endPoint: CGPoint(x: center.x, y: groundY)))
        context.stroke(triangle, with: .color(Ink.gold), style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
        line(apex, CGPoint(x: center.x, y: groundY), color: Ink.gold.opacity(0.65), dash: [3, 4], in: &context)
        line(left, apex, color: Ink.gold.opacity(0.55), dash: [4, 4], in: &context)
        let squareSize: CGFloat = 7
        var rightAngle = Path()
        rightAngle.move(to: CGPoint(x: center.x, y: groundY - squareSize))
        rightAngle.addLine(to: CGPoint(x: center.x + squareSize, y: groundY - squareSize))
        rightAngle.addLine(to: CGPoint(x: center.x + squareSize, y: groundY))
        context.stroke(rightAngle, with: .color(Ink.gold.opacity(0.6)), lineWidth: 0.8)
        dimension(CGPoint(x: left.x, y: groundY + 15), CGPoint(x: right.x, y: groundY + 15),
                  color: Ink.gold.opacity(0.6), in: &context)
        text("230.4 m", at: CGPoint(x: center.x, y: groundY + 30), size: 11, color: Ink.gold, in: &context)
        text(String(format: "h = %.1f m", height), at: CGPoint(x: center.x + 51, y: groundY - height * factor * 0.46),
             size: 10, color: Ink.gold, in: &context)
        let radial = point(circleCenter, radius: radius, angle: -.pi * 0.25)
        line(circleCenter, radial, color: Ink.cyan.opacity(0.65), in: &context)
        dot(circleCenter, radius: 2.5, color: Ink.cyan, in: &context)
        text("r = h", at: CGPoint(x: (circleCenter.x + radial.x) / 2 + 12,
                                 y: (circleCenter.y + radial.y) / 2 - 12),
             size: 11, color: Ink.cyan, in: &context)
        text("SQUARE PERIMETER ↔ CIRCLE CIRCUMFERENCE",
             at: CGPoint(x: center.x, y: size.height * 0.92), size: 7.5, color: Ink.muted, in: &context)
        text("Compare the lengths. Explore the approximation.",
             at: CGPoint(x: center.x, y: size.height * 0.98), size: 8.5, color: Ink.cyan, in: &context)
    }

    private var accessibilitySummary: String {
        switch kind {
        case .roots:
            let base = max(2, min(parameters.base, 16))
            let chain = reductionChain(parameters.number, base: base)
                .map { String($0, radix: base).uppercased() }.joined(separator: ", then ")
            let root = String(reduced(parameters.number, base: base), radix: base).uppercased()
            return "Digit reduction in base \(base). \(chain). Digital root \(root)."
        case .circle:
            return "Circle with a highlighted arc of \(Int(parameters.angle)) degrees, or \(String(format: "%.3f", parameters.angle / 360)) turns."
        case .polygons:
            return "Regular \(parameters.sides)-sided polygon divided into \(parameters.sides - 2) triangles. Interior angle sum \((parameters.sides - 2) * 180) degrees."
        case .solids:
            return "Three dimensional \(parameters.solid.label), with \(parameters.solid.vertices.count) vertices and \(parameters.solid.edges.count) edges. Near edges are brighter."
        case .time:
            return "24-hour rotation dial. \(String(format: "%.1f", parameters.hours)) hours correspond to \(String(format: "%.1f", parameters.hours * 15)) degrees."
        case .precession:
            let period = parameters.idealized ? 25_920.0 : 25_772.0
            return "Earth's tilted axis traces a cone. \(Int(parameters.years)) years of a \(parameters.idealized ? "25,920-year idealized" : "approximately 25,772-year") cycle, or \(String(format: "%.1f", parameters.years / period * 360)) degrees. Tilt 23.44 degrees."
        case .scale:
            let diameter = 2 * atan(3474.8 / (2 * max(1, parameters.moonDistance))) * 180 / .pi
            return "Moon viewed from Earth in a fixed one degree field of view. At \(Int(parameters.moonDistance)) kilometers, its angular diameter is \(String(format: "%.3f", diameter)) degrees. The cyan outline marks the Sun's reference angular diameter of approximately 0.533 degrees on the same scale."
        case .pyramid:
            return "Pyramid cross section with a 230.4-meter base and a \(String(format: "%.1f", parameters.pyramidHeight))-meter height. A comparison circle has radius equal to the height. The perimeter is 921.6 meters; the circumference is \(String(format: "%.1f", 2 * .pi * parameters.pyramidHeight)) meters."
        }
    }
}

/// The homepage emblem shares the lab's seven-circle construction without an animation loop.
struct SacredMandala: View {
    var body: some View {
        Canvas { original, size in
            var context = original
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) * 0.23
            for index in 0..<36 {
                let angle = Double(index) / 36 * 2 * .pi
                let distance = radius * (index.isMultiple(of: 3) ? 2.2 : 2.38)
                let star = point(center, radius: distance, angle: angle)
                dot(star, radius: index.isMultiple(of: 3) ? 1.5 : 0.65,
                    color: Ink.gold.opacity(index.isMultiple(of: 3) ? 0.6 : 0.3), in: &context)
            }
            for index in 0..<6 {
                let seed = point(center, radius: radius, angle: Double(index) / 6 * 2 * .pi - .pi / 2)
                ring(seed, radius: radius, color: Ink.gold.opacity(0.53), width: 0.85, in: &context)
            }
            ring(center, radius: radius, color: Ink.gold.opacity(0.8), width: 0.9, in: &context)
            ring(center, radius: radius * 2, color: Ink.gold.opacity(0.36), width: 0.75, in: &context)
            ring(center, radius: radius * 2.08, color: Ink.gold.opacity(0.13), width: 0.5, in: &context)
            glow(center, radius: radius * 0.35, color: Ink.gold.opacity(0.7), in: &context)
            dot(center, radius: 2, color: Ink.gold, in: &context)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("Seven overlapping golden circles form a flower, held inside a circle of stars.")
    }
}

private func pseudoRandom(_ value: Int) -> Double {
    let raw = sin(Double(value) * 12.9898 + 78.233) * 43758.5453
    return raw - floor(raw)
}

private func point(_ center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
    CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
}

private func ring(_ center: CGPoint, radius: CGFloat, color: Color, width: CGFloat = 1,
                  dashed: Bool = false, in context: inout GraphicsContext) {
    let bounds = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    context.stroke(Path(ellipseIn: bounds), with: .color(color),
                   style: StrokeStyle(lineWidth: width, dash: dashed ? [3, 5] : []))
}

private func line(_ a: CGPoint, _ b: CGPoint, color: Color, width: CGFloat = 1,
                  dash: [CGFloat] = [], in context: inout GraphicsContext) {
    var path = Path(); path.move(to: a); path.addLine(to: b)
    context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, dash: dash))
}

private func dot(_ center: CGPoint, radius: CGFloat, color: Color, in context: inout GraphicsContext) {
    context.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                       width: radius * 2, height: radius * 2)), with: .color(color))
}

private func glow(_ center: CGPoint, radius: CGFloat, color: Color, in context: inout GraphicsContext) {
    context.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                       width: radius * 2, height: radius * 2)),
                 with: .radialGradient(Gradient(colors: [color.opacity(0.3), .clear]),
                                       center: center, startRadius: 0, endRadius: radius))
}

private func text(_ value: String, at position: CGPoint, size: CGFloat, color: Color,
                  serif: Bool = false, in context: inout GraphicsContext) {
    context.draw(Text(value).font(.system(size: size, weight: serif ? .regular : .medium,
                                         design: serif ? .serif : .monospaced)).foregroundStyle(color),
                 at: position, anchor: .center)
}

private func dimension(_ a: CGPoint, _ b: CGPoint, color: Color, in context: inout GraphicsContext) {
    line(a, b, color: color, width: 0.7, in: &context)
    for p in [a, b] {
        line(CGPoint(x: p.x, y: p.y - 4), CGPoint(x: p.x, y: p.y + 4), color: color, width: 0.7, in: &context)
    }
}

private func reduced(_ number: Int, base: Int) -> Int {
    SacredMath.digitalRoot(number, base: base)
}

private func reductionChain(_ number: Int, base: Int) -> [Int] {
    SacredMath.digitReductionSteps(number, base: base)
}
