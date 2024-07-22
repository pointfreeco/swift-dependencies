// swift-tools-version: 5.9

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "swift-dependencies",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    .library(
      name: "Dependencies",
      targets: ["Dependencies"]
    ),
    .library(
      name: "DependenciesMacros",
      targets: ["DependenciesMacros"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/combine-schedulers", branch: "swift-testing"),
    .package(url: "https://github.com/pointfreeco/swift-clocks", branch: "swift-testing"),
    .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-issue-reporting", from: "1.2.0"),
    .package(url: "https://github.com/swiftlang/swift-syntax", "509.0.0"..<"601.0.0-prerelease"),
  ],
  targets: [
    .target(
      name: "DependenciesTestObserver",
      dependencies: [
        .product(name: "IssueReporting", package: "swift-issue-reporting"),
      ]
    ),
    .target(
      name: "Dependencies",
      dependencies: [
        .product(name: "Clocks", package: "swift-clocks"),
        .product(name: "CombineSchedulers", package: "combine-schedulers"),
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        .product(name: "IssueReporting", package: "swift-issue-reporting"),
        .product(name: "XCTestDynamicOverlay", package: "swift-issue-reporting"),
      ]
    ),
    .testTarget(
      name: "DependenciesTests",
      dependencies: [
        "Dependencies",
        "DependenciesMacros",
        .product(name: "IssueReportingTestSupport", package: "swift-issue-reporting"),
      ]
    ),
    .target(
      name: "DependenciesMacros",
      dependencies: [
        "DependenciesMacrosPlugin",
        .product(name: "IssueReporting", package: "swift-issue-reporting"),
      ]
    ),
    .macro(
      name: "DependenciesMacrosPlugin",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
    ),
  ]
)

#if !os(macOS) && !os(WASI)
  package.products.append(
    .library(
      name: "DependenciesTestObserver",
      type: .dynamic,
      targets: ["DependenciesTestObserver"]
    )
  )
#endif

#if !os(WASI)
  package.dependencies.append(contentsOf: [
    .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.2.0"),
  ])
  package.targets.append(contentsOf: [
    .testTarget(
      name: "DependenciesMacrosPluginTests",
      dependencies: [
        "DependenciesMacros",
        "DependenciesMacrosPlugin",
        .product(name: "MacroTesting", package: "swift-macro-testing"),
      ]
    )
  ])
#endif

#if !os(Windows)
  // Add the documentation compiler plugin if possible
  package.dependencies.append(
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
  )
#endif

for target in package.targets {
  target.swiftSettings = target.swiftSettings ?? []
  target.swiftSettings?.append(contentsOf: [
    .enableExperimentalFeature("StrictConcurrency")
  ])
}
