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
      "0.6.1" ..< "0.7.0"
    ),
    .package(
      url: "https://github.com/GoodHatsLLC/Emitter.git",
      "0.2.1" ..< "0.3.0"
    ),
    .package(
      url: "https://github.com/apple/swift-collections.git",
      branch: "release/1.1"
    ),
    .package(
      url: "https://github.com/apple/swift-crypto.git",
      "2.2.4" ..< "3.0.0"
    ),
  ],
  targets: [
    .target(
      name: "StateTree",
      dependencies: [
        "Disposable",
        "Emitter",
        "TreeState",
        .product(name: "Crypto", package: "swift-crypto"),
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

#if os(Linux)
package.targets.removeAll(where: { $0.name.hasPrefix("StateTreeSwiftUI") })
package.products.removeAll(where: { $0.name.hasPrefix("StateTreeSwiftUI") })
#endif
