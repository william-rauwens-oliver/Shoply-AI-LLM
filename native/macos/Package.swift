// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "LLMChat",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "LLMChat", targets: ["LLMChat"])
    ],
    targets: [
        .executableTarget(
            name: "LLMChat",
            swiftSettings: [
                .unsafeFlags(["-suppress-warnings"])
            ]
        )
    ]
)
