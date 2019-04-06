// swift-tools-version:5.0

/**
 *  Codextended
 *  Copyright (c) John Sundell 2019
 *  Licensed under the MIT license (see LICENSE file)
 */

import PackageDescription

let package = Package(
    name: "Codextended",
    products: [
        .library(
            name: "Codextended",
            targets: ["Codextended"]
        )
    ],
    targets: [
        .target(name: "Codextended"),
        .testTarget(
            name: "CodextendedTests",
            dependencies: ["Codextended"]
        )
    ]
)
