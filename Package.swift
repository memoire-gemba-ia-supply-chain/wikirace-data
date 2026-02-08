// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "WikiRaceApp",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "WikiRaceApp",
            targets: ["WikiRaceApp"]
        )
    ],
    targets: [
        .executableTarget(
            name: "WikiRaceApp",
            path: "WikiRaceApp"
        )
    ]
)
