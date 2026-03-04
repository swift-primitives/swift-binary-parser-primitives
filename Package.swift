// swift-tools-version: 6.2

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
            name: "Binary Parser Primitives",
            targets: ["Binary Parser Primitives"]
        ),
        .library(
            name: "Binary Input Primitives",
            targets: ["Binary Input Primitives"]
        ),
        .library(
            name: "Binary Input View Primitives",
            targets: ["Binary Input View Primitives"]
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
            name: "Binary LEB128 Primitives",
            targets: ["Binary LEB128 Primitives"]
        ),
        .library(
            name: "Binary Coder Primitives",
            targets: ["Binary Coder Primitives"]
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
        .package(path: "../swift-parser-primitives"),
        .package(path: "../swift-binary-primitives"),
        .package(path: "../swift-input-primitives"),
        .package(path: "../swift-machine-primitives"),
        .package(path: "../swift-index-primitives"),
        .package(path: "../swift-vector-primitives"),
        .package(path: "../swift-witness-primitives"),
    ],
    targets: [
        // MARK: - Input

        .target(
            name: "Binary Input Primitives",
            dependencies: [
                .product(name: "Binary Primitives", package: "swift-binary-primitives"),
                .product(name: "Parser Primitives", package: "swift-parser-primitives"),
            ]
        ),
        .target(
            name: "Binary Input View Primitives",
            dependencies: [
                "Binary Input Primitives",
            ]
        ),

        // MARK: - Machine

        .target(
            name: "Binary Machine Primitives",
            dependencies: [
                "Binary Input Primitives",
                "Binary Input View Primitives",
                .product(name: "Machine Primitives", package: "swift-machine-primitives"),
            ]
        ),
        .target(
            name: "Binary Borrowed Primitives",
            dependencies: [
                "Binary Machine Primitives",
                "Binary Input View Primitives",
            ]
        ),

        // MARK: - Parse Access

        .target(
            name: "Binary Parse Primitives",
            dependencies: [
                "Binary Input Primitives",
            ]
        ),

        // MARK: - LEB128

        .target(
            name: "Binary LEB128 Primitives",
            dependencies: [
                .product(name: "Binary Primitives", package: "swift-binary-primitives"),
                .product(name: "Parser Primitives", package: "swift-parser-primitives"),
            ]
        ),

        // MARK: - Coder

        .target(
            name: "Binary Coder Primitives",
            dependencies: [
                "Binary Input Primitives",
                "Binary Machine Primitives",
                .product(name: "Witness Primitives", package: "swift-witness-primitives"),
            ]
        ),

        // MARK: - Integer Parsers

        .target(
            name: "Binary Integer Primitives",
            dependencies: [
                "Binary Coder Primitives",
                "Binary Parse Primitives",
                "Binary LEB128 Primitives",
            ]
        ),

        // MARK: - Umbrella

        .target(
            name: "Binary Parser Primitives",
            dependencies: [
                "Binary Input Primitives",
                "Binary Input View Primitives",
                "Binary Machine Primitives",
                "Binary Borrowed Primitives",
                "Binary Parse Primitives",
                "Binary LEB128 Primitives",
                "Binary Coder Primitives",
                "Binary Integer Primitives",
                .product(name: "Binary Primitives", package: "swift-binary-primitives"),
                .product(name: "Parser Primitives", package: "swift-parser-primitives"),
            ]
        ),

        // MARK: - Tests

        .target(
            name: "Binary Parser Primitives Test Support",
            dependencies: [
                "Binary Parser Primitives",
                .product(name: "Binary Primitives Test Support", package: "swift-binary-primitives"),
                .product(name: "Index Primitives Test Support", package: "swift-index-primitives"),
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Binary Input Primitives Tests",
            dependencies: ["Binary Parser Primitives Test Support"]
        ),
        .testTarget(
            name: "Binary Input View Primitives Tests",
            dependencies: ["Binary Parser Primitives Test Support"]
        ),
        .testTarget(
            name: "Binary Coder Primitives Tests",
            dependencies: ["Binary Parser Primitives Test Support"]
        ),
        .testTarget(
            name: "Binary LEB128 Primitives Tests",
            dependencies: ["Binary Parser Primitives Test Support"]
        ),
        .testTarget(
            name: "Binary Integer Primitives Tests",
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
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableExperimentalFeature("SuppressedAssociatedTypesWithDefaults"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
