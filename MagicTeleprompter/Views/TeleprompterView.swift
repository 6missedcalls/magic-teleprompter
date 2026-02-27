import SwiftUI

struct TeleprompterView: View {
    @EnvironmentObject var scriptStore: ScriptStore
    @EnvironmentObject var playbackEngine: PlaybackEngine
    @State private var showSettings = false
    @State private var parseTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            sentenceDisplay
            countdownOverlay
            controlBar
        }
        .background(.ultraThinMaterial)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(scriptStore)
                .environmentObject(playbackEngine)
        }
        .onKeyPress(.space) {
            playbackEngine.togglePlayPause(sentenceCount: playbackEngine.sentences.count)
            return .handled
        }
        .onKeyPress(.upArrow) {
            playbackEngine.increaseSpeed()
            return .handled
        }
        .onKeyPress(.downArrow) {
            playbackEngine.decreaseSpeed()
            return .handled
        }
        .onKeyPress(.rightArrow) {
            playbackEngine.advanceToNext()
            playbackEngine.startAdvanceTimer()
            return .handled
        }
        .onKeyPress(.leftArrow) {
            playbackEngine.goBack()
            playbackEngine.startAdvanceTimer()
            return .handled
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "mM")) { _ in
            playbackEngine.toggleMirror()
            return .handled
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "+=")) { press in
            if press.modifiers.contains(.command) {
                playbackEngine.increaseFontSize()
                return .handled
            }
            return .ignored
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "-")) { press in
            if press.modifiers.contains(.command) {
                playbackEngine.decreaseFontSize()
                return .handled
            }
            return .ignored
        }
        .focusable()
        .onChange(of: scriptStore.scriptText) { _, newText in
            // Debounce expensive sentence parsing
            parseTask?.cancel()
            parseTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                playbackEngine.setSentences(from: newText)
            }
        }
        .onChange(of: playbackEngine.isPlaying) { _, isPlaying in
            if isPlaying {
                playbackEngine.startAdvanceTimer()
            } else {
                playbackEngine.stopAdvanceTimer()
            }
        }
        .onChange(of: playbackEngine.speed) { _, _ in
            if playbackEngine.isPlaying {
                playbackEngine.startAdvanceTimer()
            }
        }
        .onAppear {
            playbackEngine.setSentences(from: scriptStore.scriptText)
        }
        .onDisappear {
            parseTask?.cancel()
            playbackEngine.stopAdvanceTimer()
        }
    }

    // MARK: - Sentence Display

    private var sentenceDisplay: some View {
        GeometryReader { geo in
            ZStack {
                if !playbackEngine.sentences.isEmpty {
                    Text(playbackEngine.currentSentence)
                        .font(.system(
                            size: playbackEngine.fontSize,
                            weight: .medium,
                            design: .rounded
                        ))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .frame(maxWidth: min(geo.size.width, 800))
                        .contentTransition(.opacity)
                        .scaleEffect(
                            x: playbackEngine.isMirrored ? -1 : 1,
                            y: 1,
                            anchor: .center
                        )
                        .animation(.easeInOut(duration: 0.2), value: playbackEngine.currentIndex)
                } else {
                    Button {
                        showSettings = true
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 24))
                            Text("Add your script")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(.quaternary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: playbackEngine.sentences.isEmpty)
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    // MARK: - Countdown

    @ViewBuilder
    private var countdownOverlay: some View {
        if let countdown = playbackEngine.countdownValue {
            ZStack {
                Color.black.opacity(0.5)
                Text("\(countdown)")
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: countdown)
            }
        }
    }

    // MARK: - Control Bar

    private var controlBar: some View {
        VStack(spacing: 3) {
            Spacer()

            Text(playbackEngine.progress)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.quaternary)

            GlassEffectContainer {
                HStack(spacing: 8) {
                    playPauseButton
                    resetButton

                    Divider().frame(height: 14)

                    speedControl

                    Spacer()

                    settingsButton
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
    }

    private var playPauseButton: some View {
        Button {
            playbackEngine.togglePlayPause(sentenceCount: playbackEngine.sentences.count)
        } label: {
            Image(systemName: playbackEngine.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 13))
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }

    private var resetButton: some View {
        Button {
            playbackEngine.reset()
        } label: {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 11))
                .frame(width: 18, height: 18)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
    }

    private var speedControl: some View {
        HStack(spacing: 4) {
            Text("WPM")
                .font(.system(size: 8))
                .foregroundStyle(.tertiary)
            Slider(
                value: $playbackEngine.speed,
                in: PlaybackEngine.minSpeed...PlaybackEngine.maxSpeed,
                step: PlaybackEngine.speedStep
            )
            .frame(width: 80)
            .controlSize(.mini)
            Text("\(Int(playbackEngine.speed))")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 24, alignment: .trailing)
        }
    }

    private var settingsButton: some View {
        Button {
            showSettings = true
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 11))
                .frame(width: 18, height: 18)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
    }
}
