import ASCII_Serializer_Primitives

extension RFC_3987 {

    enum Grammar {

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

        static func isIPrivate(_ scalar: Unicode.Scalar) -> Bool {
            switch scalar.value {
            case 0xE000...0xF8FF, 0xF_0000...0xF_FFFD, 0x10_0000...0x10_FFFD:
                return true

            default:
                return false
            }
        }

        static func isIUnreserved(_ scalar: Unicode.Scalar) -> Bool {
            if scalar.isASCII {
                let byte = UInt8(scalar.value)
                return ASCII.Classification.isLetter(byte) || ASCII.Classification.isDigit(byte)
                    || scalar == "-" || scalar == "." || scalar == "_" || scalar == "~"
            }
            return isUCSChar(scalar)
        }

        static func isSubDelim(_ scalar: Unicode.Scalar) -> Bool {
            switch scalar {
            case "!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "=":
                return true

            default:
                return false
            }
        }

        static func isIPChar(_ scalar: Unicode.Scalar) -> Bool {
            isIUnreserved(scalar) || isSubDelim(scalar) || scalar == ":" || scalar == "@"
        }

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

        static func validate(
            _ component: some StringProtocol,
            allowing allowed: (Unicode.Scalar) -> Bool
        ) -> Bool {
            guard hasValidPercentEncoding(component) else { return false }

            var scalars = component.unicodeScalars.makeIterator()
            while let scalar = scalars.next() {
                if scalar == "%" {

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
