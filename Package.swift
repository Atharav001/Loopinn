// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Loopinn",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "LoopinnCore", targets: ["LoopinnCore"]),
        .executable(name: "Loopinn", targets: ["Loopinn"])
    ],
    targets: [
        .target(name: "LoopinnCore", linkerSettings: [.linkedLibrary("sqlite3")]),
        .executableTarget(name: "Loopinn", dependencies: ["LoopinnCore"]),
        .testTarget(name: "LoopinnCoreTests", dependencies: ["LoopinnCore"])
    ]
)
