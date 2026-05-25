// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "MMarkParser",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "MMarkParser",
            targets: ["MMarkParser"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/6d616c66/md4c.git", branch: "master"),
        .package(path: "../iosMath"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "8.0.0"),
    ],
    targets: [
        .target(
            name: "MMarkParser",
            dependencies: [
                .product(name: "md4c", package: "md4c"),
                .product(name: "iosMath", package: "iosMath"),
                .product(name: "Kingfisher", package: "Kingfisher"),
            ],
            path: "Sources",
            resources: [.process("Resources")]
        )
    ]
)
