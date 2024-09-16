import Foundation
import PathKit
import ArgumentParser
import PSProjectGen
import RecipeBuilder


extension PythonSwiftProjectCLI.Kivy {
	
	struct Recipe: AsyncParsableCommand {
		
		@Argument var recipe: String
		@Argument var spec: Path
		@Option(name: .shortAndLong) var path: String?
		
		@Option(name: .shortAndLong) var output: Path?
		
		func run() async throws {
			try await RecipeBuilder(recipe: recipe, spec: spec, path: path, output: output).run()
		}
	}
}
