import RFC_3987
import Testing

@Suite
struct `RFC_3987.IRI.Path Tests` {

    @Test
    func `A path may hold non-ASCII and may be empty`() throws {
        #expect(try RFC_3987.IRI.Path("/a/寿司").value == "/a/寿司")
        #expect(try RFC_3987.IRI.Path("").value == "")
    }

    @Test(arguments: ["/a b", "/a%zz", "/a?b", "/a#b"])
    func `Anything outside ipath is refused`(text: String) {
        #expect(throws: RFC_3987.IRI.Error.invalidPath(text)) {
            _ = try RFC_3987.IRI.Path(text)
        }
    }

    @Test
    func `Dot segments are removed around non-ASCII`() throws {
        #expect(RFC_3987.removeDotSegments(from: try RFC_3987.IRI.Path("/a/寿司/../b")).value == "/a/b")
    }
}
