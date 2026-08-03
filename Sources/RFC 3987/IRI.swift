public import ASCII_Serializer_Primitives
public import Binary_Serializable_Primitives
public import Parseable_ASCII_Primitives

extension RFC_3987 {
    /// An Internationalized Resource Identifier (IRI) as defined in RFC 3987
    ///
    /// IRIs are a complement to URIs (RFC 3986) that allow the use of
    /// Unicode characters from the Universal Character Set (Unicode/ISO 10646).
    ///
    /// ## Constraints
    ///
    /// Per RFC 3987:
    /// - Must contain a valid scheme
    /// - May contain Unicode characters (unlike URIs)
    /// - Control characters are not permitted
    ///
    /// ## Example
    ///
    /// ```swift
    /// let iri = try RFC_3987.IRI("https://example.com/寿司")
    /// ```
    ///
    /// ## See Also
    ///
    /// - [RFC 3987](https://www.rfc-editor.org/rfc/rfc3987)
    public struct IRI: Hashable, Sendable, Codable {
        /// The IRI string value
        public let value: String

        /// Creates an IRI WITHOUT validation
        ///
        /// **Warning**: Bypasses RFC validation. Only use for:
        /// - Static constants
        /// - Pre-validated values
        /// - Internal construction after validation
        @_spi(Internal)
        public init(__unchecked: Void, value: String) {
            self.value = value
        }

        /// Creates an IRI from a string with validation
        ///
        /// This initializer validates the IRI and throws an error if invalid.
        ///
        /// ## Example
        ///
        /// ```swift
        /// let iri = try RFC_3987.IRI("https://example.com/寿司")
        /// let strict = try RFC_3987.IRI("https://example.com/寿司", mode: .strict)
        /// ```
        ///
        /// - Parameters:
        ///   - value: The IRI string
        ///   - mode: Validation mode (lenient or strict). Default is `.lenient`,
        ///     matching this initializer's prior (unparameterized) behavior — no
        ///     existing caller's accepted-input set changes unless it opts in.
        /// - Throws: `Error.invalidIRI` if the string is not a valid IRI under `mode`
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

// MARK: - Codable

extension RFC_3987.IRI {
    /// Decodes an IRI from a single-value JSON string, validating it via the
    /// throwing initializer.
    ///
    /// The wire format is pinned explicitly here rather than left to whichever
    /// derivation the compiler happens to pick (synthesized memberwise vs. the
    /// standard library's `RawRepresentable`-conditional `Decodable` default):
    /// a single string, never a keyed `{"value": ...}` object.
    ///
    /// - Throws: `DecodingError.dataCorrupted` if the decoded string is not a
    ///   valid RFC 3987 IRI (mapped from `RFC_3987.IRI.Error`).
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

    /// Encodes the IRI as a single-value JSON string (its `value`), matching
    /// the format `init(from:)` decodes.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

// MARK: - Serialization

extension RFC_3987.IRI: Swift.RawRepresentable, ASCII.Serializable, Binary.Serializable {
    /// The IRI's underlying string value — the `Swift.RawRepresentable` raw value.
    public var rawValue: String {
        value
    }

    /// Creates an IRI by validating `rawValue`, or `nil` if it is not a valid RFC 3987 IRI.
    ///
    /// Re-provides the `Swift.RawRepresentable` requirement (previously inherited
    /// from the retired combined ASCII serializable protocol).
    public init?(rawValue: String) {
        do throws(RFC_3987.IRI.Error) {
            try self.init(rawValue)
        } catch {
            return nil
        }
    }

    /// Serializes `value` as its UTF-8 bytes into an ASCII-code buffer ([FAM-012] verb).
    ///
    /// Own `ASCII.Serializable` verb — replaces the retired canonical-serializer
    /// derivation, inlining exactly what the `String`-RawRepresentable serializer
    /// produced. IRIs may include non-ASCII characters; the UTF-8 bytes are carried
    /// on the ASCII-code substrate exactly as before (byte output preserved).
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {
        for byte in value.rawValue.utf8 {
            buffer.append(ASCII.Code(byte))
        }
    }

    /// Serializes `value` as its UTF-8 bytes into `buffer`.
    ///
    /// Explicit `Binary.Serializable` witness; the bytes derive from the
    /// `ASCII.Serializable` verb above (`.serialized`).
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        buffer.append(contentsOf: value.serialized)
    }
}

// MARK: - ASCII.Parseable

extension RFC_3987.IRI: ASCII.Parseable {
    /// Parse IRI from UTF-8 bytes
    ///
    /// ## Category Theory
    ///
    /// Parsing transformation:
    /// - **Domain**: [Byte] (UTF-8 bytes)
    /// - **Codomain**: RFC_3987.IRI (structured data)
    ///
    /// ## Example
    ///
    /// ```swift
    /// let iri = try RFC_3987.IRI(ascii: "https://example.com".utf8)
    /// ```
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

// MARK: - Protocol Conformances

extension RFC_3987.IRI {

    /// Protocol for types that can represent IRIs
    ///
    /// Types conforming to this protocol can be used interchangeably wherever an IRI
    /// is expected, including Foundation's `URL` type.
    ///
    /// Example:
    /// ```swift
    /// func process(iri: any RFC_3987.IRI.Representable) {
    ///     print(iri.iriString)
    /// }
    ///
    /// let url = URL(string: "https://example.com")!
    /// process(iri: url)  // Works!
    /// ```
    public protocol Representable {
        /// The IRI representation
        var iri: RFC_3987.IRI { get }
    }
}

extension RFC_3987 {

    // MARK: - Path Normalization

    /// Removes dot segments from a path per RFC 3986 Section 5.2.4
    ///
    /// This algorithm removes "." and ".." segments from paths to produce
    /// a normalized path. For example:
    /// - `/a/b/c/./../../g` → `/a/g`
    /// - `/./a/b/` → `/a/b/`
    ///
    /// - Parameter path: The path to normalize
    /// - Returns: The path with dot segments removed
    ///
    /// - Note: Cyclomatic complexity inherent to RFC 3986 Section 5.2.4 algorithm
    public static func removeDotSegments(from path: String) -> String {
        var input = path
        var output = ""

        while !input.isEmpty {
            // A: If the input buffer begins with a prefix of "../" or "./"
            if input.hasPrefix("../") {
                input.removeFirst(3)
            } else if input.hasPrefix("./") {
                input.removeFirst(2)
            }
            // B: If the input buffer begins with a prefix of "/./" or "/."
            else if input.hasPrefix("/./") {
                input = "/" + input.dropFirst(3)
            } else if input == "/." {
                input = "/"
            }
            // C: If the input buffer begins with a prefix of "/../" or "/.."
            else if input.hasPrefix("/../") {
                input = "/" + input.dropFirst(4)
                // Remove the last segment from output
                if let lastSlash = output.lastIndex(of: "/") {
                    output = String(output[..<lastSlash])
                }
            } else if input == "/.." {
                input = "/"
                if let lastSlash = output.lastIndex(of: "/") {
                    output = String(output[..<lastSlash])
                }
            }
            // D: If the input buffer consists only of "." or ".."
            else if input == "." || input == ".." {
                input = ""
            }
            // E: Move the first path segment to output
            else {
                // Find the next "/" after the first character
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

// MARK: - IRI.Representable Protocol Extension

extension RFC_3987.IRI.Representable {
    /// The IRI as a string (convenience)
    public var iriString: String {
        iri.value
    }
}

// MARK: - IRI.Representable Conformance

extension RFC_3987.IRI: RFC_3987.IRI.Representable {
    public var iri: RFC_3987.IRI {
        self
    }
}

// MARK: - ExpressibleByStringLiteral

extension RFC_3987.IRI: ExpressibleByStringLiteral {
    /// Creates an IRI from a string literal without validation
    ///
    /// ## Example
    ///
    /// ```swift
    /// let iri: RFC_3987.IRI = "https://example.com/path"
    /// ```
    ///
    /// - Note: This does not perform validation. For validated creation,
    ///   use `try RFC_3987.IRI("string")`.
    public init(stringLiteral value: String) {
        self.init(__unchecked: (), value: value)
    }
}

// MARK: - CustomStringConvertible

extension RFC_3987.IRI: CustomStringConvertible {
    public var description: String {
        value
    }
}

// MARK: - CustomDebugStringConvertible

extension RFC_3987.IRI: CustomDebugStringConvertible {
    public var debugDescription: String {
        "IRI(\"\(value)\")"
    }
}
