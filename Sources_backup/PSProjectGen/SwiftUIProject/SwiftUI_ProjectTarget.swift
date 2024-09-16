import Foundation
import AppKit
import PathKit
import XcodeGenKit
import ProjectSpec
import Yams



class SwiftUI_ProjectTarget: PSProjTargetProtocol {
	var name: String
	
	public var projectSpec: Path?
	var pythonProject: String
	let workingDir: Path
	
	init(name: String, pythonProject: String, workingDir: Path) {
		self.name = name
		//self.pythonProject = pythonProject
		self.workingDir = workingDir
		fatalError()
	}
	
	func projSettings() async throws -> ProjectSpec.Settings {
		var configDict: [String: Any] = [
			"LIBRARY_SEARCH_PATHS": [
				"$(inherited)",
			],
			"SWIFT_VERSION": "5.0",
			"OTHER_LDFLAGS": "-all_load",
			"ENABLE_BITCODE": false
		]
//		if let projectSpec = projectSpec {
//			try loadBuildConfigKeys(from: projectSpec, keys: &configDict)
//		}
		
		var configSettings: Settings {
			.init(dictionary: configDict)
		}
		
		return .init(configSettings: [
			"debug": configSettings,
			"release": configSettings
		])
	}
	
	func configFiles() async throws -> [String : String] {
		[:]
	}
	
	func sources() async throws -> [ProjectSpec.TargetSource] {
		let current = workingDir
		
		var sourcesPath: Path {
			
			return (current + "Sources")
		}
		
		var pips: [ProjectSpec.TargetSource] = [
			TargetSource(path: (sourcesPath).string, type: .group),
			.init(path: "Resources/PythonFiles", group: "Resources", type: .file, buildPhase: .resources, createIntermediateGroups: true),
			//.init(path: pythonLibPath.string, group: "Resources", type: .file, buildPhase: .resources, createIntermediateGroups: true),
			.init(path: "Resources/site-packages", name: "site-packages", type: .file, buildPhase: .resources ,createIntermediateGroups: true),
//			.init(path: "Resources/Images.xcassets"),
//			.init(path: "Resources/icon.png"),
		]
		
//		if let projectSpec = projectSpec {
//			try loadExtraPipFolders(from: projectSpec, pips: &pips)
//		}
		
		return pips
	}
	
	func dependencies() async throws -> [ProjectSpec.Dependency] {
		var output: [ProjectSpec.Dependency] = [

			.init(type: .package(product: "PySwiftObject"), reference: "PythonSwiftLink"),
			.init(type: .package(product: "PySwiftCore"), reference: "PythonSwiftLink"),
			//.init(type: .package(product: "KivyLauncher"), reference: "KivyLauncher"),
			
			
		]
//		if let packageSpec = projectSpec {
//			try loadPackageDependencies(from: packageSpec, output: &output)
//		}
		
		return output
	}
	
	func info() async throws -> ProjectSpec.Plist {
		var mainkeys: [String:Any] = [
			"UILaunchStoryboardName": "Launch Screen",
			"UIRequiresFullScreen": true
		]
		if let projectPkeys = Bundle.module.url(forResource: "project_plist_keys", withExtension: "yml") {
			try loadBasePlistKeys(from: projectPkeys, keys: &mainkeys)
		}
//		if let packageSpec = projectSpec {
//			var extraKeys = [String:Any]()
//			
//			try loadInfoPlistInfo(from: packageSpec, plist: &extraKeys)
//			
//			mainkeys.merge(extraKeys)
//			return .init(path: "Info.plist", attributes: mainkeys)
//		}
		
		return .init(path: "Info.plist", attributes: mainkeys)
	}
	
	func preBuildScripts() async throws -> [ProjectSpec.BuildScript] {
		[
			.init(
				script: .script("""
 rsync -av --delete "\(pythonProject)"/ "$PROJECT_DIR"/Resources/PythonFiles
 """),
				name: "Sync Project"
			),
			.init(
				script: .script("""
 python3.11 -m compileall -f -b "$PROJECT_DIR"/Resources/PythonFiles
 """),
				name: "Compile Python Files"
			),
			.init(
				script: .script("""
 find "$PROJECT_DIR"/Resources/PythonFiles/ -regex '.*\\.py' -delete
 """),
				name: "Delete .py leftovers"
			)
		]
	}
	
	func buildToolPlugins() async throws -> [ProjectSpec.BuildToolPlugin] {
		[.init(plugin: "SwiftonizerNew", package: "SwiftonizePlugin")]
	}
	
	func postCompileScripts() async throws -> [ProjectSpec.BuildScript] {
		[]
	}
	
	func postBuildScripts() async throws -> [ProjectSpec.BuildScript] {
		[
			.init(
				script: .script(SIGN_PYTHON_BINARY_MACOS),
				name: "Sign Python Binary"
			),
		
		]
	}
	
	func attributes() async throws -> [String : Any] {
		[:]
	}
	
	func build() async throws {
		
	}
	
	func target() async throws -> ProjectSpec.Target {
		fatalError()
	}
	
	
}
