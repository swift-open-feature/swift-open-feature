// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "swift-open-feature",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "OpenFeature", targets: ["OpenFeature"]),
        .library(name: "OpenFeatureTracing", targets: ["OpenFeatureTracing"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-distributed-tracing.git", from: "1.2.0"),
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
                .target(name: "OpenFeature"),
                .target(name: "OpenFeatureTestSupport"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle"),
            ]
        ),

        .target(
            name: "OpenFeatureTracing",
            dependencies: [
                .target(name: "OpenFeature"),
                .product(name: "Tracing", package: "swift-distributed-tracing"),
            ]
        ),
        .testTarget(
            name: "OpenFeatureTracingTests",
            dependencies: [
                .target(name: "OpenFeatureTracing"),
                .target(name: "OpenFeatureTestSupport"),
            ]
        ),

        .target(
            name: "OpenFeatureTestSupport",
            dependencies: [
                .target(name: "OpenFeature")
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
