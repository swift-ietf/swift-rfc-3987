import Testing

@testable import RFC_3987

@Suite
struct `Percent encoding hex digits` {
    @Test
    func `fullwidth hex digits after a percent sign are rejected`() {
        #expect(!RFC_3987.isValidIRI("http://example.com/%ＡＡ", mode: .strict))
        #expect(!RFC_3987.isValidIRI("http://example.com/%０１", mode: .strict))
    }

    @Test
    func `a combining mark on a percent sign does not hide it`() {
        #expect(!RFC_3987.isValidIRI("http://example.com/%\u{301}41", mode: .strict))
    }

    @Test
    func `ASCII hex digits in either case are accepted`() {
        #expect(RFC_3987.isValidIRI("http://example.com/%4a%4A", mode: .strict))
    }
}
