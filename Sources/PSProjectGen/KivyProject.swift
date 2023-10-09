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

public class KivyProjectTarget: PSProjTargetProtocol {
	
	public var name: String
	public var pythonProject: String
	
	var dist_lib: String
	
	public init(name: String, py_src: String, dist_lib: String) async throws {
		self.name = name
		self.pythonProject = py_src
		self.dist_lib = dist_lib
	}
	public func build() async throws {
	
	}
	
	public func projSettings() async throws -> ProjectSpec.Settings {
		
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
	
	public func configFiles() async throws -> [String : String] {
		[:]
	}
	
	public func sources() async throws -> [ProjectSpec.TargetSource] {
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
	
	public func dependencies() async throws -> [ProjectSpec.Dependency] {
		[
			.init(type: .package(product: "PySwiftObject"), reference: "KivySwiftLink"),
			.init(type: .package(product: "PythonSwiftCore"), reference: "KivySwiftLink"),
			.init(type: .package(product: "KivyLauncher"), reference: "KivySwiftLink"),
		]
	}
	
	public func info() async throws -> ProjectSpec.Plist {
		.init(path: "Info.plist" )
	}
	
	public func preBuildScripts() async throws -> [ProjectSpec.BuildScript] {
		[
			.init(
				script: .script("""
				rsync -av --delete "\(pythonProject)"/ "$PROJECT_DIR"/YourApp
				"""),
				name: "Sync Project"
			),
			.init(
				script: .script("""
				python3.10 -m compileall -f -b "$PROJECT_DIR"/YourApp
				"""),
				name: "Compile Python Files"
			),
			.init(
				script: .script("""
				find "$PROJECT_DIR"/YourApp/ -regex '.*\\.py' -delete
				"""),
				name: "Delete .py leftovers"
			)
		]
	}
	
	public func buildToolPlugins() async throws -> [ProjectSpec.BuildToolPlugin] {
		[.init(plugin: "Swiftonize", package: "SwiftonizePlugin")]
	}
	
	public func postCompileScripts() async throws -> [ProjectSpec.BuildScript] {
		[]
	}
	
	public func postBuildScripts() async throws -> [ProjectSpec.BuildScript] {
		[]
	}
	
	public func attributes() async throws -> [String : Any] {
		[:]
	}
	
	public func target() async throws -> ProjectSpec.Target {
		let output = Target(
			name: name,
			type: .application,
			platform: .iOS,
			productName: nil,
			deploymentTarget: .init("13.0"),
			settings: try await projSettings(),
			configFiles: try await configFiles(),
			sources: try await sources(),
			dependencies: try await dependencies(),
			info: try await info(),
			entitlements: nil,
			transitivelyLinkDependencies: false,
			directlyEmbedCarthageDependencies: false,
			requiresObjCLinking: true,
			preBuildScripts: try await preBuildScripts(),
			buildToolPlugins: try await buildToolPlugins(),
			postCompileScripts: try await postCompileScripts(),
			postBuildScripts: try await postBuildScripts(),
			buildRules: [
				
			],
			scheme: nil,
			legacy: nil,
			attributes: try await attributes(),
			onlyCopyFilesOnInstall: false,
			putResourcesBeforeSourcesBuildPhase: false
		)

		return output
	}
	
	
}


public class KivyProject: PSProjectProtocol {
	public var name: String
	
	public var py_src: String
	
	var _targets: [PSProjTargetProtocol]
	
	var requirements: String?
	
	public init(name: String, py_src: String, requirements: String?) async throws {
		self.name = name
		self.py_src = py_src
		
		_targets = [
			try await KivyProjectTarget(
				name: name,
				py_src: py_src,
				dist_lib: (try await Path.distLib()).string
			)
		]
	}
	public func targets() async throws -> [Target] {
		var output: [Target] = []
		for target in _targets {
			output.append( try await target.target() )
		}
		return output
	}
	
	public func configs() async throws -> [ProjectSpec.Config] {
		[.init(name: "debug", type: .debug),.init(name: "release", type: .release)]
	}
	
	public func schemes() async throws -> [ProjectSpec.Scheme] {
		[]
	}
	
	public func projSettings() async throws -> ProjectSpec.Settings {
		.empty
	}
	
	public func settingsGroup() async throws -> [String : ProjectSpec.Settings] {
		[:]
	}
	
	public func packages() async throws -> [String : ProjectSpec.SwiftPackage] {
		return [
			"SwiftonizePlugin": .remote(
				url: "https://github.com/pythonswiftlink/SwiftonizePlugin",
				versionRequirement: .branch("master")
			),
			"KivySwiftLink": .remote(
				url: "https://github.com/pythonswiftlink/KivySwiftLink",
				versionRequirement: .branch("master")
			)
		]
	}
	
	public func specOptions() async throws -> ProjectSpec.SpecOptions {
		return .init(bundleIdPrefix: "org.kivy")
	}
	
	public func fileGroups() async throws -> [String] {
		[]
	}
	public func configFiles() async throws -> [String : String] {
		[:]
	}
	public func attributes() async throws -> [String : Any] {
		[:]
	}
	
	public func projectReferences() async throws -> [ProjectSpec.ProjectReference] {
		[]
	}
	
	public func projectBasePath() async throws -> PathKit.Path {
		let base: Path = .current + "\(name).xcodeproj"
		if !base.exists {
			try! base.mkpath()
		}
		return base
	}
	public func createStructure() async throws {
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
		
		// pip installs
		if let requirements = requirements {
			let site_path: Path = move_lib + "python3.10/site-packages"
			pipInstall(.init(requirements), site_path: site_path)
		}
		
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
		for target in _targets {
			try await target.build()
		}
	}
	
	public func project() async throws -> ProjectSpec.Project {
		return Project(
			basePath: .current,
			name: name,
			configs: try await configs(),
			targets: try await targets(),
			aggregateTargets: [],
			settings: try await projSettings(),
			settingGroups: try await settingsGroup(),
			schemes: try await schemes(),
			breakpoints: [],
			packages: try await packages(),
			options: try await specOptions(),
			fileGroups: try await fileGroups(),
			configFiles: try await configFiles(),
			attributes: try await attributes(),
			projectReferences: []
		)
	}
	
	public func generate() async throws {
		let project = try await project()
		let fw = FileWriter(project: project)
		
		let projectGenerator = ProjectGenerator(project: project)
		
		guard let userName = ProcessInfo.processInfo.environment["LOGNAME"] else {
			throw KivyCreateError.missingUsername
		}
		
		let xcodeProject = try projectGenerator.generateXcodeProject(in: .current, userName: userName)
		
		try fw.writePlists()
		//
		
		try fw.writeXcodeProject(xcodeProject)
		
	}
}




//public class _KivyProject {
//	
//	var name: String
//	
//	
//	
//	var pythonProject: String 
////	{
////		(Path.current + "py_src").string
////	}
//	
//	public init(name: String, py_src: String) async throws {
//		self.name = name
//		self.pythonProject = py_src
//		let current = Path.current
//		
//		try? (current + "YourApp").mkdir()
//		try? (current + "wrapper_sources").mkdir()
//		try? (current + "Resources").mkdir()
//		
//		let python_lib = try await Path.pythonLib()
//		let move_lib: Path = .current + "lib"
//		if move_lib.exists {
//			try move_lib.delete()
//		}
//		try python_lib.move(move_lib)
//
//		try patchPythonLib(dist: try await Path.distLib())
//		let kivyAppFiles = current + "KivyAppFiles"
//		if kivyAppFiles.exists {
//			try kivyAppFiles.delete()
//		}
//		gitClone("https://github.com/PythonSwiftLink/KivyAppFiles")
//		let sourcesPath = Path.current + "Sources"
//		if sourcesPath.exists {
//			try sourcesPath.delete()
//		}
//		try (kivyAppFiles + "Sources").move(sourcesPath)
//		
//		
//		
//		
//		// clean up
//		
//		if kivyAppFiles.exists {
//			try kivyAppFiles.delete()
//		}
//	}
//	
//	func projSettings() async throws -> Settings {
//		let dist_lib = (try await Path.distLib()).string
//		var configSettings: Settings {
//			[
//				"LIBRARY_SEARCH_PATHS": [
//					"\"$(inherited)\"",
//					dist_lib
//				],
//				"SWIFT_VERSION": "5.0",
//				"OTHER_LDFLAGS": "-all_load"
//			]
//		}
//		return .init(configSettings: [
//			"debug": configSettings,
//			"release": configSettings
//		])
//		
//	}
//	
//	var configFiles: [String:String] {
//		[:]
//	}
//	
//	func sources() async throws -> [TargetSource] {
//		
//		let current = PathKit.Path.current
//		
//		var testPath: Path {
//			
//			return (current + "Sources")
//		}
//		
//		let python_lib = (Path.current + "lib" ) //try await Path.pythonLib()
//		
//		
//		//let site_packs = python_lib + "python3.10/site-packages"
//		
//		
//		return [
//			//.init(path: current.string),
//			TargetSource(path: (testPath).string, type: .group),
//			//.init(path: "Resources", type: .group),
//			.init(path: "YourApp", group: "Resources", type: .file, buildPhase: .resources, createIntermediateGroups: true),
//			.init(path: python_lib.string, group: "Resources", type: .file, buildPhase: .resources, createIntermediateGroups: true),
//		]
//	}
//	
//	var dependencies: [Dependency] {
//		[
//			.init(type: .package(product: "PySwiftObject"), reference: "KivySwiftLink"),
//			.init(type: .package(product: "PythonSwiftCore"), reference: "KivySwiftLink"),
//			.init(type: .package(product: "KivyLauncher"), reference: "KivySwiftLink"),
//		]
//	}
//	
//	func info() throws -> Plist {
//		.init(path: "Info.plist" )
//		
//	}
//	var preBuildScripts: [BuildScript] {
//		[
//			.init(
//				script: .script("""
//					rsync -av --delete "\(pythonProject)"/ "$PROJECT_DIR"/YourApp
//					"""
//				),
//				name: "Sync Project"
//			),
//			.init(
//				script: .script("""
//					python3.10 -m compileall -f -b "$PROJECT_DIR"/YourApp
//					"""
//			),
//				name: "Compile Python Files"
//			),
//			.init(
//				script: .script("""
//					find "$PROJECT_DIR"/YourApp/ -regex '.*\\.py' -delete
//					"""
//				),
//				name: "Delete .py leftovers"
//			)
//		]
//	}
//	var buildToolPlugins: [BuildToolPlugin] {
//		[.init(plugin: "Swiftonize", package: "SwiftonizePlugin")]
//	}
//	var postCompileScripts: [BuildScript] {
//		[]
//	}
//	var postBuildScripts: [BuildScript] {
//		[
//		]
//	}
//	
//	var attributes: [String : Any] {
//		[:]
//	}
//	func target() async throws -> Target {
//		let output = Target(
//			name: name,
//			type: .application,
//			platform: .iOS,
//			productName: nil,
//			deploymentTarget: .init("13.0"),
//			settings: try await projSettings(),
//			configFiles: configFiles,
//			sources: try await sources(),
//			dependencies: dependencies,
//			info: try info(),
//			entitlements: nil,
//			transitivelyLinkDependencies: false,
//			directlyEmbedCarthageDependencies: false,
//			requiresObjCLinking: true,
//			preBuildScripts: preBuildScripts,
//			buildToolPlugins: buildToolPlugins,
//			postCompileScripts: postCompileScripts,
//			postBuildScripts: postBuildScripts,
//			buildRules: [
//				
//			],
//			scheme: nil,
//			legacy: nil,
//			attributes: attributes,
//			onlyCopyFilesOnInstall: false,
//			putResourcesBeforeSourcesBuildPhase: false
//		)
//		//let info = InfoPlistGenerator()
//		
//		return output
//	}
//	}
