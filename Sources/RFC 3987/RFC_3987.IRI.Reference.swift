extension RFC_3987.IRI {

    public struct Reference: Sendable, Hashable {

        public let value: String

        public init(_ value: String) throws(RFC_3987.IRI.Error) {
            guard RFC_3987.isValidIRIReference(value) else { throw .invalidIRI(value) }
            self.value = value
        }
    }
}
