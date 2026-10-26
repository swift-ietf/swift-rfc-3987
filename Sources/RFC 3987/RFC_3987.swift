import ASCII

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

        return Grammar.isValidHierarchy(string[string.index(after: colonIndex)...])
    }

    public static func isValidHTTP(_ string: String) -> Bool {
        guard isValidIRI(string) else { return false }

        guard let colon = string.firstIndex(of: ":") else { return false }
        let scheme = string[..<colon].lowercased()
        return scheme == "http" || scheme == "https"
    }
}
