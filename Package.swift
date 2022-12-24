// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "StateTree",
  platforms: [
    .iOS(.v15),
    .macOS(.v12),
  ],
  products: [
    .library(
      name: "StateTree",
      targets: [
        "StateTree"
      ]
    ),
    .library(
      name: "StateTreeSwiftUI",
      targets: [
        "StateTreeSwiftUI"
      ]
    ),
    .library(
      name: "StateTreeUIKit",
      targets: [
        "StateTreeUIKit"
      ]
    ),
  ],
  dependencies: [
    .package(
      url: "https://github.com/GoodHatsLLC/AccessTracker.git", .upToNextMajor(from: "0.1.0")
    ),
    .package(url: "https://github.com/GoodHatsLLC/Bimapping.git", .upToNextMajor(from: "0.1.0")),
    .package(url: "https://github.com/GoodHatsLLC/Disposable.git", .upToNextMajor(from: "0.1.0")),
    .package(
      url: "https://github.com/GoodHatsLLC/Emitter.git",
      revision: "5ac9aae127991bb573f07b121d3bd87cb5419319"
    ),
    .package(
      url: "https://github.com/GoodHatsLLC/Projection.git",
      revision: "7126470a9c130b493549447b692c4c89e21582ac"
    ),

    .package(
      url: "https://github.com/GoodHatsLLC/SourceLocation.git", .upToNextMajor(from: "0.1.0")
    ),
    .package(url: "https://github.com/apple/swift-log.git", .upToNextMajor(from: "1.4.0")),
  ],
  targets: [
    .target(
      name: "StateTreeSwiftUI",
      dependencies: [
        "AccessTracker",
        "Behavior",
        "Dependencies",
        "Emitter",
        "TreeJSON",
        "Model",
        "Node",
        "Projection",
        "Tree",
        "Utilities",
      ]
    ),
    .target(
      name: "StateTreeUIKit",
      dependencies: [
        "AccessTracker",
        "Behavior",
        "Dependencies",
        "Emitter",
        "Model",
        "Node",
        "Projection",
        "Tree",
        "Utilities",
      ]
    ),
    .target(
      name: "StateTree",
      dependencies: [
        "AccessTracker",
        "Behavior",
        "Dependencies",
        "Emitter",
        "Model",
        "Node",
        "Projection",
        "Tree",
        "Utilities",
      ]
    ),
    .target(
      name: "TreeJSON",
      dependencies: [
        "Tree",
        "Emitter",
        "ModelInterface",
      ]
    ),
    .target(
      name: "Tree",
      dependencies: [
        "AccessTracker",
        "Behavior",
        "Model",
        "Node",
        "Projection",
        "TreeInterface",
        "Emitter",
        "Utilities",
      ]
    ),
    .target(
      name: "TreeInterface",
      dependencies: [
        "BehaviorInterface",
        "SourceLocation",
      ]
    ),
    .target(name: "ModelInterface"),
    .target(
      name: "Behavior",
      dependencies: [
        "BehaviorInterface",
        "Disposable",
        "SourceLocation",
      ]
    ),
    .target(
      name: "BehaviorInterface",
      dependencies: [
        "SourceLocation"
      ]
    ),
    .target(
      name: "Model",
      dependencies: [
        "AccessTracker",
        "Bimapping",
        "Behavior",
        "Dependencies",
        "Emitter",
        "ModelInterface",
        "Node",
        "Projection",
        "TreeInterface",
        "Utilities",
      ]
    ),
    .target(
      name: "Node",
      dependencies: [
        "AccessTracker",
        "Dependencies",
        "Emitter",
        "ModelInterface",
        "Projection",
        "Utilities",
      ]
    ),
    .target(
      name: "Utilities",
      dependencies: [
        "Dependencies",
        "Disposable",
        "SourceLocation",
        .product(name: "Logging", package: "swift-log"),
      ]
    ),
    .target(
      name: "Dependencies"
    ),

    // MARK: - Test targets

    .testTarget(name: "DependenciesTests", dependencies: ["Dependencies"]),
    .testTarget(name: "ModelTests", dependencies: ["Model"]),
    .testTarget(name: "TreeTests", dependencies: ["Tree", "TreeJSON"]),
    .testTarget(name: "UtilitiesTests", dependencies: ["Utilities"]),
  ]
)
