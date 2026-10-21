import Foundation
import Testing

@testable import RFC_3987
@testable import RFC_3987_Foundation

@Suite
struct `README Verification` {

    @Test
    func `Creating IRIs - from string literal`() {

        let iri: RFC_3987.IRI = "https://example.com/path"

        #expect(iri.value == "https://example.com/path")
    }

    @Test
    func `Creating IRIs - with validation`() throws {

        let validatedIRI: RFC_3987.IRI = try .init("https://example.com/寿司")

        #expect(validatedIRI.value == "https://example.com/寿司")
    }

    @Test
    func `Using Foundation URL - IRI.Representable conformance`() {

        let url = URL(string: "https://example.com")!

        func process(iri: any RFC_3987.IRI.Representable) -> String {
            return iri.iriString
        }

        let result = process(iri: url)
        #expect(result == "https://example.com")
    }

    @Test
    func `Using Foundation URL - HTTP validation`() {

        let url = URL(string: "https://example.com")!
        let isValid = RFC_3987.isValidHTTP(url)

        #expect(isValid == true)
    }

    @Test
    func `Validation - validate IRI string`() {

        let isValid = RFC_3987.isValidIRI("https://example.com")

        #expect(isValid == true)
    }

    @Test
    func `Validation - validate HTTP specifically`() {

        let isValid = RFC_3987.isValidHTTP("https://example.com")

        #expect(isValid == true)
    }

    @Test
    func `Validation - validate IRI.Representable types`() {

        let url = URL(string: "https://example.com")!
        let isValid = RFC_3987.isValidHTTP(url)

        #expect(isValid == true)
    }

    @Test
    func `Normalization example`() throws {

        let iri: RFC_3987.IRI = try .init("HTTPS://EXAMPLE.COM:443/path")
        let normalized = iri.normalized()

        #expect(normalized.value == "https://example.com/path")
    }

    @Test
    func `URI Conversion example`() throws {

        let iri: RFC_3987.IRI = try .init("https://example.com/hello world")
        let asciiString = iri.uriString

        #expect(asciiString.contains("example.com"))
        #expect(asciiString.contains("hello"))
    }

    @Test
    func `IRI vs URI - IRI with Unicode`() throws {

        let iri: RFC_3987.IRI = try .init("https://例え.jp/寿司")

        #expect(iri.value.contains("例え"))
        #expect(iri.value.contains("寿司"))
    }

    @Test
    func `RFC 3987 Compliance - requires scheme`() {

        let withScheme = RFC_3987.isValidIRI("https://example.com")
        let withoutScheme = RFC_3987.isValidIRI("example.com")

        #expect(withScheme == true)
        #expect(withoutScheme == false)
    }

    @Test
    func `RFC 3987 Compliance - accepts Unicode`() throws {

        let unicodeIRI: RFC_3987.IRI = try .init("https://example.com/日本語")

        #expect(unicodeIRI.value.contains("日本語"))
    }

    @Test
    func `Protocol-based design - IRI.Representable`() {

        let url = URL(string: "https://test.com")!

        let representable: any RFC_3987.IRI.Representable = url
        #expect(representable.iriString == "https://test.com")
    }
}
