// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-binary-parser-primitives",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
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
        .package(
            url: "https://github.com/swift-primitives/swift-parser-primitives.git",
            branch: "main"
        ),

        .package(
            url: "https://github.com/swift-primitives/swift-binary-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-binary-leb128-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-machine-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-vector-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-index-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-byte-primitives.git",
            branch: "main"
        ),

        .package(
            url: "https://github.com/swift-primitives/swift-byte-parser-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-span-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-buffer-linear-primitives.git",
            branch: "main"
        ),

        .package(
            url: "https://github.com/swift-primitives/swift-ownership-shared-primitives.git",
            branch: "main"
        ),
    ],
    targets: [

        .target(
            name: "Binary Input Primitives",
            dependencies: [

                .product(name: "Binary Primitives", package: "swift-binary-primitives"),
                .product(name: "Parser Primitives", package: "swift-parser-primitives"),
                .product(name: "Byte Parser Primitives", package: "swift-byte-parser-primitives"),
            ]
        ),

        .target(
            name: "Binary Machine Primitives",
            dependencies: [
                "Binary Input Primitives",
                .product(name: "Byte Parser Primitives", package: "swift-byte-parser-primitives"),
                .product(name: "Machine Primitives", package: "swift-machine-primitives"),
                .product(name: "Vector Primitives", package: "swift-vector-primitives"),
                .product(
                    name: "Byte Primitives Standard Library Integration",
                    package: "swift-byte-primitives"
                ),
                .product(
                    name: "Binary LEB128 Decode Primitives",
                    package: "swift-binary-leb128-primitives"
                ),
                .product(
                    name: "Buffer Linear Primitive",
                    package: "swift-buffer-linear-primitives"
                ),
                .product(
                    name: "Buffer Linear Primitives",
                    package: "swift-buffer-linear-primitives"
                ),
                .product(
                    name: "Ownership Shared Primitive",
                    package: "swift-ownership-shared-primitives"
                ),
            ]
        ),
        .target(
            name: "Binary Borrowed Primitives",
            dependencies: [
                "Binary Machine Primitives",
                .product(name: "Byte Parser Primitives", package: "swift-byte-parser-primitives"),
                .product(name: "Vector Primitive", package: "swift-vector-primitives"),
                .product(
                    name: "Byte Primitives Standard Library Integration",
                    package: "swift-byte-primitives"
                ),
                .product(
                    name: "Binary LEB128 Decode Primitives",
                    package: "swift-binary-leb128-primitives"
                ),

                .product(name: "Span Protocol Primitives", package: "swift-span-primitives"),
            ]
        ),

        .target(
            name: "Binary Parse Primitives",
            dependencies: [
                "Binary Input Primitives",
                .product(
                    name: "Buffer Linear Primitive",
                    package: "swift-buffer-linear-primitives"
                ),
                .product(
                    name: "Buffer Linear Primitives",
                    package: "swift-buffer-linear-primitives"
                ),
                .product(
                    name: "Ownership Shared Primitive",
                    package: "swift-ownership-shared-primitives"
                ),
            ]
        ),

        .target(
            name: "Binary Parseable Primitives",
            dependencies: [
                "Binary Parse Primitives",
                .product(name: "Binary Primitives", package: "swift-binary-primitives"),
                .product(name: "Byte Primitives", package: "swift-byte-primitives"),
                .product(
                    name: "Byte Primitives Standard Library Integration",
                    package: "swift-byte-primitives"
                ),
            ]
        ),

        .target(
            name: "Binary Integer Primitives",
            dependencies: [
                "Binary Parse Primitives",

                .product(
                    name: "Binary LEB128 Primitives",
                    package: "swift-binary-leb128-primitives"
                ),
            ]
        ),

        .target(
            name: "Binary Parser Primitives",
            dependencies: [

                "Binary Input Primitives",
                "Binary Machine Primitives",
                "Binary Borrowed Primitives",
                "Binary Parse Primitives",
                "Binary Parseable Primitives",
                "Binary Integer Primitives",
            ]
        ),

        .target(
            name: "Binary Parser Primitives Test Support",
            dependencies: [
                "Binary Parser Primitives",
                "Binary Parseable Primitives",
                .product(
                    name: "Binary Primitives Test Support",
                    package: "swift-binary-primitives"
                ),
                .product(
                    name: "Byte Primitives Standard Library Integration",
                    package: "swift-byte-primitives"
                ),
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
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
