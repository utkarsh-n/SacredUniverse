import SwiftUI
import SacredCore

struct LaboratoryView: View {
    let model: UniverseModel
    let initial: LabKind
    let showSource: (LabKind) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    private var lab: LabKind { model.selected }
    private var p: LabParameters { model.parameters }
    private var state: LabProgress { model.progress }
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    phaseIndicator
                    VStack(alignment: .leading, spacing: 8) {
                        Text(lab.title).font(.system(.title, design: .serif))
                        Text(lab.subtitle).font(.subheadline).foregroundStyle(Ink.muted)
                    }
                    SacredStage(kind: lab, parameters: p,
                                onAngleChange: { value in model.update { $0.angle = value } },
                                onRotation: { yaw, pitch in model.update { $0.yaw = yaw; $0.pitch = pitch } })
                        .frame(height: typeSize.isAccessibilitySize ? 250 : 285)
                        .accessibilityIdentifier("experimentStage")
                    result
                    LabControls(model: model)
                    learningPanel.id("learningPanel")
                    Text(lab.category).font(.system(.caption2, design: .monospaced)).tracking(1.4).foregroundStyle(Ink.muted)
                }.padding(.horizontal, 24).padding(.top, 8).padding(.bottom, 24)
            }
            .onChange(of: state.phase) { _, phase in
                if phase == .predict || phase == .explain || phase == .complete {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { proxy.scrollTo("learningPanel", anchor: .center) }
                }
            }
            .onChange(of: lab) { _, _ in proxy.scrollTo("top", anchor: .top) }
        }
        .background { UniverseBackground() }
        .navigationTitle(lab.shortTitle).navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showSource(lab) } label: { Image(systemName: "info.circle").frame(minWidth: 44, minHeight: 44) }
                    .accessibilityLabel("About this experiment").accessibilityIdentifier("sourceNotes")
            }
        }
        .safeAreaInset(edge: .bottom) { bottomAction.padding(.horizontal, 24).padding(.vertical, 12).background(Ink.bg.opacity(0.96)) }
        .onAppear { model.select(initial) }
        .onDisappear { model.stop(); model.persist() }
    }

    private var phaseIndicator: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Eyebrow(text: "\(String(format: "%02d", lab.index)) / 08")
                Spacer()
                Text(state.phase.label).font(.caption.weight(.semibold)).foregroundStyle(Ink.gold)
                    .accessibilityIdentifier("learningPhase").accessibilityValue(state.phase.rawValue)
            }
            HStack(spacing: 5) {
                ForEach(0..<5) { index in Capsule().fill(index <= state.phase.index ? Ink.gold : Ink.muted.opacity(0.16)).frame(height: 3) }
            }.accessibilityHidden(true)
        }.id("top")
    }

    private var result: some View {
        VStack(alignment: .leading, spacing: 9) {
            Eyebrow(text: readout.0)
            Text(readout.1).font(.system(.title, design: .monospaced).weight(.light)).foregroundStyle(Ink.gold)
                .minimumScaleFactor(0.6).lineLimit(2).contentTransition(.numericText())
                .accessibilityIdentifier("resultValue")
            Text(readout.2).font(.footnote).foregroundStyle(Ink.muted).lineSpacing(3)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private var readout: (String, String, String) {
        switch lab {
        case .circle:
            let value = p.unit.value(fromDegrees: p.angle)
            let suffix = p.unit == .degrees ? "°" : p.unit == .radians ? " rad" : " turns"
            return ("SAME TURN, DIFFERENT UNIT", decimal(value, digits: 3) + suffix, "\(decimal(p.angle))° = \(decimal(p.angle * .pi / 180, digits: 3)) radians = \(decimal(p.angle / 360, digits: 3)) turns")
        case .time:
            return ("ONE DURATION", "\(decimal(p.hours)) hours", "\(decimal(p.hours * 60, digits: 0)) minutes · \(decimal(p.hours * 3600, digits: 0)) seconds")
        case .roots:
            let steps = SacredMath.digitReductionSteps(p.number, base: p.base).map { String($0, radix: p.base).uppercased() }.joined(separator: " → ")
            let finalDigit = String(SacredMath.digitalRoot(p.number, base: p.base), radix: p.base).uppercased()
            return ("DIGIT SUM IN BASE \(p.base)", steps, "\(p.number) in decimal is written \(String(p.number, radix: p.base).uppercased()) in base \(p.base). Final digit: \(finalDigit).")
        case .polygons:
            return ("\(p.sides - 2) TRIANGLES × 180°", "\(decimal(SacredMath.polygonInteriorSum(sides: p.sides), digits: 0))°", "Each interior angle: \(decimal(SacredMath.polygonInteriorAngle(sides: p.sides)))° · sum in radians: \(p.sides - 2)π")
        case .solids:
            return ("VERTICES − EDGES + FACES", "\(p.solid.vertexCount) − \(p.solid.edgeCount) + \(p.solid.faceCount) = 2", "\(decimal(p.solid.totalFaceAngles, digits: 0))° across all face interiors · decimal root \(SacredMath.digitalRoot(Int(p.solid.totalFaceAngles)))")
        case .precession:
            let period = p.idealized ? 25_920.0 : 25_772.0
            return (p.idealized ? "SYMBOLIC CONSTANT-PERIOD MODEL" : "APPROXIMATE CONSTANT-PERIOD MODEL", "\(decimal(SacredMath.precessionDegrees(years: p.years, period: period)))°", "\(decimal(p.years, digits: 0)) years · \(decimal(period / 360)) years / degree · \(decimal(SacredMath.arcsecondsPerYear(period: period)))″ / year")
        case .scale:
            let ratio = p.moonDistance / 3474.8
            let angle = 2 * atan(3474.8 / (2 * p.moonDistance)) * 180 / .pi
            return ("DISTANCE ÷ MOON DIAMETER", "\(decimal(ratio)) : 1", "Moon: \(decimal(angle, digits: 3))° across · Sun at mean distance: ≈0.533°. Distances are center to center.")
        case .pyramid:
            let circumference = 2 * .pi * p.pyramidHeight
            return ("SQUARE PERIMETER / CIRCLE DIAMETER", decimal(921.6 / (2 * p.pyramidHeight), digits: 5), "Square: 921.6 m · circle: \(decimal(circumference)) m · difference: \(decimal(abs(circumference - 921.6))) m. π ≈ 3.14159.")
        }
    }

    @ViewBuilder private var learningPanel: some View {
        switch state.phase {
        case .observe, .experiment:
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: state.interacted ? "YOU CHANGED THE PATTERN" : "YOUR TURN")
                Text(lab.prompt).font(.subheadline).lineSpacing(4)
                if state.interacted { Text("Notice what changed in the live readout. Then test your understanding.").font(.footnote).foregroundStyle(Ink.muted) }
            }.readingCard()
        case .predict:
            if let prediction = state.prediction {
                VStack(alignment: .leading, spacing: 16) {
                    Eyebrow(text: "BEFORE THE REVEAL")
                    Text(prediction.question).font(.system(.title3, design: .serif))
                    ForEach(prediction.choices.indices, id: \.self) { index in
                        Button { model.answer(index) } label: {
                            HStack { Text(prediction.choices[index]); Spacer(); Image(systemName: state.selectedAnswer == index ? "arrow.counterclockwise" : "circle") }
                                .font(.subheadline.weight(.medium)).frame(minHeight: 44).padding(.horizontal, 14)
                        }.buttonStyle(.bordered).tint(state.selectedAnswer == index ? Ink.cyan : Ink.gold).accessibilityIdentifier("answer\(index)")
                    }
                    if let answer = state.selectedAnswer, answer != prediction.correct {
                        Text("Try once more. Return to the visual and follow the relationship.").font(.footnote).foregroundStyle(Ink.cyan).accessibilityIdentifier("tryAgain")
                    }
                }.readingCard()
            }
        case .explain, .complete:
            VStack(alignment: .leading, spacing: 14) {
                Eyebrow(text: state.phase == .complete ? "A RELATIONSHIP YOU CAN KEEP" : "THE PATTERN REVEALED")
                if let prediction = state.prediction { Text(prediction.explanation).font(.subheadline.weight(.medium)).lineSpacing(4) }
                Text(lab.insight).font(.subheadline).foregroundStyle(Ink.muted).lineSpacing(5)
                if state.phase == .complete {
                    TextField("What did you notice?", text: Binding(get: { state.reflection }, set: { model.reflect($0) }), axis: .vertical)
                        .lineLimit(3...6).padding(12).background(Ink.bg, in: .rect(cornerRadius: 12)).accessibilityIdentifier("reflection")
                    Button("Explore this again") { model.replay() }.font(.footnote.weight(.semibold)).frame(minHeight: 44).accessibilityIdentifier("replayExperiment")
                }
            }.readingCard()
        }
    }

    @ViewBuilder private var bottomAction: some View {
        GlassEffectContainer(spacing: 12) {
            switch state.phase {
            case .observe: GlassAction(title: "Begin experiment", prominent: true, id: "beginExperiment") { model.begin() }
            case .experiment: GlassAction(title: state.interacted ? "Make a prediction" : "Change something to continue", prominent: true, id: "makePrediction") { model.predict() }.disabled(!state.interacted)
            case .predict: Text("Choose a prediction above").font(.footnote).foregroundStyle(Ink.muted).frame(maxWidth: .infinity, minHeight: 44)
            case .explain: GlassAction(title: "Save discovery", symbol: "sparkle", prominent: true, id: "saveDiscovery") { model.discover() }
            case .complete:
                GlassAction(title: model.discovered.count == 8 ? "Explore freely" : "Next experiment", symbol: "arrow.up.right", prominent: true, id: "nextExperiment") { model.select(model.nextUndiscovered) }
            }
        }
    }
}

struct LabControls: View {
    let model: UniverseModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    private var p: LabParameters { model.parameters }
    private var lab: LabKind { model.selected }
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            switch lab {
            case .circle:
                responsivePicker(Picker("Angle unit", selection: binding(\.unit)) { ForEach(AngleUnit.allCases, id: \.self) { Text($0.label).tag($0) } }).accessibilityIdentifier("angleUnit")
                dial("Angle", value: binding(\.angle), range: 0...360, step: 1, suffix: "°", id: "angleSlider")
            case .time: dial("Hours", value: binding(\.hours), range: 0...24, step: 0.25, suffix: " h", id: "hoursSlider")
            case .roots:
                responsivePicker(Picker("Number base", selection: binding(\.base)) { Text("Base 10").tag(10); Text("Base 8").tag(8); Text("Base 12").tag(12) }).accessibilityIdentifier("numberBase")
                Stepper(value: binding(\.number), in: 0...999_999) { Text("Decimal value: \(p.number)").font(.subheadline) }.accessibilityIdentifier("numberStepper")
                HStack(spacing: 8) { ForEach([360, 1440, 86400], id: \.self) { value in Button(value.formatted()) { model.update { $0.number = value } }.font(.caption).frame(minHeight: 44).buttonStyle(.bordered).tint(Ink.gold) } }
            case .polygons:
                Stepper(value: binding(\.sides), in: 3...12) { Text("\(p.sides) sides · \(p.sides - 2) triangles").font(.subheadline) }.accessibilityIdentifier("sidesStepper")
            case .solids:
                Picker("Choose solid", selection: binding(\.solid)) { ForEach(SolidKind.allCases, id: \.self) { Text($0.label).tag($0) } }.pickerStyle(.menu).tint(Ink.gold).accessibilityIdentifier("solidPicker")
                dial("Rotation", value: binding(\.yaw), range: -.pi...(.pi), step: 0.01, suffix: " rad", id: "rotationSlider")
            case .precession:
                responsivePicker(Picker("Precession model", selection: binding(\.idealized)) { Text("Symbolic · 25,920").tag(true); Text("Approx. · 25,772").tag(false) }).accessibilityIdentifier("precessionModel")
                dial("Years elapsed", value: binding(\.years), range: 0...25_920, step: 72, suffix: " yr", id: "yearsSlider")
            case .scale:
                dial("Moon distance", value: binding(\.moonDistance), range: 363_300...405_500, step: 100, suffix: " km", id: "distanceSlider")
                Text("Representative mean perigee → apogee. Apparent disks share an angular scale; the travel diagram is schematic.").font(.caption).foregroundStyle(Ink.muted)
            case .pyramid:
                dial("Apex height", value: binding(\.pyramidHeight), range: 120...170, step: 0.1, suffix: " m", id: "heightSlider")
                Text("Fixed base 230.4 m. Approximate original dimensions; proposed symbolism is an interpretation.").font(.caption).foregroundStyle(Ink.muted)
            }
            GlassEffectContainer(spacing: 12) {
                HStack(spacing: 12) {
                    GlassAction(title: sampleTitle, symbol: "hand.tap", id: "sampleAction", action: sample)
                    if [.circle, .solids, .time, .precession].contains(lab) && !reduceMotion {
                        Button { model.toggleRunning() } label: { Image(systemName: model.running ? "pause.fill" : "play.fill").frame(width: 44, height: 44) }
                            .buttonStyle(.glass).accessibilityLabel(model.running ? "Pause motion" : "Play motion").accessibilityIdentifier("playMotion")
                    }
                }
            }
        }.padding(.vertical, 8)
    }
    private func binding<T>(_ path: WritableKeyPath<LabParameters, T>) -> Binding<T> {
        Binding(get: { model.parameters[keyPath: path] }, set: { value in model.update { $0[keyPath: path] = value } })
    }
    @ViewBuilder private func responsivePicker<Content: View>(_ content: Content) -> some View {
        if typeSize.isAccessibilitySize { content.pickerStyle(.menu).tint(Ink.gold) }
        else { content.pickerStyle(.segmented) }
    }
    private func dial(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, suffix: String, id: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { Text(title).font(.subheadline.weight(.medium)); Spacer(); Text(decimal(value.wrappedValue, digits: step < 1 ? 2 : 0) + suffix).font(.system(.caption, design: .monospaced)).foregroundStyle(Ink.gold) }
            Slider(value: value, in: range, step: step).tint(Ink.gold).accessibilityLabel(title).accessibilityValue(decimal(value.wrappedValue) + suffix).accessibilityIdentifier(id)
        }
    }
    private var sampleTitle: String {
        switch lab {
        case .circle: "Try a half-turn"
        case .time: "Try six hours"
        case .roots: "Try 720"
        case .polygons: "Try a pentagon"
        case .solids: "Try the next solid"
        case .precession: "Travel 6,480 years"
        case .scale: "Move to perigee"
        case .pyramid: "Match the circle"
        }
    }
    private func sample() {
        model.update { values in
            switch lab {
            case .circle: values.angle = p.angle == 180 ? 90 : 180
            case .time: values.hours = p.hours == 6 ? 12 : 6
            case .roots: values.number = p.number == 720 ? 1440 : 720
            case .polygons: values.sides = p.sides == 5 ? 6 : 5
            case .solids: let kinds = SolidKind.allCases; values.solid = kinds[(kinds.firstIndex(of: p.solid)! + 1) % kinds.count]
            case .precession: values.years = p.years == 6480 ? 12960 : 6480
            case .scale: values.moonDistance = p.moonDistance == 363300 ? 405500 : 363300
            case .pyramid: values.pyramidHeight = abs(p.pyramidHeight - 921.6 / (2 * .pi)) < 0.01 ? 146.6 : 921.6 / (2 * .pi)
            }
        }
    }
}
