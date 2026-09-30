import Testing

@testable import RFC_3987

@Suite
struct `HTTP scheme case` {
    @Test(arguments: ["HTTP://example.com", "Https://example.com/p", "hTtP://example.com"])
    func `an HTTP scheme is recognized in any case`(_ text: String) {
        #expect(RFC_3987.isValidHTTP(text))
    }

    @Test(arguments: ["httpx://example.com", "ftp://example.com", "http-s://example.com"])
    func `other schemes are not HTTP`(_ text: String) {
        #expect(!RFC_3987.isValidHTTP(text))
    }
}
