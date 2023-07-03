// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "ToDoSupport",
  platforms: [.iOS(.v16), .macOS(.v13)],
  products: [
    .library(
      name: "ToDoDomain",
      targets: ["ToDoDomain"]
    ),
    .library(
      name: "ToDoUI",
      targets: ["ToDoUI"]
    ),
  ],
  dependencies: [
    .package(name: "StateTree", path: "../../../"),
    .package(
      url: "https://github.com/GoodHatsLLC/swift-collections-v1_1-fork.git",
      .upToNextMinor(from: "1.1.0")
    ),
  ],
  targets: [
    .target(
      name: "ToDoUI",
      dependencies: [
        "ToDoDomain",
        .product(name: "StateTreeSwiftUI", package: "StateTree"),
        .product(name: "OrderedCollections", package: "swift-collections-v1_1-fork"),
        "UIComponents",
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
      name: "ToDoDomain",
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
    .target(
      name: "UIComponents",
      swiftSettings: [
        .enableUpcomingFeature("ConciseMagicFile"),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("StrictConcurrency"),
        .enableUpcomingFeature("ImplicitOpenExistentials"),
        .enableUpcomingFeature("BareSlashRegexLiterals"),
      ]
    ),
  ]
)
