public import Foundation
@_spi(Internal) public import RFC_3987

extension URL {

    public enum IRIConversionError: Swift.Error, CustomStringConvertible {
        case invalidIRI(String)
    }

    public init(iri: RFC_3987.IRI) throws(IRIConversionError) {

        if let url = URL(string: iri.value) {
            self = url
            return
        }

        var allowedCharacters = CharacterSet.urlFragmentAllowed
        allowedCharacters.formUnion(.urlHostAllowed)
        allowedCharacters.formUnion(.urlPathAllowed)
        allowedCharacters.formUnion(.urlQueryAllowed)

        let encoded =
            iri.value.addingPercentEncoding(
                withAllowedCharacters: allowedCharacters
            ) ?? iri.value

        guard let url = URL(string: encoded) else {
            throw IRIConversionError.invalidIRI(iri.value)
        }

        self = url
    }
}

extension URL.IRIConversionError {
    public var description: String {
        switch self {
        case .invalidIRI(let iri):
            return
                "Failed to convert IRI to URL. The IRI '\(iri)' is malformed and could not be converted to a valid URL even after percent-encoding."
        }
    }
}

extension RFC_3987.IRI {

    public var uriString: String {

        guard let url = URL(string: value) else {
            return value
        }

        return url.absoluteString
    }

    public init(url: URL) {
        self.init(
            __unchecked: (),
            value: url.absoluteString
        )
    }

    public func normalized() -> RFC_3987.IRI {
        guard let url = URL(string: value) else {
            return self
        }

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return self
        }

        if let scheme = components.scheme {
            components.scheme = scheme.lowercased()
        }
        if let host = components.host {
            components.host = host.lowercased()
        }

        if let scheme = components.scheme, let port = components.port {
            let defaultPort =
                (scheme == "http" && port == 80) || (scheme == "https" && port == 443)
                || (scheme == "ftp" && port == 21)
            if defaultPort {
                components.port = nil
            }
        }

        if let scheme = components.scheme,
            ["http", "https"].contains(scheme),
            components.path.isEmpty
        {
            components.path = "/"
        }

        let path = components.path
        if !path.isEmpty {
            components.path = RFC_3987.removeDotSegments(from: path)
        }

        guard let normalizedURL = components.url else {
            return self
        }

        return RFC_3987.IRI(
            __unchecked: (),
            value: normalizedURL.absoluteString
        )
    }
}

extension URL: RFC_3987.IRI.Representable {

    public var iri: RFC_3987.IRI {
        RFC_3987.IRI(
            __unchecked: (),
            value: absoluteString
        )
    }
}

extension RFC_3987 {

    public static func isValidIRIWithFoundation(
        _ string: String,
        mode: ValidationMode = .lenient
    ) -> Bool {

        guard !string.isEmpty else { return false }

        guard let url = URL(string: string) else { return false }

        guard let scheme = url.scheme else { return false }

        if mode == .strict {
            return validateStrictWithFoundation(string: string, url: url, scheme: scheme)
        }

        return true
    }

    private static func validateStrictWithFoundation(
        string: String,
        url: URL,
        scheme: String
    ) -> Bool {

        let schemePattern = "^[a-zA-Z][a-zA-Z0-9+.-]*$"
        guard scheme.range(of: schemePattern, options: .regularExpression) != nil else {
            return false
        }

        let controlCharacterRange = CharacterSet.controlCharacters
        if string.rangeOfCharacter(from: controlCharacterRange) != nil {
            return false
        }

        if string.contains(" ") {
            return false
        }

        if let fragment = url.fragment {

            if fragment.isEmpty {
                return false
            }
        }

        return true
    }

    public static func isValidHTTP(_ iri: some IRI.Representable) -> Bool {
        guard let url = URL(string: iri.iriString) else { return false }
        return url.scheme == "http" || url.scheme == "https"
    }
}
