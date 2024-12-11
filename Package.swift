// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "swift-open-feature",
    products: [
        .library(name: "OpenFeature", targets: ["OpenFeature"])
    ],
    targets: [
        .target(name: "OpenFeature"),
        .testTarget(
            name: "OpenFeatureTests",
            dependencies: [
                .target(name: "OpenFeature")
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
