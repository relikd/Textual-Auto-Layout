// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "TextualAutoLayout",
	platforms: [
		.macOS(.v10_11), .iOS(.v9), .tvOS(.v9) // watchOS does not support NSLayout
    ],
    products: [
        .library(name: "TextualAutoLayout", targets: ["TextualAutoLayout"]),
    ],
    targets: [
        .target(name: "TextualAutoLayout", dependencies: []),
        .testTarget(name: "TextualAutoLayoutTests", dependencies: ["TextualAutoLayout"]),
    ]
)
