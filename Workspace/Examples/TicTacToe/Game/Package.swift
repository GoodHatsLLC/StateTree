// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Game",
  platforms: [.macOS(.v12), .iOS(.v14)],
  products: [
    .library(
      name: "GameUI",
      targets: ["GameUI"]
    ),
    .library(
      name: "GameDomain",
      targets: ["GameDomain"]
    ),
  ],
  dependencies: [
    .package(path: "../../../../"),
  ],
  targets: [
    .target(
      name: "GameUI",
      dependencies: [
        "GameDomain",
        .product(name: "StateTreeSwiftUI", package: "StateTree"),
      ]
    ),
    .target(
      name: "GameDomain",
      dependencies: [
        .product(name: "StateTree", package: "StateTree"),
      ]
    ),
    .testTarget(
      name: "GameDomainTests",
      dependencies: [
        "GameDomain",
      ]
    ),
  ]
)
