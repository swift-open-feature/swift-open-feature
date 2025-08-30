// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "swift-open-feature",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "OpenFeature", targets: ["OpenFeature"])
    ],
    traits: [
        .trait(name: "ServiceLifecycleSupport"),
        .trait(name: "DistributedTracingSupport"),
        .default(enabledTraits: []),
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
                .product(
                    name: "ServiceLifecycle",
                    package: "swift-service-lifecycle",
                    condition: .when(traits: ["ServiceLifecycleSupport"])
                ),
                .product(
                    name: "Tracing",
                    package: "swift-distributed-tracing",
                    condition: .when(traits: ["DistributedTracingSupport"])
                ),
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
            name: "OpenFeatureTestSupport",
            dependencies: [
                .target(name: "OpenFeature")
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
