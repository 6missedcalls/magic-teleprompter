import Testing
import Foundation
@testable import MagicTeleprompter

@MainActor
@Suite("PlaybackEngine Tests")
struct PlaybackEngineTests {

    @Test("Initial state has correct defaults")
    func initialState() {
        let engine = PlaybackEngine()
        #expect(!engine.isPlaying)
        #expect(engine.currentIndex == 0)
        #expect(engine.countdownValue == nil)
    }

    @Test("Play sets isPlaying to true")
    func playStartsPlayback() {
        let engine = PlaybackEngine()
        engine.play(sentenceCount: 5)
        #expect(engine.isPlaying)
    }

    @Test("Play does nothing with zero sentences")
    func playWithZeroSentences() {
        let engine = PlaybackEngine()
        engine.play(sentenceCount: 0)
        #expect(!engine.isPlaying)
    }

    @Test("Pause sets isPlaying to false")
    func pauseStopsPlayback() {
        let engine = PlaybackEngine()
        engine.play(sentenceCount: 5)
        engine.pause()
        #expect(!engine.isPlaying)
    }

    @Test("Reset pauses and resets index")
    func resetClearsState() {
        let engine = PlaybackEngine()
        engine.play(sentenceCount: 5)
        engine.advanceToNext(sentenceCount: 5)
        engine.advanceToNext(sentenceCount: 5)
        engine.reset()
        #expect(!engine.isPlaying)
        #expect(engine.currentIndex == 0)
    }

    @Test("Advance increments current index")
    func advanceIncrementsIndex() {
        let engine = PlaybackEngine()
        engine.play(sentenceCount: 5)
        engine.advanceToNext(sentenceCount: 5)
        #expect(engine.currentIndex == 1)
    }

    @Test("Advance at last sentence pauses")
    func advanceAtEndPauses() {
        let engine = PlaybackEngine()
        engine.play(sentenceCount: 2)
        engine.advanceToNext(sentenceCount: 2)
        #expect(engine.currentIndex == 1)
        engine.advanceToNext(sentenceCount: 2)
        #expect(!engine.isPlaying)
    }

    @Test("Go back decrements index")
    func goBackDecrementsIndex() {
        let engine = PlaybackEngine()
        engine.advanceToNext(sentenceCount: 5)
        engine.advanceToNext(sentenceCount: 5)
        engine.goBack()
        #expect(engine.currentIndex == 1)
    }

    @Test("Go back at zero stays at zero")
    func goBackAtZero() {
        let engine = PlaybackEngine()
        engine.goBack()
        #expect(engine.currentIndex == 0)
    }

    @Test("Increase speed clamps to max")
    func increaseSpeedClamped() {
        let engine = PlaybackEngine()
        engine.speed = PlaybackEngine.maxSpeed
        engine.increaseSpeed()
        #expect(engine.speed == PlaybackEngine.maxSpeed)
    }

    @Test("Decrease speed clamps to min")
    func decreaseSpeedClamped() {
        let engine = PlaybackEngine()
        engine.speed = PlaybackEngine.minSpeed
        engine.decreaseSpeed()
        #expect(engine.speed == PlaybackEngine.minSpeed)
    }

    @Test("Increase font size clamps to max")
    func increaseFontClamped() {
        let engine = PlaybackEngine()
        engine.fontSize = PlaybackEngine.maxFontSize
        engine.increaseFontSize()
        #expect(engine.fontSize == PlaybackEngine.maxFontSize)
    }

    @Test("Decrease font size clamps to min")
    func decreaseFontClamped() {
        let engine = PlaybackEngine()
        engine.fontSize = PlaybackEngine.minFontSize
        engine.decreaseFontSize()
        #expect(engine.fontSize == PlaybackEngine.minFontSize)
    }

    @Test("Toggle mirror flips state")
    func toggleMirror() {
        let engine = PlaybackEngine()
        #expect(!engine.isMirrored)
        engine.toggleMirror()
        #expect(engine.isMirrored)
        engine.toggleMirror()
        #expect(!engine.isMirrored)
    }

    @Test("Display duration scales with word count")
    func displayDurationScaling() {
        let engine = PlaybackEngine()
        engine.speed = 180
        let shortDuration = engine.displayDuration(for: "Hello.")
        let longDuration = engine.displayDuration(for: "This is a much longer sentence with many words in it.")
        #expect(longDuration > shortDuration)
    }

    @Test("Display duration has minimum floor")
    func displayDurationMinimum() {
        let engine = PlaybackEngine()
        engine.speed = 400
        let duration = engine.displayDuration(for: "Hi.")
        #expect(duration >= 1.2)
    }

    @Test("Toggle play/pause starts countdown at beginning")
    func toggleStartsCountdown() {
        let engine = PlaybackEngine()
        engine.showCountdown = true
        engine.currentIndex = 0
        engine.togglePlayPause(sentenceCount: 5)
        #expect(!engine.isPlaying)
        #expect(engine.countdownValue == 3)
    }

    // MARK: - Sentence Management

    @Test("setSentences stores parsed sentences")
    func setSentencesStoresParsed() {
        let engine = PlaybackEngine()
        engine.setSentences(from: "Hello world. How are you?")
        #expect(engine.sentences.count == 2)
    }

    @Test("setSentences with empty text produces empty array")
    func setSentencesEmpty() {
        let engine = PlaybackEngine()
        engine.setSentences(from: "")
        #expect(engine.sentences.isEmpty)
    }

    @Test("setSentences with whitespace-only text produces empty array")
    func setSentencesWhitespace() {
        let engine = PlaybackEngine()
        engine.setSentences(from: "   \n  ")
        #expect(engine.sentences.isEmpty)
    }

    @Test("currentSentence returns correct sentence for index")
    func currentSentenceAtIndex() {
        let engine = PlaybackEngine()
        engine.setSentences(from: "First sentence. Second sentence.")
        engine.currentIndex = 1
        #expect(engine.currentSentence == "Second sentence.")
    }

    @Test("currentSentence returns empty string when no sentences")
    func currentSentenceEmpty() {
        let engine = PlaybackEngine()
        #expect(engine.currentSentence == "")
    }

    @Test("currentSentence clamps to empty when index out of bounds")
    func currentSentenceOutOfBounds() {
        let engine = PlaybackEngine()
        engine.setSentences(from: "Only one.")
        engine.currentIndex = 5
        #expect(engine.currentSentence == "")
    }

    // MARK: - Advance Timer

    @Test("startAdvanceTimer schedules timer when playing with sentences")
    func startAdvanceTimerSchedules() {
        let engine = PlaybackEngine()
        engine.setSentences(from: "Hello world. Goodbye world.")
        engine.play(sentenceCount: 2)
        engine.startAdvanceTimer()
        #expect(engine.isAdvanceTimerActive)
    }

    @Test("startAdvanceTimer does nothing when not playing")
    func startAdvanceTimerNotPlaying() {
        let engine = PlaybackEngine()
        engine.setSentences(from: "Hello world.")
        engine.startAdvanceTimer()
        #expect(!engine.isAdvanceTimerActive)
    }

    @Test("startAdvanceTimer does nothing with empty sentences")
    func startAdvanceTimerNoSentences() {
        let engine = PlaybackEngine()
        engine.play(sentenceCount: 0)
        engine.startAdvanceTimer()
        #expect(!engine.isAdvanceTimerActive)
    }

    @Test("stopAdvanceTimer invalidates active timer")
    func stopAdvanceTimerInvalidates() {
        let engine = PlaybackEngine()
        engine.setSentences(from: "Hello world. Goodbye world.")
        engine.play(sentenceCount: 2)
        engine.startAdvanceTimer()
        engine.stopAdvanceTimer()
        #expect(!engine.isAdvanceTimerActive)
    }

    @Test("Pause invalidates advance timer")
    func pauseInvalidatesAdvanceTimer() {
        let engine = PlaybackEngine()
        engine.setSentences(from: "Hello. World.")
        engine.play(sentenceCount: 2)
        engine.startAdvanceTimer()
        engine.pause()
        #expect(!engine.isAdvanceTimerActive)
    }

    @Test("Reset invalidates advance timer")
    func resetInvalidatesAdvanceTimer() {
        let engine = PlaybackEngine()
        engine.setSentences(from: "Hello. World.")
        engine.play(sentenceCount: 2)
        engine.startAdvanceTimer()
        engine.reset()
        #expect(!engine.isAdvanceTimerActive)
    }

    @Test("advanceToNext uses sentence count from stored sentences")
    func advanceUsesStoredSentences() {
        let engine = PlaybackEngine()
        engine.setSentences(from: "First. Second. Third.")
        engine.advanceToNext()
        #expect(engine.currentIndex == 1)
        engine.advanceToNext()
        #expect(engine.currentIndex == 2)
        engine.advanceToNext()
        #expect(!engine.isPlaying)
    }

    @Test("progress string reflects current position")
    func progressString() {
        let engine = PlaybackEngine()
        engine.setSentences(from: "One. Two. Three.")
        #expect(engine.progress == "1 / 3")
        engine.advanceToNext()
        #expect(engine.progress == "2 / 3")
    }

    @Test("progress string is empty with no sentences")
    func progressStringEmpty() {
        let engine = PlaybackEngine()
        #expect(engine.progress == "")
    }

    // MARK: - State Change Efficiency

    @Test("setSentences skips reprocessing for identical text")
    func setSentencesCachesResult() {
        let engine = PlaybackEngine()
        engine.setSentences(from: "First. Second. Third.")
        #expect(engine.sentences.count == 3)
        engine.advanceToNext(sentenceCount: 3)
        let indexBefore = engine.currentIndex
        engine.setSentences(from: "First. Second. Third.")
        #expect(engine.currentIndex == indexBefore)
        #expect(engine.sentences.count == 3)
    }

    @Test("Countdown values are discrete integers only")
    func countdownValuesDiscrete() {
        let engine = PlaybackEngine()
        engine.showCountdown = true
        engine.togglePlayPause(sentenceCount: 5)
        #expect(engine.countdownValue == 3)
        engine.pause()
        #expect(engine.countdownValue == nil)
    }

    // MARK: - Hide from Recording

    @Test("hideFromRecording defaults to false")
    func hideFromRecordingDefault() {
        let engine = PlaybackEngine()
        #expect(!engine.hideFromRecording)
    }

    @Test("Toggling hideFromRecording updates value")
    func hideFromRecordingToggle() {
        let engine = PlaybackEngine()
        engine.hideFromRecording = true
        #expect(engine.hideFromRecording)
        engine.hideFromRecording = false
        #expect(!engine.hideFromRecording)
    }
}
