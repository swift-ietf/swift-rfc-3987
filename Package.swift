// swift-tools-version: 6.3.3

import PackageDescription

let package = Package(
    name: "swift-rfc-3987",
    platforms: [
        .macOS("27"),
        .iOS("27"),
        .tvOS("27"),
        .watchOS("27")
    ],
    products: [
        .library(
            name: "RFC 3987",
            targets: ["RFC 3987"]
        ),
        .library(
            name: "RFC 3987 Foundation",
            targets: ["RFC 3987 Foundation"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swift-primitives/swift-binary-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-ascii-serializer-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-ascii-parser-primitives.git", branch: "main")
    ],
    targets: [
        .target(
            name: "RFC 3987",
            dependencies: [
                .product(name: "Binary Primitives", package: "swift-binary-primitives"),
                .product(name: "ASCII Serializer Primitives", package: "swift-ascii-serializer-primitives"),
                .product(name: "Parseable ASCII Primitives", package: "swift-ascii-parser-primitives")
    ]
            // Core module - uses INCITS_4_1986 for ASCII validation, no Foundation
        ),
        .target(
            name: "RFC 3987 Foundation",
            dependencies: ["RFC 3987"]
            // Foundation extensions - depends on core
        ),
        .testTarget(
            name: "RFC 3987 Tests",
            dependencies: [
                "RFC 3987",
                "RFC 3987 Foundation",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
    var foundation: Self { self + " Foundation" }
}

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
