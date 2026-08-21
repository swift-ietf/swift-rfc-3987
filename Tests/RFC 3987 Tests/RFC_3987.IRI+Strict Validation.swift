import Testing

@testable import RFC_3987

extension RFC_3987.IRI {
    @Suite struct `Strict Validation` {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
    }
}

extension RFC_3987.IRI.`Strict Validation`.Unit {
    @Test
    func `authority with userinfo port query and fragment passes strict mode`() {
        #expect(
            RFC_3987.isValidIRI(
                "https://user:pass@example.com:8080/path?q=1&r=2#frag",
                mode: .strict
            )
        )
    }

    @Test
    func `IPv6 literal authority passes strict mode`() {
        #expect(RFC_3987.isValidIRI("https://[::1]:8080/path", mode: .strict))
    }

    @Test
    func `well formed percent encoding passes strict mode`() {
        #expect(RFC_3987.isValidIRI("https://example.com/hello%20world", mode: .strict))
    }

    @Test
    func `Unicode ucschar range passes strict mode`() {
        #expect(RFC_3987.isValidIRI("https://example.com/寿司", mode: .strict))
    }

    @Test
    func `validating initializer accepts a strict mode parameter`() throws {
        let iri = try RFC_3987.IRI("https://example.com/寿司", mode: .strict)
        #expect(iri.value == "https://example.com/寿司")
    }

    @Test
    func `validating initializer still defaults to lenient mode`() throws {

        let iri = try RFC_3987.IRI("https://example.com/hello world")
        #expect(iri.value == "https://example.com/hello world")
    }
}

extension RFC_3987.IRI.`Strict Validation`.`Edge Case` {
    @Test
    func `unescaped backslash is rejected by strict mode`() {
        #expect(!RFC_3987.isValidIRI("https://example.com/path\\backslash", mode: .strict))
    }

    @Test
    func `unescaped angle brackets are rejected by strict mode`() {
        #expect(!RFC_3987.isValidIRI("https://example.com/path<script>", mode: .strict))
    }

    @Test
    func `unescaped braces are rejected by strict mode`() {
        #expect(!RFC_3987.isValidIRI("https://example.com/a{b}c", mode: .strict))
    }

    @Test
    func `malformed percent encoding is rejected by strict mode`() {
        #expect(!RFC_3987.isValidIRI("https://example.com/hello%2world", mode: .strict))
    }

    @Test
    func `truncated percent encoding is rejected by strict mode`() {
        #expect(!RFC_3987.isValidIRI("https://example.com/hello%2", mode: .strict))
    }

    @Test
    func `validating initializer rejects strict-mode violations that lenient mode accepts`() {
        #expect(throws: RFC_3987.IRI.Error.self) {
            try RFC_3987.IRI("https://example.com/hello world", mode: .strict)
        }
    }
}
