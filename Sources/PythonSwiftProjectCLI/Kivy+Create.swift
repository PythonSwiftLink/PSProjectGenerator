//
//  Kivy+Project.swift
//


import Foundation
import PathKit
import ArgumentParser
import PSProjectGen





extension PythonSwiftProjectCLI.Kivy {
	
	
	struct Create: AsyncParsableCommand {
		@Argument var name: String
		
		@Option(name: .short) var python_src: String?
		
		@Option(name: .short) var requirements: String?
		
		func run() async throws {
			let proj = try await KivyProject(name: name, py_src: python_src, requirements: requirements)
			try await proj.createStructure()
			try await proj.generate()
		}
	}
}
