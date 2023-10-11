//
//  File.swift
//  
//
//  Created by CodeBuilder on 07/10/2023.
//

import Foundation
import ArgumentParser


extension PythonSwiftProjectCLI {
	
	
	
	struct Kivy: AsyncParsableCommand {
		
		
		static var configuration: CommandConfiguration = .init(
			subcommands: [Create.self, GenerateSpec.self]
		)
		
		
		
		
	}
	
	
}

