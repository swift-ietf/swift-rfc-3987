import ASCII_Serializer_Primitives

public enum RFC_3987 {}

extension RFC_3987 {

    public static func isValidIRI(_ string: String, mode: ValidationMode = .lenient) -> Bool {

        guard !string.isEmpty else { return false }

        guard let colonIndex = string.firstIndex(of: ":") else { return false }

        let scheme = String(string[..<colonIndex])

        guard !scheme.isEmpty else { return false }

        guard mode == .strict else { return true }

        guard let firstChar = scheme.first,
            firstChar.ascii.isLetter
        else { return false }

        for char in scheme {
            guard char.ascii.isLetter || char.ascii.isDigit || "+-.".contains(char) else {
                return false
            }
        }

        for scalar in string.unicodeScalars {
            if (scalar.value >= 0x00 && scalar.value <= 0x1F)
                || (scalar.value >= 0x7F && scalar.value <= 0x9F)
            {
                return false
            }
        }

        if string.contains(" ") {
            return false
        }

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
                allowing: {
                    Grammar.isIPChar($0) || Grammar.isIPrivate($0) || $0 == "/" || $0 == "?"
                }
            )
        {
            return false
        }

        if let fragment,
            !Grammar.validate(
                fragment,
                allowing: { Grammar.isIPChar($0) || $0 == "/" || $0 == "?" }
            )
        {
            return false
        }

        return true
    }

    public static func isValidHTTP(_ string: String) -> Bool {
        guard isValidIRI(string) else { return false }

        return string.hasPrefix("http:") || string.hasPrefix("https:")
    }
}
