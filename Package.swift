// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BatteryMenubar",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "BatteryMenubarCore"),
        .executableTarget(
            name: "BatteryMenubar",
            dependencies: ["BatteryMenubarCore"]
        ),
        .testTarget(
            name: "BatteryMenubarCoreTests",
            dependencies: ["BatteryMenubarCore"]
        ),
    ]
)
