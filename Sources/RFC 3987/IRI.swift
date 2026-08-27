public import ASCII_Serializer
public import Binary_Serializable
public import Parseable_ASCII

extension RFC_3987 {

    public struct IRI: Hashable, Sendable, Codable {

        public let value: String

        @_spi(Internal)
        public init(__unchecked: Void, value: String) {
            self.value = value
        }

        public init(
            _ value: String,
            mode: RFC_3987.ValidationMode = .lenient
        ) throws(Error) {
            guard !value.isEmpty else {
                throw Error.empty
            }
            guard RFC_3987.isValidIRI(value, mode: mode) else {
                throw Error.invalidIRI(value)
            }
            self.init(__unchecked: (), value: value)
        }
    }
}

extension RFC_3987.IRI {

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        do {
            try self.init(string)
        } catch {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: error.description
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

extension RFC_3987.IRI: Swift.RawRepresentable, ASCII.Serializable, Binary.Serializable {

    public var rawValue: String {
        value
    }

    public init?(rawValue: String) {
        do throws(RFC_3987.IRI.Error) {
            try self.init(rawValue)
        } catch {
            return nil
        }
    }

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {
        for byte in value.rawValue.utf8 {
            buffer.append(ASCII.Code(byte))
        }
    }

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        buffer.append(contentsOf: value.serialized)
    }
}

extension RFC_3987.IRI: ASCII.Parseable {

    public init<Bytes: Swift.Collection>(
        ascii bytes: Bytes
    ) throws(Error) where Bytes.Element == Byte {
        guard !bytes.isEmpty else {
            throw Error.empty
        }
        let string = String(decoding: bytes, as: UTF8.self)

        try self.init(string)
    }
}

extension RFC_3987.IRI {

    public protocol Representable {

        var iri: RFC_3987.IRI { get }
    }
}

extension RFC_3987 {

    public static func removeDotSegments(from path: String) -> String {
        var input = path
        var output = ""

        while !input.isEmpty {

            if input.hasPrefix("../") {
                input.removeFirst(3)
            } else if input.hasPrefix("./") {
                input.removeFirst(2)
            }

            else if input.hasPrefix("/./") {
                input = "/" + input.dropFirst(3)
            } else if input == "/." {
                input = "/"
            }

            else if input.hasPrefix("/../") {
                input = "/" + input.dropFirst(4)

                if let lastSlash = output.lastIndex(of: "/") {
                    output = String(output[..<lastSlash])
                }
            } else if input == "/.." {
                input = "/"
                if let lastSlash = output.lastIndex(of: "/") {
                    output = String(output[..<lastSlash])
                }
            }

            else if input == "." || input == ".." {
                input = ""
            }

            else {

                let startIndex = input.index(after: input.startIndex)
                if let slashIndex = input[startIndex...].firstIndex(of: "/") {
                    let segment = String(input[..<slashIndex])
                    output += segment
                    input = String(input[slashIndex...])
                } else {
                    output += input
                    input = ""
                }
            }
        }

        return output
    }
}

extension RFC_3987.IRI.Representable {

    public var iriString: String {
        iri.value
    }
}

extension RFC_3987.IRI: RFC_3987.IRI.Representable {
    public var iri: RFC_3987.IRI {
        self
    }
}

extension RFC_3987.IRI: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        self.init(__unchecked: (), value: value)
    }
}

extension RFC_3987.IRI: CustomStringConvertible {
    public var description: String {
        value
    }
}

extension RFC_3987.IRI: CustomDebugStringConvertible {
    public var debugDescription: String {
        "IRI(\"\(value)\")"
    }
}
