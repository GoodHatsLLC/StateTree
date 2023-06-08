// swift-tools-version: 5.8
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
    .package(path: "../../../"),
    .package(
      url: "https://github.com/apple/swift-collections.git",
      branch: "release/1.1"
    ),
  ],
  targets: [
    .target(
      name: "CounterUI",
      dependencies: [
        "CounterDomain",
        .product(name: "StateTreeImperativeUI", package: "StateTree"),
      ]
    ),
    .target(
      name: "CounterDomain",
      dependencies: [
        .product(name: "StateTree", package: "StateTree"),
        .product(name: "OrderedCollections", package: "swift-collections"),
      ]
    ),
  ]
)
