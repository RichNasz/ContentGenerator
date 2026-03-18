// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "ChatCompletionsAgentGen",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(
            name: "ChatCompletionsAgentGen",
            targets: ["ChatCompletionsAgentGen"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/RichNasz/SwiftChatCompletionsDSL", branch: "main"),
        .package(url: "https://github.com/RichNasz/SwiftChatCompletionsMacros", branch: "main"),
        .package(path: "../LLMmanagement"),
    ],
    targets: [
        .target(
            name: "ChatCompletionsAgentGen",
            dependencies: [
                .product(name: "SwiftChatCompletionsDSL", package: "SwiftChatCompletionsDSL"),
                .product(name: "SwiftChatCompletionsMacros", package: "SwiftChatCompletionsMacros"),
                .product(name: "LLMmanagement", package: "LLMmanagement"),
            ]
        ),
        .testTarget(
            name: "ChatCompletionsAgentGenTests",
            dependencies: ["ChatCompletionsAgentGen"]
        ),
    ]
)
