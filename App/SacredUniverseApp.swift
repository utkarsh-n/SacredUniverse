import SwiftUI

@main
struct SacredUniverseApp: App {
    var body: some Scene {
        WindowGroup { UniverseRoot().preferredColorScheme(.dark) }
    }
}

enum UniverseSheet: Identifiable {
    case settings, source(LabKind)
    var id: String {
        switch self { case .settings: "settings"; case .source(let kind): "source-\(kind.rawValue)" }
    }
}

struct UniverseRoot: View {
    @State private var model = UniverseModel()
    @State private var tab = 0
    @State private var sheet: UniverseSheet?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var animating: Bool { model.running && sheet == nil && scenePhase == .active && !reduceMotion }
    var body: some View {
        TabView(selection: $tab) {
            Tab("Universe", systemImage: "sparkles", value: 0) {
                NavigationStack {
                    UniverseHome(model: model)
                        .navigationDestination(for: LabKind.self) { lab in laboratory(lab) }
                        .toolbar { sensoryToolbar }
                }
            }
            Tab("Journey", systemImage: "point.topleft.down.to.point.bottomright.curvepath", value: 1) {
                NavigationStack {
                    JourneyView(model: model)
                        .navigationDestination(for: LabKind.self) { lab in laboratory(lab) }
                        .toolbar { sensoryToolbar }
                }
            }
            Tab("Notebook", systemImage: "book.closed", value: 2) {
                NavigationStack {
                    NotebookView(model: model)
                        .navigationDestination(for: LabKind.self) { lab in laboratory(lab) }
                        .toolbar { sensoryToolbar }
                }
            }
        }
        .tint(Ink.gold).foregroundStyle(Ink.text)
        .sheet(item: $sheet) { destination in
            switch destination {
            case .settings: SensorySettings(model: model)
            case .source(let kind): SourceNotes(kind: kind)
            }
        }
        .onChange(of: tab) { _, _ in model.stop(); model.persist() }
        .onChange(of: sheet?.id) { _, _ in model.stop() }
        .onChange(of: scenePhase) { _, phase in if phase != .active { model.stop(); model.persist() } }
        .onChange(of: reduceMotion) { _, reduced in if reduced { model.stop() } }
        .task(id: animating) {
            guard animating else { return }
            while !Task.isCancelled && animating {
                do { try await Task.sleep(for: .milliseconds(33)) } catch { return }
                model.advance(0.033)
            }
        }
    }
    private func laboratory(_ lab: LabKind) -> some View {
        LaboratoryView(model: model, initial: lab) { kind in sheet = .source(kind) }
            .toolbar(.hidden, for: .tabBar)
            .toolbar { sensoryToolbar }
    }
    @ToolbarContentBuilder private var sensoryToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { sheet = .settings } label: { Image(systemName: "slider.horizontal.3").frame(minWidth: 44, minHeight: 44) }
                .accessibilityLabel("Sensory settings").accessibilityIdentifier("sensorySettings")
        }
    }
}
