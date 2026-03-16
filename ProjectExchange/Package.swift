// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProjectExchange",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(
            name: "ProjectExchange",
            targets: ["ProjectExchange"]
        ),
    ],
    targets: [
        .target(
            name: "ProjectExchange"
        ),
        .testTarget(
            name: "ProjectExchangeTests",
            dependencies: ["ProjectExchange"]
        ),
    ]
)
