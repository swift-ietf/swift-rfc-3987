extension RFC_3987.IRI {

    /// An IRI's path, `ipath` in RFC 3987, which unlike `RFC_3986.URI.Path` may hold non-ASCII. It may be empty.
    public struct Path: Hashable, Sendable {

        public let value: String

        @_spi(Internal)
        public init(__unchecked: Void, value: String) {
            self.value = value
        }

        public init(_ value: String) throws(RFC_3987.IRI.Error) {
            guard RFC_3987.Grammar.validate(value, allowing: { RFC_3987.Grammar.isIPChar($0) || $0 == "/" }) else {
                throw .invalidPath(value)
            }
            self.init(__unchecked: (), value: value)
        }
    }
}

extension RFC_3987.IRI.Path: CustomStringConvertible {
    public var description: String {
        value
    }
}
