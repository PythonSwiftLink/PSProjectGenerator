import Foundation
import AppKit
import PathKit
import XcodeGenKit
import ProjectSpec
import Yams



class SwiftUI_Project: PSProjectProtocol {
	var name: String
	
	var py_src: String
	
	let workingDir: Path
	
	var requirements: String?
	
	var _targets: [PSProjTargetProtocol] = []
	
	var dev_mode = true
	
	init(name: String, py_src: String, workingDir: Path, requirements: String? = nil, _targets: [PSProjTargetProtocol], dev_mode: Bool = true) {
		self.name = name
		self.py_src = py_src
		self.workingDir = workingDir
		self.requirements = requirements
		self._targets = _targets
		self.dev_mode = dev_mode
	}
	
	func targets() async throws -> [ProjectSpec.Target] {
		var output: [Target] = []
		for target in _targets {
			output.append( try await target.target() )
		}
		return output
	}
	
	func configs() async throws -> [ProjectSpec.Config] {
		[.init(name: "debug", type: .debug),.init(name: "release", type: .release)]
	}
	
	func schemes() async throws -> [ProjectSpec.Scheme] {
		[]
	}
	
	func projSettings() async throws -> ProjectSpec.Settings {
		.empty
	}
	
	func settingsGroup() async throws -> [String : ProjectSpec.Settings] {
		[:]
	}
	
	func packages() async throws -> [String : ProjectSpec.SwiftPackage] {
		var releases = try await GithubAPI(owner: "PythonSwiftLink", repo: "KivyCore")
		try await releases.handleReleases()
		guard let latest = releases.releases.first else { throw CocoaError(.coderReadCorrupt) }
		var output: [String : ProjectSpec.SwiftPackage] = [:]
		if dev_mode {
			output["SwiftonizePlugin"] = .local(path: "/Volumes/CodeSSD/PSL-development/SwiftonizePlugin-development", group: nil)
			output["SwiftonizePlugin"] = .local(path: "/Volumes/CodeSSD/PSL-development/SwiftonizePlugin-development", group: nil)
		}
		output["PythonCore"] = .remote(
			url: "https://github.com/pythonswiftlink/PythonCore",
			versionRequirement: .upToNextMajorVersion("311.0.2")
		)
		output["PythonSwiftLink"] = .remote(
			url: "https://github.com/pythonswiftlink/PythonCore",
			versionRequirement: .upToNextMajorVersion(latest.tag_name)
		)

//			"KivyLauncher": .remote(
//				url: "https://github.com/pythonswiftlink/KivyLauncher",
//				versionRequirement: .upToNextMajorVersion("311.0.0")
//			)
//			
		
//		if let packageSpec = projectSpec {
//			try loadSwiftPackages(from: packageSpec, output: &output)
//		}
		return output
	}
	
	func specOptions() async throws -> ProjectSpec.SpecOptions {
		return .init(bundleIdPrefix: "org.pythonswiftlink")
	}
	
	func fileGroups() async throws -> [String] {
		[]
	}
	
	func configFiles() async throws -> [String : String] {
		[:]
	}
	
	func attributes() async throws -> [String : Any] {
		[:]
	}
	
	func projectReferences() async throws -> [ProjectSpec.ProjectReference] {
		[]
	}
	
	func projectBasePath() async throws -> PathKit.Path {
		workingDir
	}
	
	func createStructure() async throws {
		let current = workingDir
		
		try? (current + "Resources/YourApp").mkpath()
		try? (current + "wrapper_sources").mkdir()
		//try? distIphoneos.mkpath()
		//try? distSimulator.mkpath()
		//try? (current + "dist_lib/iphoneos").mkpath()
		//try? (current + "dist_lib/iphonesimulator").mkpath()
		//try? (current + "Resources").mkdir()
		let downloadsPath = Path(Bundle.module.path(forResource: "downloads", ofType: "yml")!)
		let downloader = try YAMLDecoder().decode([String:AssetsDownloader].self, from: downloadsPath.read())
		
	}
	
	func project() async throws -> ProjectSpec.Project {
		return Project(
			basePath: workingDir,
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
	
	func generate() async throws {
		let project = try await project()
		let fw = FileWriter(project: project)
		let projectGenerator = ProjectGenerator(project: project)
		
		guard let userName = ProcessInfo.processInfo.environment["LOGNAME"] else {
			throw KivyCreateError.missingUsername
		}
		
		let xcodeProject = try projectGenerator.generateXcodeProject(in: workingDir, userName: userName)
		
		try fw.writePlists()
		//
		
		try fw.writeXcodeProject(xcodeProject)
		try await NSWorkspace.shared.open([project.defaultProjectPath.url], withApplicationAt: .applicationDirectory.appendingPathComponent("Xcode.app"), configuration: .init())
	}
	
	
}
