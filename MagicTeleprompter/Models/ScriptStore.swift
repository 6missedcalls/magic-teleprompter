import SwiftUI
import Combine
import UniformTypeIdentifiers

@MainActor
final class ScriptStore: ObservableObject, @unchecked Sendable {

    @Published var scriptText: String

    private var cancellables = Set<AnyCancellable>()

    private static let userDefaultsKey = "magic_teleprompter_draft"

    init() {
        self.scriptText = UserDefaults.standard.string(
            forKey: Self.userDefaultsKey
        ) ?? ""

        setupAutosave()
    }

    // MARK: - Import

    func importScript() {
        let panel = NSOpenPanel()
        panel.title = "Import Script"
        panel.allowedContentTypes = [.plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            scriptText = content
        } catch {
            presentError(
                title: "Import Failed",
                message: "Could not read file: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Export

    func exportScript() {
        let panel = NSSavePanel()
        panel.title = "Export Script"
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "script.txt"
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try scriptText.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            presentError(
                title: "Export Failed",
                message: "Could not write file: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Private

    private func setupAutosave() {
        $scriptText
            .debounce(for: .seconds(2), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] text in
                guard self != nil else { return }
                UserDefaults.standard.set(text, forKey: ScriptStore.userDefaultsKey)
            }
            .store(in: &cancellables)
    }

    private func presentError(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
