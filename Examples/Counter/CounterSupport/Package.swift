// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "CounterSupport",
  platforms: [.iOS(.v16)],
  products: [
    .library(
      name: "CounterDomain",
      targets: ["CounterDomain"]
    ),
    .library(
      name: "CounterUI",
      targets: ["CounterUI"]
    ),
  ],
  dependencies: [
    .package(name: "StateTree", path: "../../..")
  ],
  targets: [
    .target(
      name: "CounterUI",
      dependencies: [
        "CounterDomain",
        .product(name: "StateTreeUIKit", package: "StateTree"),
      ]
    ),
    .target(
      name: "CounterDomain",
      dependencies: [
        .product(name: "StateTree", package: "StateTree")
      ]
    ),
  ]
)
