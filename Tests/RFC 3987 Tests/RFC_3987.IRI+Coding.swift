import Foundation
import Testing

@testable import RFC_3987

extension RFC_3987.IRI {
    @Suite struct Coding {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
    }
}

extension RFC_3987.IRI.Coding.Unit {
    @Test
    func `round trips through JSON`() throws {
        let original = try RFC_3987.IRI("https://example.com/寿司")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RFC_3987.IRI.self, from: data)
        #expect(decoded == original)
    }

    @Test
    func `encodes as a JSON string, not a keyed object`() throws {
        let iri = try RFC_3987.IRI("https://example.com/path")
        let data = try JSONEncoder().encode(iri)
        let jsonValue = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        #expect(jsonValue is String)
    }
}

extension RFC_3987.IRI.Coding.`Edge Case` {
    @Test
    func `decoding an empty string surfaces the specific empty-IRI reason`() {
        let data = Data("\"\"".utf8)
        do {
            _ = try JSONDecoder().decode(RFC_3987.IRI.self, from: data)
            Issue.record("expected decoding to throw")
        } catch let DecodingError.dataCorrupted(context) {
            #expect(context.debugDescription == RFC_3987.IRI.Error.empty.description)
        } catch {
            Issue.record("expected DecodingError.dataCorrupted, got \(error)")
        }
    }

    @Test
    func `decoding a schemeless string surfaces the specific invalid-IRI reason`() {
        let data = Data("\"not-a-valid-iri\"".utf8)
        do {
            _ = try JSONDecoder().decode(RFC_3987.IRI.self, from: data)
            Issue.record("expected decoding to throw")
        } catch let DecodingError.dataCorrupted(context) {
            #expect(
                context.debugDescription
                    == RFC_3987.IRI.Error.invalidIRI("not-a-valid-iri").description
            )
        } catch {
            Issue.record("expected DecodingError.dataCorrupted, got \(error)")
        }
    }
}
