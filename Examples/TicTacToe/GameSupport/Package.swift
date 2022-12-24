// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "GameSupport",
  platforms: [.macOS(.v12)],
  products: [
    .library(
      name: "GameDomain",
      targets: ["GameDomain"]
    ),
    .library(
      name: "GameUI",
      targets: ["GameUI"]
    ),
  ],
  dependencies: [
    .package(name: "StateTree", path: "../../..")
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
        .product(name: "StateTree", package: "StateTree")
      ]
    ),
  ]
)
