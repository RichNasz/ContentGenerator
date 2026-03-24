// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AgentGen",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(
            name: "AgentGen",
            targets: ["AgentGen"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/RichNasz/SwiftOpenResponsesDSL", branch: "main"),
        .package(url: "https://github.com/RichNasz/SwiftLLMToolMacros", branch: "main"),
        .package(path: "../LLMmanagement"),
    ],
    targets: [
        .target(
            name: "AgentGen",
            dependencies: [
                .product(name: "SwiftOpenResponsesDSL", package: "SwiftOpenResponsesDSL"),
                .product(name: "SwiftLLMToolMacros", package: "SwiftLLMToolMacros"),
                .product(name: "LLMmanagement", package: "LLMmanagement"),
            ]
        ),
        .testTarget(
            name: "AgentGenTests",
            dependencies: ["AgentGen"]
        ),
    ]
)
