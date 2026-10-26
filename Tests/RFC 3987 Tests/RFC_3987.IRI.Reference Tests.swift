import RFC_3987
import Testing

extension RFC_3987.IRI.Reference {
    @Suite struct Test {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
    }
}

extension RFC_3987.IRI.Reference.Test.Unit {

    @Test(arguments: [
        "https://example.com/寿司?q=1#f",
        "urn:cdx:3e671687-395b-41f5-a30f-a58921a69b79/1#component",
        "mailto:jane@example.com",
    ])
    func `an absolute IRI is an IRI reference`(text: String) throws {
        #expect(try RFC_3987.IRI.Reference(text).value == text)
    }

    @Test(arguments: [
        "",
        "docs/寿司.html",
        "/path?query#fragment",
        "//example.com:8080/path",
        "../up/one",
        "?query",
        "#fragment",
        "a/b:c",
        "%E5%AF%BF%E5%8F%B8",
    ])
    func `a relative reference is an IRI reference`(text: String) throws {
        #expect(try RFC_3987.IRI.Reference(text).value == text)
    }
}

extension RFC_3987.IRI.Reference.Test.`Edge Case` {

    @Test
    func `a colon in the first segment makes it an absolute IRI with a scheme`() {
        #expect(throws: RFC_3987.IRI.Error.invalidIRI("1a:b")) { try RFC_3987.IRI.Reference("1a:b") }
        #expect(RFC_3987.isValidIRIReference("a:b"))
    }

    @Test
    func `white space and controls are refused`() {
        #expect(!RFC_3987.isValidIRIReference("docs/a b"))
        #expect(!RFC_3987.isValidIRIReference("docs/a\u{7}b"))
    }

    @Test
    func `malformed percent encoding is refused`() {
        #expect(!RFC_3987.isValidIRIReference("docs/%zz"))
    }

    @Test
    func `a second number sign is refused`() {
        #expect(!RFC_3987.isValidIRIReference("#a#b"))
    }

    @Test
    func `private-use characters are allowed in the query only`() {
        #expect(RFC_3987.isValidIRIReference("?\u{E000}"))
        #expect(!RFC_3987.isValidIRIReference("/\u{E000}"))
    }
}
