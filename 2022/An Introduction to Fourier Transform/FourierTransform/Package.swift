// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FourierTransform",
    platforms: [.macOS(.v11)],
    products: [],
    dependencies: [
        .package(url: "https://github.com/apple/swift-numerics.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "PathUtilities",
                swiftSettings: [.unsafeFlags(["-O"])]),
        .target(
            name: "FourierDrawing",
            dependencies: [
                .product(name: "Numerics", package: "swift-numerics"),
                "PathUtilities"
            ]),
        .target(name: "ImageDCT"),
        .executableTarget(
            name: "App",
            dependencies: ["FourierDrawing", "ImageDCT"],
            resources: [.copy("Resources/flower.png")]),
        .testTarget(
            name: "PerformanceTests",
            dependencies: ["FourierDrawing"]),
    ]
)
