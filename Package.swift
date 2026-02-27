// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MagicTeleprompter",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(
            name: "MagicTeleprompter",
            path: "MagicTeleprompter",
            exclude: [
                "Info.plist",
                "MagicTeleprompter.entitlements"
            ],
            resources: [
                .process("Assets.xcassets")
            ]
        ),
        .testTarget(
            name: "MagicTeleprompterTests",
            dependencies: ["MagicTeleprompter"],
            path: "MagicTeleprompterTests"
        )
    ]
)
