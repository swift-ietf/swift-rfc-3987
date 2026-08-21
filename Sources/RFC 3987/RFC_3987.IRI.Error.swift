extension RFC_3987.IRI {

    public enum Error: Swift.Error, Sendable, Equatable {

        case empty

        case invalidIRI(String)

        case invalidURI(String)

        case conversionFailed(String)
    }
}

extension RFC_3987.IRI.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .empty:
            return "IRI cannot be empty"

        case .invalidIRI(let value):
            return "Invalid IRI: '\(value)'"

        case .invalidURI(let value):
            return "Invalid URI: '\(value)'"

        case .conversionFailed(let value):
            return "Failed to convert IRI: '\(value)'"
        }
    }
}
