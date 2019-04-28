// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftGraphQLServer",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "SwiftGraphQLServer",
            targets: ["SwiftGraphQLServer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/HedvigInsurance/Graphiti.git", from: "0.9.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "3.3.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SwiftGraphQLServer",
            dependencies: [
                "Graphiti",
                "Vapor"
            ]),
        .testTarget(
            name: "SwiftGraphQLServerTests",
            dependencies: ["SwiftGraphQLServer"]),
    ]
)
