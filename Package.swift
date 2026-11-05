// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LiquidClean",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "LiquidClean", targets: ["LiquidClean"])
    ],
    targets: [
        .executableTarget(
            name: "LiquidClean",
            path: "Sources"
        )
    ]
)
