// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "TicTacToeSupport",
  platforms: [.macOS(.v12), .iOS(.v15)],
  products: [
    .library(
      name: "TicTacToeUI",
      targets: ["TicTacToeUI"]
    ),
    .library(
      name: "TicTacToeDomain",
      targets: ["TicTacToeDomain"]
    ),
  ],
  dependencies: [
    .package(path: "../../../../"),
  ],
  targets: [
    .target(
      name: "TicTacToeUI",
      dependencies: [
        "TicTacToeDomain",
        .product(name: "StateTreeSwiftUI", package: "StateTree"),
      ]
    ),
    .target(
      name: "TicTacToeDomain",
      dependencies: [
        .product(name: "StateTree", package: "StateTree"),
      ]
    ),
    .testTarget(
      name: "TicTacToeDomainTests",
      dependencies: [
        "TicTacToeDomain",
      ]
    ),
  ]
)
