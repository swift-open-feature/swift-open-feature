// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "swift-open-feature",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .library(name: "OpenFeature", targets: ["OpenFeature"])
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "OpenFeature",
            dependencies: [
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle")
            ]
        ),
        .testTarget(
            name: "OpenFeatureTests",
            dependencies: [
                .target(name: "OpenFeature")
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
