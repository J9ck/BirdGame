// swift-tools-version: 5.9
// NOTE: Full build requires Xcode on macOS/iOS. On Linux, only model files can be compiled.
import PackageDescription

let package = Package(
    name: "BirdGame3",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "BirdGame3",
            targets: ["BirdGame3"]
        )
    ],
    targets: [
        .target(
            name: "BirdGame3",
            path: "Sources",
            exclude: ["App/BirdGame3App.swift"] // Exclude app entry point for library builds
        ),
        .testTarget(
            name: "BirdGame3Tests",
            dependencies: ["BirdGame3"],
            path: "Tests"
        )
    ]
)
