extension RFC_3987 {

    public static func isValidIRIReference(_ string: String) -> Bool {
        let segmentEnd = string.firstIndex(where: { $0 == "/" || $0 == "?" || $0 == "#" }) ?? string.endIndex
        guard string[..<segmentEnd].contains(":") else { return Grammar.isValidHierarchy(string) }
        return isValidIRI(string, mode: .strict)
    }
}
