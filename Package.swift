// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-rfc-3987",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(
            name: "RFC 3987",
            targets: ["RFC 3987"]
        ),
        .library(
            name: "RFC 3987 Foundation",
            targets: ["RFC 3987 Foundation"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-atoms/swift-binary.git",
            branch: "main", traits: ["Serializer"]),
        .package(url: "https://github.com/swift-atoms/swift-ascii.git", branch: "main", traits: ["Parser", "Serializer"]),
    ],
    targets: [
        .target(
            name: "RFC 3987",
            dependencies: [
                .product(name: "Binary", package: "swift-binary"),
                .product(name: "ASCII", package: "swift-ascii"),
            ]

        ),
        .target(
            name: "RFC 3987 Foundation",
            dependencies: [.target(name: "RFC 3987")]

        ),
        .testTarget(
            name: "RFC 3987 Tests",
            dependencies: [
                .target(name: "RFC 3987"),
                .target(name: "RFC 3987 Foundation"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
