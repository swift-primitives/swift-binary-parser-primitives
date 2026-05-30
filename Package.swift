// swift-tools-version: 6.3.1

import PackageDescription

let package = Package(
    name: "swift-binary-parser-primitives",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(
            name: "Binary Parser Primitives Core",
            targets: ["Binary Parser Primitives Core"]
        ),
        .library(
            name: "Binary Parser Primitives",
            targets: ["Binary Parser Primitives"]
        ),
        .library(
            name: "Binary Parseable Primitives",
            targets: ["Binary Parseable Primitives"]
        ),
        .library(
            name: "Binary Input Primitives",
            targets: ["Binary Input Primitives"]
        ),
        .library(
            name: "Binary Machine Primitives",
            targets: ["Binary Machine Primitives"]
        ),
        .library(
            name: "Binary Borrowed Primitives",
            targets: ["Binary Borrowed Primitives"]
        ),
        .library(
            name: "Binary Parse Primitives",
            targets: ["Binary Parse Primitives"]
        ),
        .library(
            name: "Binary Integer Primitives",
            targets: ["Binary Integer Primitives"]
        ),
        .library(
            name: "Binary Parser Primitives Test Support",
            targets: ["Binary Parser Primitives Test Support"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-primitives/swift-parser-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-binary-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-binary-leb128-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-machine-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-vector-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-index-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-byte-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-byte-parser-primitives.git", branch: "main"),
    ],
    targets: [
        // MARK: - Core

        .target(
            name: "Binary Parser Primitives Core",
            dependencies: [
                .product(name: "Binary Primitives", package: "swift-binary-primitives"),
                .product(name: "Parser Primitives", package: "swift-parser-primitives"),
            ]
        ),

        // MARK: - Input

        .target(
            name: "Binary Input Primitives",
            dependencies: [
                "Binary Parser Primitives Core",
                .product(name: "Byte Parser Primitives", package: "swift-byte-parser-primitives"),
            ]
        ),

        // MARK: - Machine

        .target(
            name: "Binary Machine Primitives",
            dependencies: [
                "Binary Input Primitives",
                .product(name: "Byte Parser Primitives", package: "swift-byte-parser-primitives"),
                .product(name: "Machine Primitives", package: "swift-machine-primitives"),
                .product(name: "Vector Primitives", package: "swift-vector-primitives"),
                .product(name: "Byte Primitives Standard Library Integration", package: "swift-byte-primitives"),
                .product(name: "Binary LEB128 Decode Primitives", package: "swift-binary-leb128-primitives"),
            ]
        ),
        .target(
            name: "Binary Borrowed Primitives",
            dependencies: [
                "Binary Machine Primitives",
                .product(name: "Byte Parser Primitives", package: "swift-byte-parser-primitives"),
                .product(name: "Vector Primitive", package: "swift-vector-primitives"),
                .product(name: "Byte Primitives Standard Library Integration", package: "swift-byte-primitives"),
                .product(name: "Binary LEB128 Decode Primitives", package: "swift-binary-leb128-primitives"),
            ]
        ),

        // MARK: - Parse Access

        .target(
            name: "Binary Parse Primitives",
            dependencies: [
                "Binary Input Primitives",
            ]
        ),

        // MARK: - Sibling Protocol (relocated from swift-binary-primitives)
        .target(
            name: "Binary Parseable Primitives",
            dependencies: [
                "Binary Parse Primitives",
                .product(name: "Binary Primitives", package: "swift-binary-primitives"),
                .product(name: "Byte Primitives", package: "swift-byte-primitives"),
                .product(name: "Byte Primitives Standard Library Integration", package: "swift-byte-primitives"),
            ]
        ),

        // MARK: - LEB128
        //
        // The LEB128 parser bridge (Binary.LEB128.Unsigned/Signed: Parser.`Protocol`)
        // was extracted to swift-binary-leb128-parser-primitives per [MOD-014]
        // (integration package, recipient-then-provider [PKG-NAME-016]). The shared
        // decode arithmetic lives in swift-binary-leb128-primitives' Binary.LEB128.Decode,
        // which the Machine/Borrowed interpreters here delegate to directly.

        // MARK: - Coder
        //
        // Binary.Coder lives in swift-binary-coder-primitives per [MOD-DOMAIN]
        // — Coder is a different transformation domain from Parser. The
        // integer-specific coder methods (UInt8.coder, Int32.coder, ...) live
        // there too in "Binary Integer Coder Primitives". See
        // swift-institute/Research/transformation-domain-architecture.md v3.3.0.

        // MARK: - Integer Parsers

        .target(
            name: "Binary Integer Primitives",
            dependencies: [
                "Binary Parse Primitives",
                // Direct dep on the LEB128 types (was transited through the now-extracted
                // parser bridge); Integer re-exports the Binary.LEB128 namespace.
                .product(name: "Binary LEB128 Primitives", package: "swift-binary-leb128-primitives"),
            ]
        ),

        // MARK: - Umbrella

        .target(
            name: "Binary Parser Primitives",
            dependencies: [
                "Binary Parser Primitives Core",
                "Binary Input Primitives",
                "Binary Machine Primitives",
                "Binary Borrowed Primitives",
                "Binary Parse Primitives",
                "Binary Parseable Primitives",
                "Binary Integer Primitives",
            ]
        ),

        // MARK: - Tests

        .target(
            name: "Binary Parser Primitives Test Support",
            dependencies: [
                "Binary Parser Primitives",
                "Binary Parseable Primitives",
                .product(name: "Binary Primitives Test Support", package: "swift-binary-primitives"),
                .product(name: "Byte Primitives Standard Library Integration", package: "swift-byte-primitives"),
                .product(name: "Index Primitives Test Support", package: "swift-index-primitives"),
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Binary Input Primitives Tests",
            dependencies: ["Binary Parser Primitives Test Support"]
        ),
        .testTarget(
            name: "Binary Borrowed Primitives Tests",
            dependencies: ["Binary Parser Primitives Test Support"]
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
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
