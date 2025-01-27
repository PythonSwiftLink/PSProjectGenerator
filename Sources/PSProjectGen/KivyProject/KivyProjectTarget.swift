import Foundation
import AppKit
import PathKit
import XcodeGenKit
import ProjectSpec
import Yams


public enum recipeKeys: String {
	case kiwisolver
	case ffmpeg
	case ffpyplayer
	case matplotlib
	case materialyoucolor
	case pillow
	
}

public class KivyProjectTarget: PSProjTargetProtocol {
	
	public var name: String
	public var pythonProject: Path
	
	var dist_lib: Path
	
	public var projectSpec: Path?
	//	var projectSpec: SpecData?
	
	let workingDir: Path
	let resourcesPath: Path
	let pythonLibPath: Path
	let app_path: Path
    let experimental: Bool
	
	weak var project: KivyProject?
	
	
	
    public init(name: String, py_src: Path, dist_lib: Path, projectSpec: Path?, workingDir: Path, app_path: Path, experimental: Bool) async throws {
		self.name = name
		self.workingDir = workingDir
		self.app_path = app_path
		let resources = workingDir + "Resources"
		self.resourcesPath = resources
		self.pythonLibPath = resources + "lib"
		self.pythonProject = py_src
		self.dist_lib = dist_lib
		self.projectSpec = projectSpec
        self.experimental = experimental
	}
	public func build() async throws {
		
	}
	
	public func projSettings() async throws -> ProjectSpec.Settings {
		var configDict: [String: Any] = [
			"LIBRARY_SEARCH_PATHS": [
				"$(inherited)",
            ] + ( experimental ? [] : [dist_lib]),
			"SWIFT_VERSION": "5.0",
			"OTHER_LDFLAGS": "-all_load",
			"ENABLE_BITCODE": false
		]
		if let projectSpec = projectSpec {
			try loadBuildConfigKeys(from: projectSpec, keys: &configDict)
		}
		
		var configSettings: Settings {
			.init(dictionary: configDict)
		}
		
		return .init(configSettings: [
			"Debug": configSettings,
			"Release": configSettings
		])
	}
	
	public func configFiles() async throws -> [String : String] {
		[:]
	}
	
	public func sources() async throws -> [ProjectSpec.TargetSource] {
		let current = workingDir
		
		var sourcesPath: Path {
			
			return (current + "Sources")
		}
		
		var pips: [ProjectSpec.TargetSource] = [
			TargetSource(path: (sourcesPath).string, type: .group),
			.init(path: "Resources/YourApp", group: "Resources", type: .file, buildPhase: .resources, createIntermediateGroups: true),
			//.init(path: pythonLibPath.string, group: "Resources", type: .file, buildPhase: .resources, createIntermediateGroups: true),
			.init(path: "Resources/site-packages", name: "site-packages", type: .file, buildPhase: .resources ,createIntermediateGroups: true),
			.init(path: "Resources/Launch Screen.storyboard"),
			.init(path: "Resources/Images.xcassets"),
			.init(path: "Resources/icon.png"),
		]
		
		if let projectSpec = projectSpec {
			try loadExtraPipFolders(from: projectSpec, pips: &pips)
		}
		
		return pips
	}
	
	public func dependencies() async throws -> [ProjectSpec.Dependency] {
		var output: [ProjectSpec.Dependency] = [
			//			.init(type: .package(product: "PySwiftObject"), reference: "KivySwiftLink"),
			//			.init(type: .package(product: "PythonSwiftCore"), reference: "KivySwiftLink"),
			
			.init(type: .package(products: ["KivyLauncher"]), reference: "KivySwiftLink"),
			.init(type: .package(products: ["PySwiftObject"]), reference: "PythonSwiftLink"),
			.init(type: .package(products: ["PySwiftCore"]), reference: "PythonSwiftLink"),
			.init(type: .package(products: ["KivyCore"]), reference: "KivyCore"),
			.init(type: .package(products: ["KivyLauncher"]), reference: "KivyLauncher"),
			
			
		]
		if let packageSpec = projectSpec {
			try loadPackageDependencies(from: packageSpec, output: &output)
		}
		
		if let recipes = project?.projectSpecData?.toolchain_recipes {
			for recipe in recipes {
				output.append(.init(type: .package(products: [recipe]), reference: "KivyExtra"))
			}
		}
		
		return output
	}
	
	public func info() async throws -> ProjectSpec.Plist {
		var mainkeys: [String:Any] = [
			"UILaunchStoryboardName": "Launch Screen",
			"UIRequiresFullScreen": true
		]
		if
			let psp_bundle = Bundle(path: (app_path + "PythonSwiftProject_PSProjectGen.bundle").string ),
			let _project_plist_keys = psp_bundle.path(forResource: "downloads", ofType: "yml")
		{
			try loadBasePlistKeys(from: .init(filePath: _project_plist_keys), keys: &mainkeys)
		}
//		if let projectPkeys = Bundle.module.url(forResource: "project_plist_keys", withExtension: "yml") {
//			try loadBasePlistKeys(from: projectPkeys, keys: &mainkeys)
//		}
		if let packageSpec = projectSpec {
			var extraKeys = [String:Any]()
			
			try loadInfoPlistInfo(from: packageSpec, plist: &extraKeys)
			
			mainkeys.merge(extraKeys)
			return .init(path: "Info.plist", attributes: mainkeys)
		}
		
		return .init(path: "Info.plist", attributes: mainkeys)
	}
	
	public func preBuildScripts() async throws -> [ProjectSpec.BuildScript] {
		[
			.init(
				script: .script("""
	rsync -av --delete "\(pythonProject)"/ "$PROJECT_DIR"/Resources/YourApp
	"""),
				name: "Sync Project"
			),
			.init(
				script: .script("""
	python3.11 -m compileall -f -b "$PROJECT_DIR"/Resources/YourApp
	"""),
				name: "Compile Python Files"
			),
			.init(
				script: .script("""
	find "$PROJECT_DIR"/Resources/YourApp/ -regex '.*\\.py' -delete
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
		[
//			.init(
//				script: .script(PURGE_PYTHON_BINARY),
//				name: "Purge Python Binary Modules for Non-Target Platforms"
//			),
//			.init(
//				script: .script(SIGN_PYTHON_BINARY),
//				name: "Sign Python Binary Modules"
//			)
		]
	}
	
	public func attributes() async throws -> [String : Any] {
		[:]
	}
	
	public func target() async throws -> ProjectSpec.Target {
		let output = Target(
			name: name,
			type: .application,
			platform: .iOS,
			productName: name,
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
