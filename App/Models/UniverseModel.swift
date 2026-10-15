import Foundation
import Observation
import SacredCore

enum LabKind: String, CaseIterable, Codable, Identifiable {
    case circle, time, roots, polygons, solids, precession, scale, pyramid
    var id: String { rawValue }
    var index: Int { Self.allCases.firstIndex(of: self)! + 1 }
    var title: String {
        switch self {
        case .circle: "A circle, many languages"
        case .time: "The architecture of a day"
        case .roots: "The return to nine"
        case .polygons: "A shape made of triangles"
        case .solids: "Five perfect worlds"
        case .precession: "The great year"
        case .scale: "Near, far, almost the same"
        case .pyramid: "A circle inside a pyramid"
        }
    }
    var shortTitle: String {
        switch self {
        case .circle: "The circle"
        case .time: "Time"
        case .roots: "Number"
        case .polygons: "Shape"
        case .solids: "Solids"
        case .precession: "Cycles"
        case .scale: "Scale"
        case .pyramid: "Proportion"
        }
    }
    var symbol: String {
        switch self {
        case .circle: "circle.dotted"
        case .time: "clock"
        case .roots: "number"
        case .polygons: "hexagon"
        case .solids: "cube.transparent"
        case .precession: "globe.europe.africa"
        case .scale: "moonphase.full.moon"
        case .pyramid: "pyramid"
        }
    }
    var subtitle: String {
        switch self {
        case .circle: "Turn the angle. Change the language."
        case .time: "One day, three ways of counting."
        case .roots: "Follow the digits. Then change the base."
        case .polygons: "Find the triangles hiding in a polygon."
        case .solids: "Hold a world. Discover what stays constant."
        case .precession: "Scrub millennia across a slow celestial wheel."
        case .scale: "Let the Moon move. Watch the ratio breathe."
        case .pyramid: "Tune a height. Compare two perimeters."
        }
    }
    var prompt: String {
        switch self {
        case .circle: "Drag the glowing point, then switch from degrees to radians."
        case .time: "Move the hours dial and watch minutes and seconds grow together."
        case .roots: "Try a multiple of 9. Switch to base 8 and follow its digits again."
        case .polygons: "Add a side. Count how many new triangles you create."
        case .solids: "Turn the solid with your finger, then choose a different one."
        case .precession: "Move the year dial. Compare the symbolic and approximate models."
        case .scale: "Move the Moon from near to far. Compare apparent size and distance."
        case .pyramid: "Adjust the height until the square perimeter meets the circle."
        }
    }
    var insight: String {
        switch self {
        case .circle: "A turn is a geometric relationship. 360°, 2π radians, and 1 turn describe the same motion. The numeral changes with the unit."
        case .time: "Hours, minutes, and seconds scale the same duration. The familiar 9 in 86,400 comes from how we divide a day and write numbers."
        case .roots: "In base 10, 10 leaves a remainder of 1 when divided by 9. So a number and its digit sum have the same remainder. Positive multiples of 9 reduce to 9. In base 8, the analogous number is 7."
        case .polygons: "A convex polygon with n sides splits into n − 2 triangles from one vertex. Each triangle contributes 180°, so the total is (n − 2) × 180°."
        case .solids: "For each of these convex polyhedra, vertices − edges + faces = 2. Their face-angle totals also reduce to 9 when written in decimal degrees. These are two different mathematical relationships."
        case .precession: "Earth's spin axis slowly traces a cone. The video's 25,920-year cycle gives exactly 72 years per degree. An approximate 25,772-year model gives about 71.59; the rate changes over time."
        case .scale: "Distance divided by diameter is a ratio that survives changing units. The Sun is roughly 108 diameters away. The Moon ranges around 105–117, so the resemblance is approximate and varies."
        case .pyramid: "With a base near 230.4 m and an original height near 146.6 m, a square perimeter and a circle's circumference nearly agree. Rounded dimensions make a close proportion, rather than an exact identity."
        }
    }
    var category: String {
        switch self {
        case .circle, .time: "UNIT CONVENTION"
        case .roots, .polygons, .solids: "MATHEMATICAL RELATIONSHIP"
        case .precession, .scale: "APPROXIMATE ASTRONOMY"
        case .pyramid: "GEOMETRIC COMPARISON"
        }
    }
    var videoSeconds: Int {
        switch self {
        case .circle: 246
        case .time: 113
        case .roots: 303
        case .polygons: 354
        case .solids: 446
        case .precession: 774
        case .scale: 6505
        case .pyramid: 3676
        }
    }
}

enum LearningPhase: String, Codable, CaseIterable {
    case observe, experiment, predict, explain, complete
    var label: String {
        switch self {
        case .observe: "Notice"
        case .experiment: "Explore"
        case .predict: "Predict"
        case .explain: "Understand"
        case .complete: "Discovered"
        }
    }
    var index: Int { Self.allCases.firstIndex(of: self)! }
}

struct LabParameters: Codable, Equatable {
    var number = 360
    var base = 10
    var angle = 360.0
    var unit = AngleUnit.degrees
    var sides = 6
    var solid = SolidKind.tetrahedron
    var yaw = 0.35
    var pitch = 0.25
    var hours = 24.0
    var years = 0.0
    var idealized = true
    var moonDistance = 384_400.0
    var pyramidHeight = 146.6
}

struct Prediction: Codable {
    let question: String
    let choices: [String]
    let correct: Int
    let explanation: String
}

struct LabProgress: Codable {
    var phase = LearningPhase.observe
    var interacted = false
    var prediction: Prediction?
    var selectedAnswer: Int?
    var discoveredAt: Date?
    var reflection = ""
}

private struct UniverseArchive: Codable {
    var version = 1
    var selected = LabKind.circle
    var parameters: [String: LabParameters] = [:]
    var progress: [String: LabProgress] = [:]
}

@MainActor @Observable
final class UniverseModel {
    private var archive = UniverseArchive()
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var saveTask: Task<Void, Never>?
    @ObservationIgnored private var preserveUnreadableSave = false
    @ObservationIgnored let feedback = UniverseFeedback()
    var running = false
    var soundEnabled: Bool { didSet { defaults.set(soundEnabled, forKey: "sound"); feedback.soundEnabled = soundEnabled } }
    var hapticsEnabled: Bool { didSet { defaults.set(hapticsEnabled, forKey: "haptics"); feedback.hapticsEnabled = hapticsEnabled } }
    var restorationNotice: String?

    init() {
        let args = ProcessInfo.processInfo.arguments
        let testing = args.contains("--ui-testing")
        defaults = testing ? UserDefaults(suiteName: "com.utkarsh.sacreduniverse.uitesting")! : .standard
        if args.contains("--reset-progress") && testing { defaults.removePersistentDomain(forName: "com.utkarsh.sacreduniverse.uitesting") }
        soundEnabled = defaults.object(forKey: "sound") as? Bool ?? false
        hapticsEnabled = defaults.object(forKey: "haptics") as? Bool ?? true
        feedback.soundEnabled = soundEnabled
        feedback.hapticsEnabled = hapticsEnabled
        if let data = defaults.data(forKey: "universe.v1") {
            if let loaded = try? JSONDecoder().decode(UniverseArchive.self, from: data), loaded.version == 1 {
                archive = loaded
            } else {
                preserveUnreadableSave = true
                restorationNotice = "Your saved session could not be read. A recovery copy is retained locally while you begin a fresh exploration."
            }
        }
    }

    var selected: LabKind { archive.selected }
    var parameters: LabParameters { archive.parameters[selected.rawValue] ?? LabParameters() }
    var progress: LabProgress { progress(for: selected) }
    var discovered: [LabKind] { LabKind.allCases.filter { progress(for: $0).discoveredAt != nil } }
    var nextUndiscovered: LabKind { LabKind.allCases.first { progress(for: $0).discoveredAt == nil } ?? .circle }
    func progress(for kind: LabKind) -> LabProgress { archive.progress[kind.rawValue] ?? LabProgress() }
    func parameters(for kind: LabKind) -> LabParameters { archive.parameters[kind.rawValue] ?? LabParameters() }

    func select(_ kind: LabKind) { stop(); archive.selected = kind; markMutation(); persist(); feedback.tick() }

    func update(_ change: (inout LabParameters) -> Void, userInitiated: Bool = true) {
        var values = parameters
        change(&values)
        values.yaw = atan2(sin(values.yaw), cos(values.yaw))
        values.pitch = min(1.48, max(-1.48, values.pitch))
        guard values != parameters else { return }
        markMutation()
        if userInitiated { running = false }
        archive.parameters[selected.rawValue] = values
        if userInitiated || running {
            var state = progress
            if !state.interacted { feedback.tick() }
            state.interacted = true
            if state.phase != .experiment {
                state.phase = .experiment; state.prediction = nil; state.selectedAnswer = nil
            }
            archive.progress[selected.rawValue] = state
        }
        scheduleSave()
    }

    func begin() {
        setProgress { $0.phase = .experiment }
        feedback.tick()
    }

    func predict() {
        guard progress.interacted else { return }
        stop()
        let question = makePrediction()
        setProgress { $0.prediction = question; $0.selectedAnswer = nil; $0.phase = .predict }
        feedback.tick()
    }

    func answer(_ choice: Int) {
        guard progress.phase == .predict, let question = progress.prediction, question.choices.indices.contains(choice) else { return }
        setProgress { $0.selectedAnswer = choice; if choice == question.correct { $0.phase = .explain } }
        feedback.result(correct: choice == question.correct)
    }

    func discover() {
        guard progress.phase == .explain else { return }
        let first = progress.discoveredAt == nil
        setProgress { $0.phase = .complete; if $0.discoveredAt == nil { $0.discoveredAt = Date() } }
        if first { feedback.discovery() }
    }

    func replay() { stop(); setProgress { $0.phase = .experiment; $0.prediction = nil; $0.selectedAnswer = nil } }
    func reflect(_ text: String) { setProgress { $0.reflection = String(text.prefix(4_000)) } }
    func stop() { running = false; feedback.stop() }
    func toggleRunning() {
        running.toggle()
        if running && progress.phase != .complete {
            setProgress { $0.phase = .experiment; $0.prediction = nil; $0.selectedAnswer = nil }
        }
        feedback.tick()
    }

    func advance(_ dt: Double) {
        guard running else { return }
        update({ p in
            switch selected {
            case .circle: p.angle = (p.angle + dt * 32).truncatingRemainder(dividingBy: 360)
            case .solids: p.yaw += dt * 0.38
            case .time: p.hours = (p.hours + dt * 1.5).truncatingRemainder(dividingBy: 24)
            case .precession: p.years = (p.years + dt * 900).truncatingRemainder(dividingBy: p.idealized ? 25_920 : 25_772)
            default: break
            }
        }, userInitiated: false)
    }

    func persist() {
        saveTask?.cancel()
        guard !preserveUnreadableSave else { return }
        guard let data = try? JSONEncoder().encode(archive) else { return }
        defaults.set(data, forKey: "universe.v1")
    }
    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(250)) } catch { return }
            self?.persist()
        }
    }
    private func setProgress(_ change: (inout LabProgress) -> Void) {
        markMutation()
        var value = progress; change(&value); archive.progress[selected.rawValue] = value; persist()
    }
    private func markMutation() {
        if preserveUnreadableSave {
            if let original = defaults.data(forKey: "universe.v1") { defaults.set(original, forKey: "universe.recovery") }
            preserveUnreadableSave = false
        }
    }

    private func makePrediction() -> Prediction {
        let p = parameters
        switch selected {
        case .circle:
            return Prediction(question: "How many radians make one complete turn?", choices: ["π", "2π", "360"], correct: 1, explanation: "Radians measure arc length divided by radius. A circumference is 2π radii long.")
        case .time:
            return Prediction(question: "How many minutes are in a 24-hour day?", choices: ["1,440", "2,400", "864"], correct: 0, explanation: "24 × 60 = 1,440 minutes. Another factor of 60 gives 86,400 seconds.")
        case .roots:
            let result = SacredMath.digitalRoot(p.number, base: p.base)
            let wrongA = result == 1 ? 2 : 1
            let wrongB = result == 3 ? 4 : 3
            let digits = [wrongA, result, wrongB].map { String($0, radix: p.base).uppercased() }
            return Prediction(question: "Reduce \(String(p.number, radix: p.base).uppercased()) in base \(p.base). Which final digit remains?", choices: digits, correct: 1, explanation: "Add the written digits repeatedly until one digit remains. In base \(p.base), this preserves the remainder modulo \(p.base - 1).")
        case .polygons:
            let sum = Int(SacredMath.polygonInteriorSum(sides: p.sides))
            return Prediction(question: "What is the interior-angle sum of your \(p.sides)-sided polygon?", choices: ["\(sum + 180)°", "\(sum - 180)°", "\(sum)°"], correct: 2, explanation: "The fan contains \(p.sides - 2) triangles. \(p.sides - 2) × 180° = \(sum)°.")
        case .solids:
            return Prediction(question: "For the \(p.solid.label.lowercased()), what is V − E + F?", choices: ["0", "2", "9"], correct: 1, explanation: "\(p.solid.vertexCount) − \(p.solid.edgeCount) + \(p.solid.faceCount) = 2. This is Euler's relationship for convex polyhedra.")
        case .precession:
            return Prediction(question: "In the symbolic 25,920-year model, how long does a 1° shift take?", choices: ["60 years", "72 years", "360 years"], correct: 1, explanation: "25,920 ÷ 360 = 72. A measured model is approximate and gives a slightly different rate.")
        case .scale:
            return Prediction(question: "As the Moon moves farther away, its apparent disk…", choices: ["gets smaller", "stays the same", "gets bigger"], correct: 0, explanation: "Its physical diameter stays the same, while the distance increases. Angular diameter therefore decreases.")
        case .pyramid:
            return Prediction(question: "Keep the square base fixed. If the height rises, the circle's circumference…", choices: ["shrinks", "stays the same", "grows"], correct: 2, explanation: "The circle uses height as its radius. C = 2πh grows directly with h, while the square perimeter stays fixed.")
        }
    }
}
