// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PythonSwiftProject",
	platforms: [.macOS(.v13)],
	products: [
		.executable(name: "PSProjectCLI", targets: ["PythonSwiftProjectCLI"]),
		.library(name: "PSProjectGen", targets: ["PSProjectGen"]),
	],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
		.package(url: "https://github.com/tuist/XcodeProj.git", exact: "8.15.0"),
		.package(url: "https://github.com/yonaskolb/XcodeGen.git", exact: "2.37.0"),
		.package(url: "https://github.com/1024jp/GzipSwift", from: .init(6, 0, 0)),
		.package(url: "https://github.com/marmelroy/Zip", from: .init(2, 1, 0)),
		.package(url: "https://github.com/apple/swift-syntax.git", .upToNextMajor(from: .init(509, 0, 0))),
		.package(url: "https://github.com/jpsim/Yams.git", .upToNextMajor(from: "5.0.6")),
		//.package(url: "https://github.com/PythonSwiftLink/SwiftPackageGen", from: .init(0, 0, 3)),
		.package(path: "../packages/SwiftPackageGen")
		
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
		
		.target(
			name: "PSProjectGen",
			
			dependencies: [
				.product(name: "XcodeGenKit", package: "XcodeGen"),
				.product(name: "ProjectSpec", package: "XcodeGen"),
				.product(name: "Gzip", package: "GzipSwift"),
				.product(name: "Zip", package: "Zip"),
				.product(name: "SwiftSyntax", package: "swift-syntax"),
				.product(name: "SwiftParser", package: "swift-syntax"),
				//.product(name: "SwiftSyntaxParser", package: "swift-syntax"),
				.product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
				.product(name: "Yams", package: "Yams"),
				.product(name: "RecipeBuilder", package: "SwiftPackageGen")
			],
			resources: [
				.copy("downloads.yml"),
				.copy("project_plist_keys.yml")
			]
			
			),
		.executableTarget(
			name: "PythonSwiftProjectGUI",
			dependencies: [
				"PSProjectGen",
				.product(name: "Gzip", package: "GzipSwift"),
				.product(name: "Zip", package: "Zip")
			]
			),
        .executableTarget(
            name: "PythonSwiftProjectCLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
//				.product(name: "XcodeGenKit", package: "XcodeGen"),
//				.product(name: "ProjectSpec", package: "XcodeGen"),
				"PSProjectGen",
				.product(name: "Gzip", package: "GzipSwift"),
				.product(name: "Zip", package: "Zip"),
				.product(name: "GeneratePackage", package: "SwiftPackageGen"),
				.product(name: "RecipeBuilder", package: "SwiftPackageGen")
            ]
        ),
    ]
)
