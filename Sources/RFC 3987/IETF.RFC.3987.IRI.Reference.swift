extension IETF.RFC.`3987`.IRI {

    public struct Reference: Sendable, Hashable {

        public let value: String

        public init(_ value: String) throws(IETF.RFC.`3987`.IRI.Error) {
            guard IETF.RFC.`3987`.isValidIRIReference(value) else { throw .invalidIRI(value) }
            self.value = value
        }
    }
}
