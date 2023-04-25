// swift-tools-version: 5.7
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
    .package(name: "StateTree", path: "../../../../"),
  ],
  targets: [
    .target(
      name: "ToDoUI",
      dependencies: [
        "ToDoDomain",
        .product(name: "StateTreeSwiftUI", package: "StateTree"),
        "UIComponents",
      ]
    ),
    .target(
      name: "ToDoDomain",
      dependencies: [
        .product(name: "StateTree", package: "StateTree"),
      ]
    ),
    .target(
      name: "UIComponents"
    ),
    .testTarget(
      name: "ToDoDomainTests",
      dependencies: ["ToDoDomain", "StateTree"]
    ),
  ]
)
