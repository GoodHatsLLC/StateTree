// swift-tools-version: 5.8
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
      ],
      swiftSettings: [
        .enableUpcomingFeature("ConciseMagicFile"),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("StrictConcurrency"),
        .enableUpcomingFeature("ImplicitOpenExistentials"),
        .enableUpcomingFeature("BareSlashRegexLiterals"),
      ]
    ),
    .target(
      name: "TicTacToeDomain",
      dependencies: [
        .product(name: "StateTree", package: "StateTree"),
      ],
      swiftSettings: [
        .enableUpcomingFeature("ConciseMagicFile"),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("StrictConcurrency"),
        .enableUpcomingFeature("ImplicitOpenExistentials"),
        .enableUpcomingFeature("BareSlashRegexLiterals"),
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
