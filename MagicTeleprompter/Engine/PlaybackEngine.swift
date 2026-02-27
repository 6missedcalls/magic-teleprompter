import Foundation
import SwiftUI

@MainActor
final class PlaybackEngine: ObservableObject {

    // MARK: - Constants

    static let minSpeed: Double = 80
    static let maxSpeed: Double = 400
    static let speedStep: Double = 10
    static let minFontSize: CGFloat = 20
    static let maxFontSize: CGFloat = 72

    // MARK: - Playback State

    @Published var isPlaying: Bool = false
    @Published var currentIndex: Int = 0
    @Published var countdownValue: Int? = nil

    // MARK: - Persisted Settings

    @Published var speed: Double = 180 {
        didSet { UserDefaults.standard.set(speed, forKey: "playback_speed") }
    }

    @Published var fontSize: CGFloat = 36 {
        didSet { UserDefaults.standard.set(fontSize, forKey: "playback_fontSize") }
    }

    @Published var isMirrored: Bool = false {
        didSet { UserDefaults.standard.set(isMirrored, forKey: "playback_isMirrored") }
    }

    @Published var showCountdown: Bool = true {
        didSet { UserDefaults.standard.set(showCountdown, forKey: "playback_showCountdown") }
    }

    @Published var hideFromRecording: Bool = false {
        didSet { UserDefaults.standard.set(hideFromRecording, forKey: "playback_hideFromRecording") }
    }

    // MARK: - Sentence State

    private(set) var sentences: [String] = []

    var currentSentence: String {
        guard !sentences.isEmpty, currentIndex < sentences.count else {
            return ""
        }
        return sentences[currentIndex]
    }

    var progress: String {
        guard !sentences.isEmpty else { return "" }
        return "\(currentIndex + 1) / \(sentences.count)"
    }

    var isAdvanceTimerActive: Bool {
        advanceTimer != nil
    }

    var onAdvance: (() -> Void)?

    // MARK: - Private

    private var countdownTimer: Timer?
    private var advanceTimer: Timer?

    // MARK: - Init

    init() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "playback_speed") != nil {
            speed = defaults.double(forKey: "playback_speed")
        }
        if defaults.object(forKey: "playback_fontSize") != nil {
            fontSize = defaults.double(forKey: "playback_fontSize")
        }
        isMirrored = defaults.bool(forKey: "playback_isMirrored")
        if defaults.object(forKey: "playback_showCountdown") != nil {
            showCountdown = defaults.bool(forKey: "playback_showCountdown")
        }
        hideFromRecording = defaults.bool(forKey: "playback_hideFromRecording")
    }

    // MARK: - Sentence Management

    func setSentences(from text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            sentences = []
            return
        }
        
        // Use cached result if text hasn't changed
        if trimmed == lastProcessedText {
            return
        }
        lastProcessedText = trimmed
        
        // More efficient sentence splitting using NaturalLanguage framework
        var result: [String] = []
        result.reserveCapacity(100)
        
        trimmed.enumerateSubstrings(
            in: trimmed.startIndex...,
            options: .bySentences
        ) { substring, _, _, _ in
            if let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
                result.append(s)
            }
        }
        sentences = result.isEmpty ? [trimmed] : result
    }
    
    private var lastProcessedText: String = ""

    // MARK: - Sentence Timing

    func displayDuration(for sentence: String) -> TimeInterval {
        let wordCount = sentence.split { $0.isWhitespace }.count
        let seconds = Double(wordCount) / speed * 60.0
        return max(seconds, 1.2)
    }

    // MARK: - Playback Controls

    func togglePlayPause(sentenceCount: Int) {
        if !isPlaying && showCountdown && currentIndex == 0 {
            startCountdown(sentenceCount: sentenceCount)
        } else if isPlaying {
            pause()
        } else {
            play(sentenceCount: sentenceCount)
        }
    }

    func startCountdown(sentenceCount: Int) {
        countdownTimer?.invalidate()
        advanceTimer?.invalidate()
        countdownValue = 3

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tickCountdown(sentenceCount: sentenceCount)
            }
        }
    }

    private func tickCountdown(sentenceCount: Int) {
        guard let current = countdownValue else {
            countdownTimer?.invalidate()
            countdownTimer = nil
            return
        }
        if current <= 1 {
            countdownTimer?.invalidate()
            countdownTimer = nil
            countdownValue = nil
            play(sentenceCount: sentenceCount)
        } else {
            countdownValue = current - 1
        }
    }

    func play(sentenceCount: Int) {
        countdownTimer?.invalidate()
        countdownValue = nil
        guard sentenceCount > 0 else { return }
        isPlaying = true
    }

    func pause() {
        countdownTimer?.invalidate()
        stopAdvanceTimer()
        countdownValue = nil
        isPlaying = false
    }

    func reset() {
        pause()
        currentIndex = 0
    }

    func advanceToNext(sentenceCount: Int) {
        guard currentIndex < sentenceCount - 1 else {
            pause()
            return
        }
        currentIndex = currentIndex + 1
    }

    func advanceToNext() {
        advanceToNext(sentenceCount: sentences.count)
    }

    func goBack() {
        guard currentIndex > 0 else { return }
        currentIndex = currentIndex - 1
    }

    // MARK: - Advance Timer

    func startAdvanceTimer() {
        advanceTimer?.invalidate()
        advanceTimer = nil
        guard isPlaying, !sentences.isEmpty else { return }
        let duration = displayDuration(for: currentSentence)

        advanceTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isPlaying else { return }
                self.advanceToNext()
                self.onAdvance?()
                if self.isPlaying {
                    self.startAdvanceTimer()
                }
            }
        }
    }

    func stopAdvanceTimer() {
        advanceTimer?.invalidate()
        advanceTimer = nil
    }

    // MARK: - Speed

    func increaseSpeed() {
        speed = min(speed + Self.speedStep, Self.maxSpeed)
    }

    func decreaseSpeed() {
        speed = max(speed - Self.speedStep, Self.minSpeed)
    }

    // MARK: - Font Size

    func increaseFontSize() {
        fontSize = min(fontSize + 2, Self.maxFontSize)
    }

    func decreaseFontSize() {
        fontSize = max(fontSize - 2, Self.minFontSize)
    }

    // MARK: - Mirror

    func toggleMirror() {
        isMirrored = !isMirrored
    }
}
