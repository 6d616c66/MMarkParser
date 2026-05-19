// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "MMarkParser",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "MMarkParser",
            targets: ["MMarkParser"]
        )
    ],
    targets: [
        .target(
            name: "iosMath",
            dependencies: [],
            path: "Sources/iosMath",
            exclude: ["fonts"],
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("lib"),
                .headerSearchPath("render"),
                .headerSearchPath("render/internal"),
            ]
        ),
        .target(
            name: "MMarkParser",
            dependencies: ["iosMath"],
            path: "Sources",
            exclude: ["iosMath"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "MMarkParserTests",
            dependencies: ["MMarkParser"],
            path: "Tests"
        )
    ]
)