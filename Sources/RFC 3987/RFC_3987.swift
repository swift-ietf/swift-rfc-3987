import ASCII_Serializer_Primitives

/// RFC 3987: Internationalized Resource Identifiers (IRIs)
///
/// IRIs are a complement to URIs (RFC 3986) that allow the use of
/// Unicode characters from the Universal Character Set (Unicode/ISO 10646).
///
/// ## Key Types
///
/// - ``IRI``: An Internationalized Resource Identifier
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
public enum RFC_3987 {}

// MARK: - Validation

extension RFC_3987 {
    /// Validates if a string is a valid IRI using Foundation-free validation
    ///
    /// - Parameters:
    ///   - string: The string to validate
    ///   - mode: Validation mode (lenient or strict). Default is lenient.
    /// - Returns: true if the string appears to be a valid IRI
    ///
    /// ## Validation Rules
    ///
    /// ### Lenient Mode (Default)
    /// - Must not be empty
    /// - Must contain a scheme (e.g., http:, https:, urn:)
    /// - Basic structural validation
    ///
    /// ### Strict Mode
    /// - All lenient mode rules
    /// - Validates scheme format: ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
    /// - Rejects control characters (U+0000 to U+001F, U+007F-U+009F)
    /// - Rejects unencoded space characters
    /// - Validates the authority, path, query, and fragment components against
    ///   the RFC 3987 ABNF (Section 2.2): every character must be `iunreserved`
    ///   (`ALPHA` / `DIGIT` / `"-"` / `"."` / `"_"` / `"~"` / `ucschar`),
    ///   `sub-delims`, a well-formed `pct-encoded` (`"%" HEXDIG HEXDIG`) triplet,
    ///   or one of the component's own structural separators (e.g. `":"` / `"@"`
    ///   in authority and path, `"/"` / `"?"` in query and fragment). `iprivate`
    ///   is additionally permitted in the query component only, per the grammar.
    ///
    /// - Note: For more comprehensive validation using Foundation's URL parser,
    ///   use the Foundation extensions which provide additional validation capabilities.
    public static func isValidIRI(_ string: String, mode: ValidationMode = .lenient) -> Bool {
        // Empty strings are not valid IRIs
        guard !string.isEmpty else { return false }

        // IRIs must have a scheme (e.g., "http:", "https:", "urn:")
        // Scheme is everything before the first ":"
        guard let colonIndex = string.firstIndex(of: ":") else { return false }

        let scheme = String(string[..<colonIndex])

        // Scheme must not be empty
        guard !scheme.isEmpty else { return false }

        // Lenient mode: just check basic structure
        guard mode == .strict else { return true }

        // Strict mode: validate scheme format
        // Per RFC 3987: scheme = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
        // Schemes must be ASCII per RFC 3987 Section 2.2
        guard let firstChar = scheme.first,
            firstChar.ascii.isLetter
        else { return false }

        for char in scheme {
            guard char.ascii.isLetter || char.ascii.isDigit || "+-.".contains(char) else {
                return false
            }
        }

        // Check for control characters (U+0000 to U+001F, U+007F-U+009F)
        for scalar in string.unicodeScalars {
            if (scalar.value >= 0x00 && scalar.value <= 0x1F)
                || (scalar.value >= 0x7F && scalar.value <= 0x9F)
            {
                return false
            }
        }

        // Check for unencoded spaces
        if string.contains(" ") {
            return false
        }

        // Validate the remaining components (authority, path, query, fragment)
        // against the RFC 3987 ABNF character classes and percent-encoding rule.
        //
        //   ihier-part = "//" iauthority ipath-abempty
        //              / ipath-absolute / ipath-rootless / ipath-empty
        //   IRI        = scheme ":" ihier-part [ "?" iquery ] [ "#" ifragment ]
        //
        // Authority (userinfo/host/port) is validated as the union of the
        // character classes its sub-components allow — this is a permissive
        // over-approximation of `iauthority`'s finer IP-literal/IPv4/reg-name
        // structure, not a full sub-parse of it.
        var rest = string[string.index(after: colonIndex)...]

        var authority: Substring?
        if rest.hasPrefix("//") {
            let afterSlashes = rest.dropFirst(2)
            let authorityEnd =
                afterSlashes.firstIndex(where: { $0 == "/" || $0 == "?" || $0 == "#" })
                ?? afterSlashes.endIndex
            authority = afterSlashes[afterSlashes.startIndex..<authorityEnd]
            rest = afterSlashes[authorityEnd...]
        }

        let pathEnd = rest.firstIndex(where: { $0 == "?" || $0 == "#" }) ?? rest.endIndex
        let path = rest[rest.startIndex..<pathEnd]
        var afterPath = rest[pathEnd...]

        var query: Substring?
        if afterPath.first == "?" {
            afterPath = afterPath.dropFirst()
            let queryEnd = afterPath.firstIndex(of: "#") ?? afterPath.endIndex
            query = afterPath[afterPath.startIndex..<queryEnd]
            afterPath = afterPath[queryEnd...]
        }

        let fragment: Substring? = afterPath.first == "#" ? afterPath.dropFirst() : nil

        if let authority,
            !Grammar.validate(
                authority,
                allowing: {
                    Grammar.isIUnreserved($0) || Grammar.isSubDelim($0)
                        || $0 == ":" || $0 == "@" || $0 == "[" || $0 == "]"
                }
            )
        {
            return false
        }

        guard Grammar.validate(path, allowing: { Grammar.isIPChar($0) || $0 == "/" }) else {
            return false
        }

        if let query,
            !Grammar.validate(
                query,
                allowing: { Grammar.isIPChar($0) || Grammar.isIPrivate($0) || $0 == "/" || $0 == "?" }
            )
        {
            return false
        }

        if let fragment,
            !Grammar.validate(fragment, allowing: { Grammar.isIPChar($0) || $0 == "/" || $0 == "?" })
        {
            return false
        }

        return true
    }

    /// Validates if an IRI string represents an HTTP or HTTPS IRI
    ///
    /// - Parameter string: The IRI string to validate
    /// - Returns: true if the IRI has an http or https scheme
    public static func isValidHTTP(_ string: String) -> Bool {
        guard isValidIRI(string) else { return false }

        return string.hasPrefix("http:") || string.hasPrefix("https:")
    }
}
