public import Foundation
@_spi(Internal) public import RFC_3987

extension URL {

    public enum IRIConversionError: Swift::Error, CustomStringConvertible {
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
        guard let colon = value.firstIndex(of: ":") else {
            return self
        }
        let scheme = value[..<colon].lowercased()
        var rest = Substring(value[value.index(after: colon)...])
        var result = scheme + ":"

        let suffixStart = rest.firstIndex { $0 == "?" || $0 == "#" } ?? rest.endIndex
        let suffix = rest[suffixStart...]
        rest = rest[..<suffixStart]

        var path = rest
        if rest.hasPrefix("//") {
            let afterSlashes = rest.index(rest.startIndex, offsetBy: 2)
            let authorityEnd = rest[afterSlashes...].firstIndex(of: "/") ?? rest.endIndex
            result += "//" + Self.normalizedAuthority(rest[afterSlashes..<authorityEnd], scheme: scheme)
            path = rest[authorityEnd...]
            if path.isEmpty, scheme == "http" || scheme == "https" {
                path = "/"
            }
        }

        if path.hasPrefix("/") {
            result += RFC_3987.removeDotSegments(from: RFC_3987.IRI.Path(__unchecked: (), value: String(path))).value
        } else {
            result += path
        }
        result += suffix

        return RFC_3987.IRI(__unchecked: (), value: result)
    }

    private static func normalizedAuthority(_ authority: Substring, scheme: String) -> String {
        var userinfo = ""
        var hostPort = authority
        if let at = authority.lastIndex(of: "@") {
            userinfo = String(authority[...at])
            hostPort = authority[authority.index(after: at)...]
        }

        var host = hostPort
        var port: Substring = ""
        let hostEnd = hostPort.hasPrefix("[") ? hostPort.firstIndex(of: "]") : hostPort.startIndex
        if let hostEnd, let portColon = hostPort[hostEnd...].lastIndex(of: ":") {
            host = hostPort[..<portColon]
            port = hostPort[hostPort.index(after: portColon)...]
        }

        let defaultPort: Substring? =
            switch scheme {
            case "http": "80"
            case "https": "443"
            case "ftp": "21"
            default: nil
            }

        var result = userinfo + host.lowercased()
        if !port.isEmpty, port != defaultPort {
            result += ":" + port
        }
        return result
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

    public static func isValidHTTP(_ iri: some IRI.Representable) -> Bool {
        guard let url = URL(string: iri.iriString) else { return false }
        let scheme = url.scheme?.lowercased()
        return scheme == "http" || scheme == "https"
    }
}
