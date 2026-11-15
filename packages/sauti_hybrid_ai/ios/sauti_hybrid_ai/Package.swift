// swift-tools-version: 5.9
// Sauti hybrid inference bridge (iOS).
//
// Hybrid inference requires Swift Package Manager: Firebase AI Logic's
// GeminiLanguageModel (cloud fallback for Apple's Foundation Models) is only
// distributed through SPM. The Firebase version range must include the exact
// version pinned by firebase_core (13.1.1 at the time of writing).

import PackageDescription

let package = Package(
  name: "sauti_hybrid_ai",
  platforms: [
    .iOS("15.0")
  ],
  products: [
    .library(name: "sauti-hybrid-ai", targets: ["sauti_hybrid_ai"])
  ],
  dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk", "13.0.0"..<"14.0.0"),
    .package(name: "FlutterFramework", path: "../FlutterFramework"),
  ],
  targets: [
    .target(
      name: "sauti_hybrid_ai",
      dependencies: [
        .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
        .product(name: "FirebaseAILogic", package: "firebase-ios-sdk"),
        .product(name: "FlutterFramework", package: "FlutterFramework"),
      ]
    )
  ]
)
