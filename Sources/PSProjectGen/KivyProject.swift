//
//  File.swift
//  
//
//  Created by CodeBuilder on 08/10/2023.
//

import Foundation

import PathKit
import XcodeGenKit
import ProjectSpec

enum KivyCreateError: Error, CustomStringConvertible {
	case missingProjectSpec(Path)
	case projectSpecParsingError(Error)
	case cacheGenerationError(Error)
	case validationError(SpecValidationError)
	case generationError(Error)
	case missingUsername
	case writingError(Error)
	
	var description: String {
		switch self {
		case let .missingProjectSpec(path):
			return "No project spec found at \(path.absolute())"
		case let .projectSpecParsingError(error):
			return "Parsing project spec failed: \(error)"
		case let .cacheGenerationError(error):
			return "Couldn't generate cache file: \(error)"
		case let .validationError(error):
			return error.description
		case let .generationError(error):
			return String(describing: error)
		case .missingUsername:
			return "Couldn't find current username"
		case let .writingError(error):
			return String(describing: error)
		}
	}
	
	var message: String? {
		description
	}
	
	var exitStatus: Int32 {
		1
	}
}

extension PathKit.Path {
	
	static func pythonLib() async throws -> Path {
		let folder: Path = .current + "python_lib"
		if folder.exists { return folder }
		try await downloadZipUnPacked(
			url: "https://github.com/PythonSwiftLink/KivyCore/releases/download/0.0.0/python_lib.zip",
			dst: current + "python_lib.zip"
		)
		return .current + "python_lib"
	}
	
	static func distLib() async throws -> Path {
		let folder: Path = .current + "dist_lib"
		if folder.exists { return folder }
		return try await downloadZipUnPacked(
			url: "https://github.com/PythonSwiftLink/KivyCore/releases/download/0.0.0/dist_lib.zip",
			dst: current + "dist_lib.zip"
		)
	}
	
}

func patchPythonLib(dist: Path) throws {
	let lib = Path.current + "lib"
	let libs = lib.iterateChildren().filter( {$0.extension == "libs"} )
	try libs.forEach { file in
		var content = try String(contentsOf: file.url)
		content = content.replacingOccurrences(
			of: "/Users/runner/work/KivyCoreBuilder/KivyCoreBuilder/kivy_build/dist/lib",
			with: "\(dist.string)"
		)
		try file.write(content, encoding: .utf8)
	}
}

public class KivyProject {
	
	var name: String
	
	var pythonProject: String {
		(Path.current + "py_src").string
	}
	
	public init(name: String) async throws {
		self.name = name
		
		let current = Path.current
		
		try? (current + "YourApp").mkdir()
		try? (current + "wrapper_sources").mkdir()
		try? (current + "Resources").mkdir()
		
		let python_lib = try await Path.pythonLib()
		let move_lib: Path = .current + "lib"
		if move_lib.exists {
			try move_lib.delete()
		}
		try python_lib.move(move_lib)

		try patchPythonLib(dist: try await Path.distLib())
		let kivyAppFiles = current + "KivyAppFiles"
		if kivyAppFiles.exists {
			try kivyAppFiles.delete()
		}
		gitClone("https://github.com/PythonSwiftLink/KivyAppFiles")
		let sourcesPath = Path.current + "Sources"
		if sourcesPath.exists {
			try sourcesPath.delete()
		}
		try (kivyAppFiles + "Sources").move(sourcesPath)
		
		
		
		
		// clean up
		
		if kivyAppFiles.exists {
			try kivyAppFiles.delete()
		}
	}
	
	func projSettings() async throws -> Settings {
		let dist_lib = (try await Path.distLib()).string
		var configSettings: Settings {
			[
				"LIBRARY_SEARCH_PATHS": [
					"\"$(inherited)\"",
					dist_lib
				],
				"SWIFT_VERSION": "5.0",
				"OTHER_LDFLAGS": "-all_load"
			]
		}
		return .init(configSettings: [
			"debug": configSettings,
			"release": configSettings
		])
		
	}
	
	var configFiles: [String:String] {
		[:]
	}
	
	func sources() async throws -> [TargetSource] {
		
		let current = PathKit.Path.current
		
		var testPath: Path {
			
			return (current + "Sources")
		}
		
		let python_lib = (Path.current + "lib" ) //try await Path.pythonLib()
		
		
		//let site_packs = python_lib + "python3.10/site-packages"
		
		
		return [
			//.init(path: current.string),
			TargetSource(path: (testPath).string, type: .group),
			//.init(path: "Resources", type: .group),
			.init(path: "YourApp", group: "Resources", type: .file, buildPhase: .resources, createIntermediateGroups: true),
			.init(path: python_lib.string, group: "Resources", type: .file, buildPhase: .resources, createIntermediateGroups: true),
		]
	}
	
	var dependencies: [Dependency] {
		[
			.init(type: .package(product: "PySwiftObject"), reference: "KivySwiftLink"),
			.init(type: .package(product: "PythonSwiftCore"), reference: "KivySwiftLink"),
			.init(type: .package(product: "KivyLauncher"), reference: "KivySwiftLink"),
		]
	}
	
	func info() throws -> Plist {
		.init(path: "Info.plist" )
		
	}
	var preBuildScripts: [BuildScript] {
		[
			.init(
				script: .script("""
					rsync -av --delete "\(pythonProject)"/ "$PROJECT_DIR"/YourApp
					"""
				),
				name: "Sync Project"
			),
			.init(
				script: .script("""
					python3.10 -m compileall -f -b "$PROJECT_DIR"/YourApp
					"""
			),
				name: "Compile Python Files"
			),
			.init(
				script: .script("""
					find "$PROJECT_DIR"/YourApp/ -regex '.*\\.py' -delete
					"""
				),
				name: "Delete .py leftovers"
			)
		]
	}
	var buildToolPlugins: [BuildToolPlugin] {
		[.init(plugin: "Swiftonize", package: "SwiftonizePlugin")]
	}
	var postCompileScripts: [BuildScript] {
		[]
	}
	var postBuildScripts: [BuildScript] {
		[
		]
	}
	
	var attributes: [String : Any] {
		[:]
	}
	func target() async throws -> Target {
		let output = Target(
			name: name,
			type: .application,
			platform: .iOS,
			productName: nil,
			deploymentTarget: .init("13.0"),
			settings: try await projSettings(),
			configFiles: configFiles,
			sources: try await sources(),
			dependencies: dependencies,
			info: try info(),
			entitlements: nil,
			transitivelyLinkDependencies: false,
			directlyEmbedCarthageDependencies: false,
			requiresObjCLinking: true,
			preBuildScripts: preBuildScripts,
			buildToolPlugins: buildToolPlugins,
			postCompileScripts: postCompileScripts,
			postBuildScripts: postBuildScripts,
			buildRules: [
				
			],
			scheme: nil,
			legacy: nil,
			attributes: attributes,
			onlyCopyFilesOnInstall: false,
			putResourcesBeforeSourcesBuildPhase: false
		)
		//let info = InfoPlistGenerator()
		
		return output
	}
	}
