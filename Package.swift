// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "VectorGuard",
    platforms: [
        .iOS(.v15),
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
            name: "VectorGuard",
            path: "Sources/VectorGuard",
            linkerSettings: [
                .linkedFramework("CoreMotion"),
                .linkedFramework("CoreLocation"),
            ]
        ),
        .testTarget(
            name: "VectorGuardTests",
            dependencies: ["VectorGuard"],
            path: "Tests/VectorGuardTests"
        ),
    ]
)
