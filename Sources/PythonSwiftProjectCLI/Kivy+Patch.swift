//
//  File.swift
//  
//
//  Created by CodeBuilder on 08/01/2024.
//

import Foundation
import PathKit
import ArgumentParser
import PSProjectGen
extension PythonSwiftProjectCLI.Kivy {
	
	struct Patch: AsyncParsableCommand {
		
		@Option(name: .short) var project_path: String
		
		func run() async throws {
			let workingDir: Path = .init(project_path)
			let resources = workingDir + "Resources"
			var mainSiteFolder: Path { resources + "site-packages" }
			var distFolder: Path { workingDir + "dist_lib"}
			
			var site_folders: [Path] {
				
				var output: [Path] = [ mainSiteFolder ]
				let numpySite = resources + "numpy-site"
				if numpySite.exists {
					output.append(numpySite)
				}
				
				return output
			}
			for site_folder in site_folders {
				try patchPythonLib(pythonLib: site_folder, dist: distFolder)
			}
		}
	}
	
	
}
