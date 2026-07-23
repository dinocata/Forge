// swift-tools-version: 6.3.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Forge",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ForgeCore",
            targets: ["ForgeCore"]
        ),
        .library(
            name: "ForgeNetworking",
            targets: ["ForgeNetworking"]
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ForgeCore",
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
        .target(
            name: "ForgeNetworking",
            dependencies: [
                "ForgeCore"
            ],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
        .testTarget(
            name: "ForgeCoreTests",
            dependencies: ["ForgeCore"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
        .testTarget(
            name: "ForgeNetworkingTests",
            dependencies: ["ForgeNetworking"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        )
    ]
)
