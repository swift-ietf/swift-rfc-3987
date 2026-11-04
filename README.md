# swift-rfc-3987

Use this package when you need to accept, store or check internationalized resource identifiers, which may contain Unicode characters such as `https://example.com/寿司` without percent-encoding. Start from `RFC_3987.IRI` for an absolute IRI and `RFC_3987.IRI.Reference` for one that may be relative. For conversion to and from Foundation's `URL` and for normalization, add the `RFC 3987 Foundation` product. If your identifiers are ASCII-only URIs, use swift-rfc-3986.

## Laws

- `RFC_3987.IRI.init(_:mode:)` is lenient by default. Lenient mode only requires text before the first colon, so `https://example.com/hello world` is accepted. Strict mode also checks the scheme, the character set of each component and the percent-encoding.
- In strict mode a scheme starts with an ASCII letter and continues with letters, digits, plus, hyphen or period. Spaces, control characters, backslashes, angle brackets and braces are refused.
- In strict mode a percent sign must be followed by two ASCII hex digits, in either case, so fullwidth digits are refused. Private-use characters are allowed in the query only.
- A string literal creates an `RFC_3987.IRI` without any validation.
- An `RFC_3987.IRI.Reference` is absolute when its first segment, up to the first slash, question mark or number sign, contains a colon. It is then checked in strict mode. Otherwise it is checked as a relative reference, and the empty string is valid.
- `RFC_3987.isValidHTTP(_:)` accepts the http and https schemes in any letter case.
- An `RFC_3987.IRI` encodes as a single string and decodes with lenient validation. A failure becomes a data-corrupted `DecodingError` whose description is the validation error's.
- `RFC_3987.IRI.normalized()` lowercases the scheme and host, drops the default port for http, https and ftp, gives an empty http or https path a single slash, and removes dot segments. An IRI that Foundation's `URL` can't parse is returned unchanged.
- `RFC_3987.IRI.uriString`, `RFC_3987.IRI.normalized()`, `RFC_3987.IRI.init(url:)` and the `iri` of a `URL` all use the URL's absolute string, so characters outside ASCII come back percent-encoded in UTF-8.
- `URL.init(iri:)` first tries the IRI as it is, and percent-encodes it only if that fails.
