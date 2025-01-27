// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser

@main
struct PythonSwiftProjectCLI: AsyncParsableCommand {
	
	static var configuration: CommandConfiguration = .init(
		version: "0.0.8",
		subcommands: [Kivy.self, SwiftUI.self]
	)
	
	
	enum CodingKeys: CodingKey {
	}
	

	
}
