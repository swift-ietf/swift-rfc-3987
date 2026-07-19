//
//  RFC_3987.Grammar.swift
//  swift-rfc-3987
//

import ASCII_Serializer_Primitives

extension RFC_3987 {
    /// Character-class and percent-encoding predicates mirroring the RFC 3987
    /// ABNF (Section 2.2), used by `isValidIRI(_:mode: .strict)`.
    ///
    /// - Note: Internal only — these are grammar-classification primitives,
    ///   not part of the package's public validation surface.
    enum Grammar {
        /// `ucschar` — the Unicode ranges RFC 3987 adds to `iunreserved` beyond
        /// what RFC 3986's ASCII-only `unreserved` allows.
        ///
        /// ```
        /// ucschar = %xA0-D7FF / %xF900-FDCF / %xFDF0-FFEF
        ///         / %x10000-1FFFD / %x20000-2FFFD / %x30000-3FFFD
        ///         / %x40000-4FFFD / %x50000-5FFFD / %x60000-6FFFD
        ///         / %x70000-7FFFD / %x80000-8FFFD / %x90000-9FFFD
        ///         / %xA0000-AFFFD / %xB0000-BFFFD / %xC0000-CFFFD
        ///         / %xD0000-DFFFD / %xE1000-EFFFD
        /// ```
        static func isUCSChar(_ scalar: Unicode.Scalar) -> Bool {
            switch scalar.value {
            case 0xA0...0xD7FF,
                0xF900...0xFDCF,
                0xFDF0...0xFFEF,
                0x1_0000...0x1_FFFD,
                0x2_0000...0x2_FFFD,
                0x3_0000...0x3_FFFD,
                0x4_0000...0x4_FFFD,
                0x5_0000...0x5_FFFD,
                0x6_0000...0x6_FFFD,
                0x7_0000...0x7_FFFD,
                0x8_0000...0x8_FFFD,
                0x9_0000...0x9_FFFD,
                0xA_0000...0xA_FFFD,
                0xB_0000...0xB_FFFD,
                0xC_0000...0xC_FFFD,
                0xD_0000...0xD_FFFD,
                0xE_1000...0xE_FFFD:
                return true
            default:
                return false
            }
        }

        /// `iprivate` — private-use ranges permitted only inside `iquery`.
        ///
        /// ```
        /// iprivate = %xE000-F8FF / %xF0000-FFFFD / %x100000-10FFFD
        /// ```
        static func isIPrivate(_ scalar: Unicode.Scalar) -> Bool {
            switch scalar.value {
            case 0xE000...0xF8FF, 0xF_0000...0xF_FFFD, 0x10_0000...0x10_FFFD:
                return true
            default:
                return false
            }
        }

        /// `iunreserved = ALPHA / DIGIT / "-" / "." / "_" / "~" / ucschar`
        static func isIUnreserved(_ scalar: Unicode.Scalar) -> Bool {
            if scalar.isASCII {
                let byte = UInt8(scalar.value)
                return ASCII.Classification.isLetter(byte) || ASCII.Classification.isDigit(byte)
                    || scalar == "-" || scalar == "." || scalar == "_" || scalar == "~"
            }
            return isUCSChar(scalar)
        }

        /// `sub-delims = "!" / "$" / "&" / "'" / "(" / ")" / "*" / "+" / "," / ";" / "="`
        /// (RFC 3986 §2.2, reused unchanged by RFC 3987).
        static func isSubDelim(_ scalar: Unicode.Scalar) -> Bool {
            switch scalar {
            case "!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "=":
                return true
            default:
                return false
            }
        }

        /// `ipchar = iunreserved / pct-encoded / sub-delims / ":" / "@"`
        ///
        /// `pct-encoded` triplets are validated separately by `hasValidPercentEncoding`
        /// and skipped over by `validate(_:allowing:)`; this predicate covers the
        /// remaining single-scalar alternatives.
        static func isIPChar(_ scalar: Unicode.Scalar) -> Bool {
            isIUnreserved(scalar) || isSubDelim(scalar) || scalar == ":" || scalar == "@"
        }

        /// Validates that every `"%"` in `component` begins a well-formed
        /// `pct-encoded = "%" HEXDIG HEXDIG` triplet.
        static func hasValidPercentEncoding(_ component: some StringProtocol) -> Bool {
            var iterator = component.makeIterator()
            while let character = iterator.next() {
                guard character == "%" else { continue }
                guard let first = iterator.next(), first.isHexDigit,
                    let second = iterator.next(), second.isHexDigit
                else { return false }
            }
            return true
        }

        /// Validates `component` scalar-by-scalar against `allowed`, treating
        /// `"%XX"` triplets as always allowed once `hasValidPercentEncoding` has
        /// confirmed they are well-formed.
        static func validate(
            _ component: some StringProtocol,
            allowing allowed: (Unicode.Scalar) -> Bool
        ) -> Bool {
            guard hasValidPercentEncoding(component) else { return false }

            var scalars = component.unicodeScalars.makeIterator()
            while let scalar = scalars.next() {
                if scalar == "%" {
                    // Already confirmed well-formed by hasValidPercentEncoding above.
                    _ = scalars.next()
                    _ = scalars.next()
                    continue
                }
                guard allowed(scalar) else { return false }
            }
            return true
        }
    }
}
