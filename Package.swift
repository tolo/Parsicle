// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Parsicle",
    platforms: [
        .iOS(.v9),
        .tvOS(.v9),
    ], 
    products: [
        .library(
            name: "Parsicle",
            targets: ["Parsicle"]),
    ],
    targets: [
        .target(
            name: "Parsicle",
            dependencies: []),
        .testTarget(
            name: "ParsicleTests",
            dependencies: ["Parsicle"]),
    ]
)
