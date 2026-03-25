// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MakeScheduleUI",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "MakeScheduleUI",
            path: "Sources"
        )
    ]
)
