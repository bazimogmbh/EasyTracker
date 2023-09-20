# EasyTracker

EasyTracker is a lightweight iOS framework designed for tracking user purchases.

## Installation

Swift Package Manager
Add EasyTracker as a dependency in your Package.swift file:

swift
Copy code
dependencies: [
    .package(url: "https://github.com/BeeMeeMan/EasyTracker.git", from: "1.0.0")
],

## Getting Started

Initialize EasyTracker in your app's entry point:
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    EasyTracker.configure()
    return true
}

## Tracking Purchases

Use trackPurchase(detail:) to record purchase events:

## License

EasyTracker is available under the MIT License.
