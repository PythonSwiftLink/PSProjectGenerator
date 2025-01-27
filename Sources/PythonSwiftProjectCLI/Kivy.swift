//
//  File.swift
//  
//
//  Created by CodeBuilder on 07/10/2023.
//

import Foundation
import ArgumentParser
import PathKit

extension PathKit.Path: ExpressibleByArgument {
	public init?(argument: String) {
		self.init(argument)
	}
}

extension PythonSwiftProjectCLI {
	
	
	
	struct Kivy: AsyncParsableCommand {
		
		
		public static var configuration: CommandConfiguration = .init(
			subcommands: [Create.self, GenerateSpec.self, Patch.self, Recipe.self]
		)
		
		
		
		
	}
	
	
}

