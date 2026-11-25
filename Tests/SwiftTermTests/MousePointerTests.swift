//
//  MousePointerTests.swift
//
//  The pointer over the macOS view: the I-beam, or, when the host opts in, an arrow
//  while the application receives mouse reports, as in Ghostty.
//
#if os(macOS)
import AppKit
import Testing

@testable import SwiftTerm

@MainActor
struct MousePointerTests {
    private func makeView() -> TerminalView {
        TerminalView(frame: CGRect(x: 0, y: 0, width: 320, height: 160))
    }

    @Test func pointerIsTheIBeamByDefaultEvenWhileReportingMouse() {
        let view = makeView()
        view.feed(text: "\u{1b}[?1000h")

        #expect(view.pointer == NSCursor.iBeam)
    }

    @Test func optedInPointerIsAnArrowWhileReportingMouse() {
        let view = makeView()
        view.pointsWithArrowWhileReportingMouse = true
        view.feed(text: "\u{1b}[?1000h")

        #expect(view.pointer == NSCursor.arrow)
    }

    @Test func optedInPointerIsTheIBeamOnceReportingStops() {
        let view = makeView()
        view.pointsWithArrowWhileReportingMouse = true
        view.feed(text: "\u{1b}[?1000h\u{1b}[?1000l")

        #expect(view.pointer == NSCursor.iBeam)
    }

    @Test func optedInPointerIsTheIBeamWhenTheHostDisallowsReporting() {
        let view = makeView()
        view.pointsWithArrowWhileReportingMouse = true
        view.allowMouseReporting = false
        view.feed(text: "\u{1b}[?1000h")

        #expect(view.pointer == NSCursor.iBeam)
    }
}
#endif
