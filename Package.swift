// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "bl-speech-recognizer",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15)
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "bl-speech-recognizer",
      targets: ["bl-speech-recognizer"]),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "bl-speech-recognizer"
    ),
    .testTarget(
      name: "bl-speech-recognizerTests",
      dependencies: ["bl-speech-recognizer"]
    ),
  ]
)
