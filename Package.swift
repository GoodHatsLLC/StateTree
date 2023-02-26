// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "StateTree",
  platforms: [
    .macOS(.v12),
    .iOS(.v14),
  ],
  products: [
    .library(
      name: "StateTree",
      targets: [
        "StateTree",
      ]
    ),
    .library(
      name: "StateTreeSwiftUI",
      targets: [
        "StateTreeSwiftUI",
      ]
    ),
  ],
  dependencies: [
    .package(
      url: "https://github.com/GoodHatsLLC/Disposable.git",
      from: .init(0, 6, 0)
    ),
    .package(
      url: "https://github.com/GoodHatsLLC/Emitter.git",
      from: .init(0, 2, 0)
    ),
    .package(
      url: "https://github.com/apple/swift-collections.git",
      branch: "release/1.1"
    ),
  ],
  targets: [
    .target(
      name: "StateTree",
      dependencies: [
        "Disposable",
        "Emitter",
        "TreeState",
        .product(name: "HeapModule", package: "swift-collections"),
      ]
    ),
    .target(
      name: "StateTreeSwiftUI",
      dependencies: [
        "StateTree",
        "TimeTravel",
      ]
    ),
    .target(
      name: "TimeTravel",
      dependencies: [
        "StateTree",
      ]
    ),
    .target(
      name: "TreeState"
    ),
    .testTarget(
      name: "StateTreeTests",
      dependencies: [
        "StateTree",
        "Disposable",
        .product(name: "HeapModule", package: "swift-collections"),
      ]
    ),
    .testTarget(
      name: "StateTreeSwiftUITests",
      dependencies: [
        "StateTreeSwiftUI",
      ]
    ),
    .testTarget(
      name: "TreeStateTests",
      dependencies: [
        "TreeState",
        "Disposable",
        .product(name: "HeapModule", package: "swift-collections"),
      ]
    ),
  ]
)
