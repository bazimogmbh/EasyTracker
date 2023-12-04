// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EasyTracker",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "EasyTracker",
            targets: ["EasyTracker"]),
    ],
    dependencies: [
//        .package(url: "https://github.com/apple/swift-app-tracking-transparency", from: "2.0.0"),
//        .package(url: "https://github.com/apple/swift-ad-support", from: "1.0.0"),
//        .package(url: "https://github.com/apple/swift-network", from: "1.0.0"),
//        .package(url: "https://github.com/apple/swift-storekit", from: "1.0.0"),
        .package(url: "https://github.com/bizz84/SwiftyStoreKit", from: "0.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "EasyTracker",
            dependencies: ["SwiftyStoreKit"]),
        .testTarget(
            name: "EasyTrackerTests",
            dependencies: ["EasyTracker"]),
    ]
)
