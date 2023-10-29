//
//  Kivy+Project.swift
//


import Foundation
import PathKit
import ArgumentParser
import PSProjectGen





extension PythonSwiftProjectCLI.Kivy {
	
	struct GenerateSpec: AsyncParsableCommand {
		func run() async throws {
			let specPath = (Path.current + "projectSpec.yml")
			if specPath.exists { throw CocoaError(.fileWriteFileExists) }
			try specPath.write("""
			# spec file when creating xcode project.

			development_team:
				# id: T5Q8XY2KM9 # add team for signing automatically, you can find it on https://developer.apple.com/account#MembershipDetailsCard

			info_plist:
				# NSBluetoothAlwaysUsageDescription: require bluetooth

			packages:
				# PyCoreBluetooth:
				#     url:  https://github.com/KivySwiftPackages/PyCoreBluetooth
				#     branch: master
				#     products: [ PyCoreBluetooth ] # what products to add to target
				#     # python wrap packages only
				#     python_imports: # defines what to append to import list
				#         products: [ PyCoreBluetooth ] # what products that has wrapper
				#         modules: [ corebluetooth ] # what modules to append to import list .init(name: "corebluetooth", module: PyInit_corebluetooth)

			pip_folders:
				# - path: /path/to/extra_pips

			pip_requirements:
				# - path: /path/to/requirements.txt
			
			toolchain_recipes:
				# - pillow
				
			""".replacingOccurrences(of: "\t", with: "    "), encoding: .utf8)
		}
	}
	
	struct Create: AsyncParsableCommand {
		@Argument var name: String
		
		@Option(name: .short) var python_src: String?
		
		@Option(name: .short) var requirements: String?
		
		@Option(name: .short) var swift_packages: String?
		
		@Flag(name: .short) var forced: Bool = false
		
		func run() async throws {
//			try await GithubAPI(owner: "PythonSwiftLink", repo: "KivyCore").handleReleases()
//			return
			let projDir = (Path.current + name)
			if forced, projDir.exists {
				try? projDir.delete()
			}
			try? projDir.mkdir()
			//chdir(projDir.string)
			let projectSpec: Path? = if let swift_packages = swift_packages {.init(swift_packages)} else { nil }
			let proj = try await KivyProject(
				name: name,
				py_src: python_src,
				requirements: requirements,
				//projectSpec: swift_packages == nil ? nil : .init(swift_packages!),
				projectSpec: projectSpec,
				workingDir: projDir
			)
			
			try await proj.createStructure()
			try await proj.generate()
			
			
		}
	}
}
