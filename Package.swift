// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EasyTracker",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "EasyTracker",
            targets: ["EasyTracker"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-app-tracking-transparency.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-ad-support.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-network.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-storekit.git", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "EasyTracker",
            dependencies: []),
        .testTarget(
            name: "EasyTrackerTests",
            dependencies: ["EasyTracker"]),
    ]
)
