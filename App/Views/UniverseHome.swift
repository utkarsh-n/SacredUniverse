import SwiftUI

struct UniverseHome: View {
    let model: UniverseModel
    @ScaledMetric(relativeTo: .largeTitle) private var heroSize = 49.0
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 9) {
                    Eyebrow(text: "AN ATLAS OF HIDDEN RELATIONSHIPS")
                    Text("Sacred\nUniverse").font(.system(size: heroSize, weight: .regular, design: .serif)).tracking(-1.5).lineSpacing(-4)
                    Text("Find the pattern. Follow your wonder.").font(.subheadline).foregroundStyle(Ink.muted)
                }.padding(.top, 4)

                ZStack(alignment: .bottom) {
                    SacredMandala().frame(height: 265).accessibilityHidden(true)
                    VStack(spacing: 8) {
                        Text("ONE WORLD. MANY WAYS TO SEE.").font(.system(.caption2, design: .monospaced)).tracking(2).foregroundStyle(Ink.muted)
                        NavigationLink(value: model.selected) {
                            Label(model.progress.phase == .observe ? "Begin exploring" : "Continue exploring", systemImage: "arrow.up.right")
                                .font(.subheadline.weight(.semibold)).frame(minWidth: 195, minHeight: 44)
                        }.buttonStyle(.glassProminent).tint(Ink.gold).foregroundStyle(Ink.bg).accessibilityIdentifier("continueExploring")
                    }.padding(.bottom, 4)
                }

                HStack {
                    Eyebrow(text: "EIGHT CONNECTED EXPERIMENTS")
                    Spacer()
                    Text("\(model.discovered.count) / 8").font(.system(.caption, design: .monospaced)).foregroundStyle(Ink.muted)
                        .accessibilityLabel("\(model.discovered.count) of 8 discoveries saved")
                }
                LazyVStack(spacing: 12) {
                    ForEach(LabKind.allCases) { lab in
                        NavigationLink(value: lab) { LabRow(kind: lab, progress: model.progress(for: lab)) }
                            .buttonStyle(.plain).accessibilityIdentifier("lab-\(lab.rawValue)")
                    }
                }
                if let notice = model.restorationNotice { Text(notice).font(.footnote).foregroundStyle(Ink.muted).readingCard() }
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow(text: "INSPIRED BY A QUESTION")
                    Text("What survives when you change how you measure?").font(.system(.title3, design: .serif))
                    Text("Inspired by After Skool’s Hidden Mathematics with Randall Carlson. Explore the relationships with your own hands.").font(.footnote).foregroundStyle(Ink.muted).lineSpacing(4)
                    Link("Watch the original film ↗", destination: URL(string: "https://www.youtube.com/watch?v=R7oyZGW99os")!).font(.footnote.weight(.semibold)).padding(.top, 4)
                }.readingCard()
            }.padding(.horizontal, 24).padding(.bottom, 28)
        }.background { UniverseBackground() }.navigationTitle("Universe").navigationBarTitleDisplayMode(.inline)
    }
}

struct LabRow: View {
    let kind: LabKind
    let progress: LabProgress
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 15).fill(Ink.gold.opacity(0.08)).frame(width: 52, height: 58)
                Image(systemName: kind.symbol).font(.title2.weight(.light)).foregroundStyle(Ink.gold)
            }.accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(String(format: "%02d", kind.index)).font(.system(.caption2, design: .monospaced)).foregroundStyle(Ink.gold)
                    Text(kind.shortTitle.uppercased()).font(.caption2.weight(.medium)).tracking(1.4).foregroundStyle(Ink.muted)
                }
                Text(kind.title).font(.system(.headline, design: .serif)).foregroundStyle(Ink.text)
                Text(progress.discoveredAt == nil ? kind.subtitle : "Discovery saved · explore again").font(.caption).foregroundStyle(Ink.muted)
            }.frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: progress.discoveredAt == nil ? "arrow.up.right" : "checkmark.circle.fill").font(.subheadline).foregroundStyle(progress.discoveredAt == nil ? Ink.muted : Ink.cyan)
        }.padding(16).background(Ink.panel.opacity(0.65), in: .rect(cornerRadius: 22))
            .overlay { RoundedRectangle(cornerRadius: 22).strokeBorder(.white.opacity(0.055)) }
            .accessibilityElement(children: .combine)
    }
}

struct JourneyView: View {
    let model: UniverseModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                Eyebrow(text: "FROM THE EVERYDAY TO THE COSMIC")
                Text("A path through\nthe pattern.").font(.system(.largeTitle, design: .serif))
                Text("Notice. Explore. Predict. Understand. Keep the insight. Every stop is open; start wherever curiosity takes you.").font(.subheadline).foregroundStyle(Ink.muted).lineSpacing(4)
                ProgressView(value: Double(model.discovered.count), total: 8).tint(Ink.gold).accessibilityLabel("Learning progress")
                ForEach(LabKind.allCases) { lab in
                    HStack(alignment: .top, spacing: 18) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle().stroke(Ink.gold.opacity(0.5), lineWidth: 1).frame(width: 36, height: 36)
                                Image(systemName: model.progress(for: lab).discoveredAt == nil ? lab.symbol : "checkmark").font(.caption).foregroundStyle(Ink.gold)
                            }
                            if lab != .pyramid { Rectangle().fill(Ink.gold.opacity(0.15)).frame(width: 1, height: 80) }
                        }.accessibilityHidden(true)
                        NavigationLink(value: lab) {
                            VStack(alignment: .leading, spacing: 8) {
                                Eyebrow(text: "STOP \(lab.index) · \(model.progress(for: lab).phase.label.uppercased())")
                                Text(lab.title).font(.system(.title3, design: .serif)).foregroundStyle(Ink.text)
                                Text(lab.prompt).font(.footnote).foregroundStyle(Ink.muted).lineSpacing(3)
                            }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 3)
                        }.buttonStyle(.plain).accessibilityIdentifier("journey-\(lab.rawValue)")
                    }
                }
            }.padding(24)
        }.background { UniverseBackground() }.navigationTitle("Journey").navigationBarTitleDisplayMode(.inline)
    }
}

struct NotebookView: View {
    let model: UniverseModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Eyebrow(text: "YOUR FIELD NOTES")
                Text("Wonder,\nremembered.").font(.system(.largeTitle, design: .serif))
                if model.discovered.isEmpty {
                    VStack(alignment: .leading, spacing: 18) {
                        Image(systemName: "sparkle").font(.largeTitle).foregroundStyle(Ink.gold)
                        Text("Your first discovery is waiting.").font(.system(.title2, design: .serif))
                        Text("Explore an experiment, test a prediction, and save the insight here. Your dials and notes will stay with you.").font(.subheadline).foregroundStyle(Ink.muted).lineSpacing(4)
                        NavigationLink(value: model.nextUndiscovered) { Label("Find a pattern", systemImage: "arrow.up.right").frame(minHeight: 44) }.buttonStyle(.glassProminent)
                    }.readingCard()
                } else {
                    Text("\(model.discovered.count) discoveries · saved on this iPhone").font(.subheadline).foregroundStyle(Ink.muted).accessibilityIdentifier("notebookCount")
                    ForEach(model.discovered) { kind in
                        NavigationLink(value: kind) {
                            VStack(alignment: .leading, spacing: 12) {
                                Eyebrow(text: kind.category)
                                Text(kind.title).font(.system(.title2, design: .serif))
                                Text(kind.insight).font(.subheadline).foregroundStyle(Ink.muted).lineSpacing(4)
                                if !model.progress(for: kind).reflection.isEmpty {
                                    Text("“\(model.progress(for: kind).reflection)”").font(.system(.body, design: .serif)).foregroundStyle(Ink.gold)
                                }
                                Label("Return to experiment", systemImage: "arrow.up.right").font(.caption.weight(.semibold)).foregroundStyle(Ink.gold)
                            }.readingCard()
                        }.buttonStyle(.plain).accessibilityIdentifier("discovery-\(kind.rawValue)")
                    }
                }
            }.padding(24)
        }.background { UniverseBackground() }.navigationTitle("Notebook").navigationBarTitleDisplayMode(.inline)
    }
}
