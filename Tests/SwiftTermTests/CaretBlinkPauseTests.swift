#if os(macOS)
import AppKit
import Testing
@testable import SwiftTerm

/// Typing pauses the caret's blink without replacing its Core Animation
/// animation on every key. Replacing it per key made a fullscreen window reach
/// the screen only a few times a second, so typed text showed up late and in
/// bursts. The blink is removed on the first key, comes back once when typing
/// pauses, and the keys in between leave Core Animation alone.
@MainActor
final class CaretBlinkPauseTests {
    private let blinkKey = #keyPath(CALayer.opacity)

    private func makeCaret(style: CursorStyle = .blinkBlock) throws -> (view: TerminalView, caret: CaretView) {
        let font = try #require(NSFont(name: "Menlo", size: 12))
        let view = TerminalView(frame: .zero, font: font)
        let caret = CaretView(frame: CGRect(x: 0, y: 0, width: 8, height: 16), cursorStyle: style, terminal: view)
        // Blink regardless of focus: the view is in no window, so it has none.
        caret.tracksFocus = false
        return (view, caret)
    }

    @Test func blinkingCaretStartsWithItsAnimation() throws {
        let fixture = try makeCaret()

        withExtendedLifetime(fixture.view) {
            #expect(fixture.caret.layer?.animation(forKey: blinkKey) != nil)
        }
    }

    @Test func firstKeyStopsTheBlinkAndShowsTheCaret() throws {
        let fixture = try makeCaret()

        withExtendedLifetime(fixture.view) {
            fixture.caret.resetBlinkAfterInput()

            #expect(fixture.caret.layer?.animation(forKey: blinkKey) == nil)
            #expect(fixture.caret.layer?.opacity == 1)
            #expect(fixture.caret.blinkResumeTimer?.isValid == true)
        }
    }

    @Test func laterKeysOnlyMoveTheTimer() throws {
        let fixture = try makeCaret()

        withExtendedLifetime(fixture.view) {
            fixture.caret.resetBlinkAfterInput()
            let firstTimer = fixture.caret.blinkResumeTimer

            fixture.caret.resetBlinkAfterInput()
            fixture.caret.resetBlinkAfterInput()

            #expect(fixture.caret.layer?.animation(forKey: blinkKey) == nil)
            #expect(firstTimer?.isValid == false)
            #expect(fixture.caret.blinkResumeTimer?.isValid == true)
        }
    }

    @Test func blinkComesBackWhenTypingPauses() throws {
        let fixture = try makeCaret()

        withExtendedLifetime(fixture.view) {
            fixture.caret.resetBlinkAfterInput()

            fixture.caret.blinkResumeTimer?.fire()

            #expect(fixture.caret.layer?.animation(forKey: blinkKey) != nil)
            #expect(fixture.caret.blinkResumeTimer == nil)
        }
    }

    @Test func switchingToASteadyCaretCancelsThePendingBlink() throws {
        let fixture = try makeCaret()

        withExtendedLifetime(fixture.view) {
            fixture.caret.resetBlinkAfterInput()
            let timer = fixture.caret.blinkResumeTimer

            fixture.caret.style = .steadyBlock

            #expect(timer?.isValid == false)
            #expect(fixture.caret.blinkResumeTimer == nil)
            #expect(fixture.caret.layer?.animation(forKey: blinkKey) == nil)
        }
    }

    @Test func disablingAnimationsCancelsThePendingBlink() throws {
        let fixture = try makeCaret()

        withExtendedLifetime(fixture.view) {
            fixture.caret.resetBlinkAfterInput()
            let timer = fixture.caret.blinkResumeTimer

            fixture.caret.disableAnimations()

            #expect(timer?.isValid == false)
            #expect(fixture.caret.blinkResumeTimer == nil)
            #expect(fixture.caret.layer?.animation(forKey: blinkKey) == nil)
        }
    }

    @Test func steadyCaretIgnoresTyping() throws {
        let fixture = try makeCaret(style: .steadyBlock)

        withExtendedLifetime(fixture.view) {
            fixture.caret.resetBlinkAfterInput()

            #expect(fixture.caret.blinkResumeTimer == nil)
            #expect(fixture.caret.layer?.animation(forKey: blinkKey) == nil)
        }
    }
}
#endif
