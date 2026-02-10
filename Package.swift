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
    ],
    targets: [
        .target(
            name: "Binary Parser Primitives",
            dependencies: [
                .product(name: "Parser Primitives", package: "swift-parser-primitives"),
                .product(name: "Binary Primitives", package: "swift-binary-primitives"),
                .product(name: "Input Primitives", package: "swift-input-primitives"),
                .product(name: "Machine Primitives", package: "swift-machine-primitives"),
                .product(name: "Vector Primitives", package: "swift-vector-primitives"),
            ]
        ),
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
            name: "Binary Parser Primitives Tests",
            dependencies: [
                "Binary Parser Primitives",
                "Binary Parser Primitives Test Support",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let settings: [SwiftSetting] = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableExperimentalFeature("Lifetimes"),
        .strictMemorySafety()
    ]
    target.swiftSettings = (target.swiftSettings ?? []) + settings
}
