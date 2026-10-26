extension RFC_3987.Grammar {

    static func isValidHierarchy(_ text: some StringProtocol) -> Bool {
        for scalar in text.unicodeScalars {
            if (scalar.value >= 0x00 && scalar.value <= 0x1F)
                || (scalar.value >= 0x7F && scalar.value <= 0x9F)
            {
                return false
            }
        }

        if text.contains(" ") {
            return false
        }

        var rest = Substring(text)

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
            !Self.validate(
                authority,
                allowing: {
                    Self.isIUnreserved($0) || Self.isSubDelim($0)
                        || $0 == ":" || $0 == "@" || $0 == "[" || $0 == "]"
                }
            )
        {
            return false
        }

        guard Self.validate(path, allowing: { Self.isIPChar($0) || $0 == "/" }) else {
            return false
        }

        if let query,
            !Self.validate(
                query,
                allowing: {
                    Self.isIPChar($0) || Self.isIPrivate($0) || $0 == "/" || $0 == "?"
                }
            )
        {
            return false
        }

        if let fragment,
            !Self.validate(
                fragment,
                allowing: { Self.isIPChar($0) || $0 == "/" || $0 == "?" }
            )
        {
            return false
        }

        return true
    }
}
