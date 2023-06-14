// swift-tools-version: 5.8

import class Foundation.ProcessInfo
import PackageDescription

// MARK: - Build

enum Build {
  static let isVerbose: Bool = {
    let value = ProcessInfo.processInfo.environment["VERBOSE_BUILD"] == "1"
    // trigger initial print that shows up next to 'warning' indicator.
    if value {
      print("[🏗️ Printing build context]")
    }
    return value
  }()

  static let usesCustomTreeActor: Bool = {
    ProcessInfo.processInfo.environment["CUSTOM_ACTOR"] == "1"
  }()

  static let platformSupportsSwiftUI: Bool = {
    #if !canImport(SwiftUI)
    return false
    #else
    return true
    #endif
  }()

  static let globalSwiftSettings: [SwiftSetting] = {
    var settings: [SwiftSetting] = []
    if usesCustomTreeActor {
      printContext("[🛠️ - @TreeActor aliased to custom global actor]")
      settings.append(.define("CUSTOM_ACTOR"))
    } else {
      printContext("[🎨 - @TreeActor aliased to @MainActor]")
    }
    settings.append(contentsOf: [
      .enableUpcomingFeature("ConciseMagicFile"),
      .enableUpcomingFeature("ExistentialAny"),
      .enableUpcomingFeature("StrictConcurrency"),
      .enableUpcomingFeature("ImplicitOpenExistentials"),
      .enableUpcomingFeature("BareSlashRegexLiterals"),
    ])
    return settings
  }()

  static var shouldBuildSwiftUI: Bool { !usesCustomTreeActor && platformSupportsSwiftUI }

  static func printContext(_ context: String) {
    if isVerbose {
      print(context)
    }
  }
}

extension Package {
  func filteredForCompatibility() -> Package {
    if Build.shouldBuildSwiftUI {
      Build.printContext("[🍎 - SwiftUI build enabled]")
    } else {
      Build.printContext("[🐧 - SwiftUI build disabled]")
      targets.removeAll { $0.name.contains("SwiftUI") }
      products.removeAll { $0.name.contains("SwiftUI") }
    }
    return self
  }
}

// MARK: Package definition

let package = Package(
  name: "StateTree",
  platforms: [
    .macOS("12.3"),
    .iOS("15.4"),
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
    .library(
      name: "StateTreeImperativeUI",
      targets: [
        "StateTreeImperativeUI",
      ]
    ),
    .library(
      name: "StateTreeTesting",
      targets: [
        "StateTreeTesting",
      ]
    ),
  ],
  dependencies: [
    .package(
      url: "https://github.com/GoodHatsLLC/Disposable.git",
      "0.8.0" ..< "0.9.0"
    ),
    .package(
      url: "https://github.com/GoodHatsLLC/Emitter.git",
      "0.8.5" ..< "0.9.0"
    ),
    .package(
      url: "https://github.com/GoodHatsLLC/swift-collections-v1_1-fork.git",
      "1.1.0" ..< "1.2.0"
    ),
    .package(
      url: "https://github.com/apple/swift-docc-plugin",
      from: "1.1.0"
    ),
  ],
  targets: [
    .target(
      name: "Intents",
      dependencies: [
        "Utilities",
      ],
      swiftSettings: Build.globalSwiftSettings
    ),
    .target(
      name: "TreeActor",
      swiftSettings: Build.globalSwiftSettings
    ),
    .target(
      name: "Utilities",
      dependencies: [
        "Disposable",
        .product(name: "OrderedCollections", package: "swift-collections-v1_1-fork"),
      ],
      swiftSettings: Build.globalSwiftSettings
    ),
    .target(
      name: "Behavior",
      dependencies: [
        "Disposable",
        "Emitter",
        "TreeActor",
        "Utilities",
      ],
      swiftSettings: Build.globalSwiftSettings
    ),
    .target(
      name: "StateTree",
      dependencies: [
        "Behavior",
        "Disposable",
        "Emitter",
        "Intents",
        "TreeActor",
        "Utilities",
        .product(name: "HeapModule", package: "swift-collections-v1_1-fork"),
        .product(name: "OrderedCollections", package: "swift-collections-v1_1-fork"),
      ],
      swiftSettings: Build.globalSwiftSettings
    ),
    .target(
      name: "StateTreeSwiftUI",
      dependencies: [
        "Behavior",
        "Disposable",
        "Emitter",
        "Intents",
        "StateTree",
        "StateTreePlayback",
        "TreeActor",
        "Utilities",
      ],
      swiftSettings: Build.globalSwiftSettings
    ),
    .target(
      name: "StateTreeTesting",
      dependencies: [
        "StateTree",
        "StateTreePlayback",
      ],
      swiftSettings: Build.globalSwiftSettings
    ),
    .target(
      name: "StateTreeImperativeUI",
      dependencies: [
        "StateTree",
        "TreeActor",
      ],
      swiftSettings: Build.globalSwiftSettings
    ),
    .target(
      name: "StateTreePlayback",
      dependencies: [
        "StateTree",
      ],
      swiftSettings: Build.globalSwiftSettings
    ),
    .testTarget(
      name: "StateTreeTests",
      dependencies: [
        "StateTree",
        "Disposable",
        .product(name: "HeapModule", package: "swift-collections-v1_1-fork"),
      ]
    ),
    .testTarget(
      name: "StateTreeImperativeUITests",
      dependencies: [
        "StateTree",
        "StateTreeImperativeUI",
      ]
    ),
    .testTarget(
      name: "StateTreePlaybackTests",
      dependencies: [
        "StateTreePlayback",
      ]
    ),
    .testTarget(
      name: "StateTreeSwiftUITests",
      dependencies: [
        "StateTreeSwiftUI",
      ]
    ),
    .testTarget(
      name: "BehaviorTests",
      dependencies: ["Behavior"]
    ),
    .testTarget(
      name: "IntentsTests",
      dependencies: ["Intents"]
    ),
    .testTarget(
      name: "UtilitiesTests",
      dependencies: ["Utilities"]
    ),
  ]
)
.filteredForCompatibility()
