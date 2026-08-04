// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ViewMonitor",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(name: "ViewMonitor", targets: ["ViewMonitor"]),
    ],
    targets: [
        .target(
            name: "ViewMonitor",
            resources: [.process("Resources")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "ViewMonitorTests",
            dependencies: ["ViewMonitor"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
