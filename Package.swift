// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "WikiRaceAppStale",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "WikiRaceAppStale",
            targets: ["WikiRaceAppStale"]
        )
    ],
    targets: [
        .executableTarget(
            name: "WikiRaceAppStale",
            path: "WikiRaceApp",
            resources: [
                .process("Media.xcassets"),
                .process("events.json")
            ]
        )
    ]
)
