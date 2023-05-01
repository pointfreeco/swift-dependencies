// swift-tools-version: 5.6

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
    )
  ],
  dependencies: [
    .package(url: "https://github.com/google/swift-benchmark", from: "0.1.0"),
    .package(url: "https://github.com/pointfreeco/combine-schedulers", from: "0.10.0"),
    .package(url: "https://github.com/pointfreeco/swift-clocks", from: "0.3.0"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "0.8.0"),
  ],
  targets: [
    .target(
      name: "Dependencies",
      dependencies: [
        .product(name: "CombineSchedulers", package: "combine-schedulers"),
        .product(name: "Clocks", package: "swift-clocks"),
        .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay"),
      ]
    ),
    .testTarget(
      name: "DependenciesTests",
      dependencies: [
        "Dependencies"
      ]
    ),
    .executableTarget(
      name: "swift-dependencies-benchmark",
      dependencies: [
        "Dependencies",
        .product(name: "Benchmark", package: "swift-benchmark"),
      ]
    ),
  ]
)

#if swift(>=5.6)
  // Add the documentation compiler plugin if possible
  package.dependencies.append(
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
  )
#endif

//for target in package.targets {
//  target.swiftSettings = target.swiftSettings ?? []
//  target.swiftSettings?.append(
//    .unsafeFlags([
//      "-Xfrontend", "-warn-concurrency",
//      "-Xfrontend", "-enable-actor-data-race-checks",
//      "-enable-library-evolution",
//    ])
//  )
//}
