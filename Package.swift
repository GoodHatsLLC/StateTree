// swift-tools-version: 5.7

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
    .library(
      name: "StateTreeReporter",
      targets: [
        "StateTreeReporter",
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
      ],
      swiftSettings: Build.globalSwiftSettings
    ),
    .target(
      name: "StateTreeSwiftUI",
      dependencies: [
        "StateTree",
        "StateTreePlayback",
      ],
      swiftSettings: Build.globalSwiftSettings
    ),
    .target(
      name: "StateTreeReporter",
      dependencies: [
        "StateTree",
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
    .target(
      name: "TreeState",
      swiftSettings: Build.globalSwiftSettings
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
.filteredForCompatibility()
