import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var scriptStore: ScriptStore
    @EnvironmentObject var playbackEngine: PlaybackEngine

    var body: some View {
        VStack(spacing: 0) {
            header
            scriptEditor
            fileActions
            Divider().padding(.horizontal, 14)
            settingsControls
        }
        .frame(minWidth: 380, minHeight: 400)
        .background(.ultraThinMaterial)
        .presentationBackground(.ultraThinMaterial)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Settings")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
            wordCount
            Spacer()
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular, in: .capsule)
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }

    // MARK: - Script Editor

    private var scriptEditor: some View {
        TextEditor(text: $scriptStore.scriptText)
            .font(.system(size: 13, design: .monospaced))
            .scrollContentBackground(.hidden)
            .padding(.horizontal, 10)
    }

    // MARK: - File Actions

    private var fileActions: some View {
        HStack(spacing: 6) {
            GlassEffectContainer {
                HStack(spacing: 2) {
                    Button {
                        scriptStore.importScript()
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                            .font(.system(size: 10))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular, in: .capsule)

                    Button {
                        scriptStore.exportScript()
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                            .font(.system(size: 10))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular, in: .capsule)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }

    // MARK: - Settings Controls

    private var settingsControls: some View {
        VStack(spacing: 10) {
            settingRow(label: "Font Size") {
                HStack(spacing: 4) {
                    Button { playbackEngine.decreaseFontSize() } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 9, weight: .semibold))
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)

                    Text("\(Int(playbackEngine.fontSize))")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.primary)
                        .frame(width: 24)

                    Button { playbackEngine.increaseFontSize() } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 9, weight: .semibold))
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }

            settingRow(label: "Mirror") {
                Toggle("", isOn: $playbackEngine.isMirrored)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
            }

            settingRow(label: "Countdown") {
                Toggle("", isOn: $playbackEngine.showCountdown)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
            }

            settingRow(label: "Hide from recordings") {
                Toggle("", isOn: $playbackEngine.hideFromRecording)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
            }
        }
        .padding(14)
    }

    // MARK: - Helpers

    private func settingRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
            content()
        }
    }

    private var wordCount: some View {
        let words = scriptStore.scriptText
            .split { $0.isWhitespace }
            .count
        return Text("\(words) words")
            .font(.system(size: 9, design: .monospaced))
            .foregroundStyle(.quaternary)
    }
}
