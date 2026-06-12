// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "NyoraEngine",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(name: "NyoraEngine", targets: ["NyoraEngine"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "NyoraEngine",
            dependencies: []
        ),
        .testTarget(
            name: "NyoraEngineTests",
            dependencies: ["NyoraEngine"],
            resources: [.process("Fixtures")]
        ),
    ]
)
