// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "VectorGuard",
    platforms: [
        .iOS(.v16),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "VectorGuard",
            targets: ["VectorGuard"]
        ),
    ],
    targets: [
        .target(
            name: "VectorGuard"
        ),
        .testTarget(
            name: "VectorGuardTests",
            dependencies: ["VectorGuard"]
        ),
    ]
)
