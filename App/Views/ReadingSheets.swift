import SwiftUI

struct SensorySettings: View {
    @Bindable var model: UniverseModel
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section("Feel the discoveries") {
                    Toggle("Meaningful haptics", isOn: $model.hapticsEnabled).accessibilityIdentifier("hapticsEnabled")
                    Toggle("Discovery chimes", isOn: $model.soundEnabled).accessibilityIdentifier("soundEnabled")
                    Text("A soft touch marks a change or discovery. Optional chimes respect Silent Mode and mix with your music.").font(.footnote).foregroundStyle(.secondary)
                    Button("Try feedback") { model.feedback.discovery() }.accessibilityIdentifier("tryFeedback")
                }
                Section("At your pace") {
                    Text("Motion pauses when you leave an experiment, open a sheet, or put the app in the background. Reduce Motion replaces playback with manual controls.")
                    Text("Discoveries, dials, and reflections are saved locally on this iPhone. Every experiment is available from the start.")
                }
                Section("Sacred Universe") {
                    Text("An interactive companion to Hidden Mathematics by After Skool, with Randall Carlson. Original visualizations and explanations.")
                    Link("Original video", destination: URL(string: "https://www.youtube.com/watch?v=R7oyZGW99os")!)
                }
            }.navigationTitle("Sensory settings").navigationBarTitleDisplayMode(.inline).tint(Ink.gold)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() }.accessibilityIdentifier("closeSheet") } }
        }.presentationDetents([.large]).presentationDragIndicator(.visible)
    }
}

struct SourceNotes: View {
    let kind: LabKind
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Eyebrow(text: kind.category)
                    Text(kind.title).font(.system(.title, design: .serif))
                    Text(kind.insight).font(.body).lineSpacing(5)
                    VStack(alignment: .leading, spacing: 12) {
                        Eyebrow(text: "FROM THE FILM")
                        Text("Hidden Mathematics · Randall Carlson\nAfter Skool · December 8, 2020").font(.subheadline).foregroundStyle(Ink.muted)
                        Link("Open the related passage ↗", destination: URL(string: "https://www.youtube.com/watch?v=R7oyZGW99os&t=\(kind.videoSeconds)s")!).frame(minHeight: 44)
                    }.readingCard()
                    VStack(alignment: .leading, spacing: 12) {
                        Eyebrow(text: "WHAT THIS MODEL SHOWS")
                        Text(modelNote).font(.subheadline).foregroundStyle(Ink.muted).lineSpacing(5)
                        if kind == .precession {
                            Link("NASA · Axial precession ↗", destination: URL(string: "https://science.nasa.gov/learn/basics-of-space-flight/chapter2-1/")!).frame(minHeight: 44)
                        } else if kind == .scale {
                            Link("NASA · Moon measurements ↗", destination: URL(string: "https://nssdc.gsfc.nasa.gov/planetary/factsheet/moonfact.html")!).frame(minHeight: 44)
                            Link("NASA · Sun measurements ↗", destination: URL(string: "https://nssdc.gsfc.nasa.gov/planetary/factsheet/sunfact.html")!).frame(minHeight: 44)
                        }
                    }.readingCard()
                    Text("The film connects these patterns to sacred traditions and architecture. Those interpretations are part of its perspective; you can test the mathematical relationships here yourself.").font(.footnote).foregroundStyle(Ink.muted).lineSpacing(4)
                }.padding(24)
            }.background { UniverseBackground() }.foregroundStyle(Ink.text)
                .navigationTitle("About this experiment").navigationBarTitleDisplayMode(.inline).tint(Ink.gold)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() }.accessibilityIdentifier("closeSheet") } }
        }.presentationDetents([.large]).presentationDragIndicator(.visible)
    }
    private var modelNote: String {
        switch kind {
        case .circle: "The geometry stays fixed while the units change. A full turn is defined as 360 degrees; in radians it is 2π. Arcminutes and arcseconds subdivide a degree by 60 and 60 again."
        case .time: "24 × 60 × 60 = 86,400 seconds by civil time-unit definitions. Earth's sidereal rotation period is slightly shorter than a solar day; this dial is a conventional 24-hour day."
        case .roots: "This is place-value arithmetic, not a measurement of a physical force. Digits are displayed in the selected base. Zero stays zero, and a positive multiple of base − 1 reduces to base − 1."
        case .polygons: "The fan triangulates a regular convex polygon. Every triangle contributes π radians or 180 degrees. Changing units alters the written angle sum without changing the polygon."
        case .solids: "The mesh coordinates and edge counts are those of genuine regular Platonic solids, projected in perspective. Face-angle sums add planar interior angles across faces; they are distinct from dihedral angles and solid angles."
        case .precession: "The 25,920-year model is the video's symbolic construction. The 25,772-year option is a constant-period approximation near the modern rate; NASA describes the cycle as about 26,000 years. Actual precession varies. Equal sectors on the wheel are divisions of a circle, not constellation boundaries. The scene is a schematic axis cone, not a star-position ephemeris."
        case .scale: "Moon diameter 3,474.8 km; mean distance 384,400 km; representative mean perigee/apogee 363,300/405,500 km. Sun diameter 1,391,400 km at mean distance 149,600,000 km. Angular diameter uses 2 atan(diameter / 2 distance). Real eclipse coverage also depends on observer location and solar distance."
        case .pyramid: "A movable mathematical cross section uses a fixed 230.4 m base and a starting height of 146.6 m, rounded dimensions commonly associated with the Great Pyramid. The circle radius equals the height. Match the circle constructs h = perimeter / 2π; it does not establish ancient design intent."
        }
    }
}
