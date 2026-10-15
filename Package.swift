// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SacredUniverse",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "SacredCore", targets: ["SacredCore"])
    ],
    targets: [
        .target(name: "SacredCore"),
        .testTarget(name: "SacredCoreTests", dependencies: ["SacredCore"])
    ]
)
