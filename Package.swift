// swift-tools-version: 5.8

import class Foundation.ProcessInfo
import PackageDescription

// MARK: Package definition

let package = Package(
  name: "StateTree",
  platforms: [
    .macOS("12.3"),
    .iOS("15.4"),
    .tvOS("15.4"),
    .watchOS("8.5"),
    .macCatalyst("15.4"),
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
    )
    .contingent(on: Env.supportsSwiftUI),
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
  ].compactMap { $0 },
  dependencies: [
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0")
      .contingent(on: Env.requiresDocCPlugin),
    .package(
      url: "https://github.com/GoodHatsLLC/Disposable.git",
      .upToNextMajor(from: "1.0.0")
    ),
    .package(
      url: "https://github.com/GoodHatsLLC/Emitter.git",
      .upToNextMajor(from: "1.0.0")
    ),
    .package(
      url: "https://github.com/GoodHatsLLC/swift-collections-v1_1-fork.git",
      .upToNextMinor(from: "1.1.0")
    ),
    .package(url: "https://github.com/GoodHatsLLC/SwiftLintFix.git", from: "0.1.0"),
  ].compactMap { $0 },
  targets: [
    .target(
      name: "Intents",
      dependencies: [
        "Utilities",
      ],
      exclude: [
        "ThirdParty/URLEncoder/LICENSE.md",
      ],
      swiftSettings: Env.swiftSettings
    ),
    .target(
      name: "TreeActor",
      swiftSettings: Env.swiftSettings
    ),
    .target(
      name: "Utilities",
      dependencies: [
        "Disposable",
        .product(name: "OrderedCollections", package: "swift-collections-v1_1-fork"),
      ],
      exclude: [
        "ThirdParty/AnyAsyncSequence/LICENSE.md",
        "ThirdParty/RuntimeWarning/LICENSE.md",
        "ThirdParty/SipHash/LICENSE.md",
      ],
      swiftSettings: Env.swiftSettings
    ),
    .target(
      name: "Behavior",
      dependencies: [
        "Disposable",
        "Emitter",
        "TreeActor",
        "Utilities",
      ],
      swiftSettings: Env.swiftSettings
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
      swiftSettings: Env.swiftSettings
    ),
    .target(
      name: "StateTreeSwiftUI",
      dependencies: [
        "StateTree",
        "StateTreePlayback",
      ],
      swiftSettings: Env.swiftSettings
    ).contingent(on: Env.supportsSwiftUI),
    .target(
      name: "StateTreeTesting",
      dependencies: [
        "StateTree",
        "StateTreePlayback",
      ],
      swiftSettings: Env.swiftSettings
    ),
    .target(
      name: "StateTreeImperativeUI",
      dependencies: [
        "StateTree",
      ],
      swiftSettings: Env.swiftSettings
    ),
    .target(
      name: "StateTreePlayback",
      dependencies: [
        "StateTree",
      ],
      swiftSettings: Env.swiftSettings
    ),
    .testTarget(
      name: "StateTreeTests",
      dependencies: [
        "StateTree",
        .product(name: "HeapModule", package: "swift-collections-v1_1-fork"),
      ]
    ),
    .testTarget(
      name: "StateTreeImperativeUITests",
      dependencies: [
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
    )
    .contingent(on: Env.supportsSwiftUI),
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
  ].compactMap { $0 }
)

// MARK: - Env

private enum Env {

  // MARK: Internal

  static let isVerbose: Bool = {
    let value: Bool = {
      ProcessInfo.processInfo.environment["VERBOSE"] == "1"
    }()
    // trigger initial print that shows up next to 'warning' indicator.
    if value {
      print("[🏗️ - Verbose build enabled]")
    }
    return value
  }()

  static let requiresDocCPlugin: Bool = {
    let shouldBuildDocC = ProcessInfo.processInfo.environment["DOCC"] == "1"
    if shouldBuildDocC {
      verboseContext("[📝 - Building DocC plugin]")
    }
    return shouldBuildDocC
  }()

  static let swiftSettings: [SwiftSetting] = {
    var settings: [SwiftSetting] = []
    if treeActorIsNonMain {
      verboseContext("[🛠️ - @TreeActor aliased to custom global actor]")
      settings.append(.define("CUSTOM_ACTOR"))
    } else {
      verboseContext("[🎨 - @TreeActor aliased to @MainActor]")
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

  static let supportsSwiftUI: Bool = {
    if !treeActorIsNonMain, canImportSwiftUI {
      verboseContext("[🎨 - SwiftUI build enabled]")
      return true
    } else {
      verboseContext("[📵 - SwiftUI build disabled]")
      return false
    }
  }()

  static func verboseContext(_ context: String) {
    if isVerbose {
      print(context)
    }
  }

  // MARK: Private

  private static let treeActorIsNonMain: Bool = {
    if ProcessInfo.processInfo.environment["CUSTOM_ACTOR"] == "1" {
      verboseContext("[🎄 - @TreeActor != @MainActor]")
      return true
    } else {
      verboseContext("[🌳 - @TreeActor == @MainActor]")
      return false
    }
  }()

  private static let canImportSwiftUI: Bool = {
    #if !canImport(SwiftUI)
    verboseContext("[🐧 - SwiftUI is unavailable]")
    return false
    #else
    verboseContext("[🍎 - SwiftUI can be imported]")
    return true
    #endif
  }()

}

// MARK: - ConditionalArtifact

private protocol ConditionalArtifact { }
extension ConditionalArtifact {
  func
    contingent(on filter: Bool) -> Self?
  {
    if filter {
      return self
    } else {
      return nil
    }
  }
}

// MARK: - Package.Dependency + ConditionalArtifact

extension Package.Dependency: ConditionalArtifact { }

// MARK: - Target + ConditionalArtifact

extension Target: ConditionalArtifact { }

// MARK: - Product + ConditionalArtifact

extension Product: ConditionalArtifact { }
