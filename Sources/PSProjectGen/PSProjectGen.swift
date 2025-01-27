import Foundation
import XcodeGenKit
import ProjectSpec
import XcodeGenCore
import PathKit
import XcodeProj


public protocol PSProjTargetProtocol {
	var name: String { get }
	var pythonProject: Path { get }
	
	func projSettings() async throws -> Settings
	func configFiles() async throws -> [String:String]
	func sources() async throws -> [TargetSource]
	func dependencies() async throws -> [Dependency]
	func info() async throws -> Plist
	func preBuildScripts() async throws -> [BuildScript]
	func buildToolPlugins() async throws -> [BuildToolPlugin]
	func postCompileScripts() async throws -> [BuildScript]
	func postBuildScripts() async throws -> [BuildScript]
	func attributes() async throws -> [String : Any]
	func build() async throws
	func target() async throws -> Target
}

public protocol PSProjectProtocol {
	var name: String { get }
	
	var py_src: Path { get }
	
	//var targets: [PSProjTargetProtocol] { get set }
	func targets() async throws -> [Target]
	
	func configs() async throws -> [Config]
	func schemes() async throws -> [Scheme]
	func projSettings() async throws -> Settings
	func settingsGroup() async throws -> [String: Settings]
	func packages() async throws -> [String:SwiftPackage]
	func specOptions() async throws -> SpecOptions
	func fileGroups() async throws -> [String]
	func configFiles() async throws -> [String:String]
	func attributes() async throws -> [String : Any]
	func projectReferences() async throws -> [ProjectReference]
	func projectBasePath() async throws -> Path
	func createStructure() async throws
	func project() async throws ->  Project
	func generate() async throws
}

public class PSProjectGen {
	
	var name: String
	
	var py_src: String
	
	var targets: [Target]
	
	public init(name: String, py_src: String) async throws {
		self.name = name
		self.py_src = py_src
		
		targets = []
	}
	
	
	var configs: [Config] {
		[.init(name: "Debug", type: .debug),.init(name: "Release", type: .release)]
	}
	//func targets() async throws -> [Target] {  [ try await KivyProject(name: name, py_src: py_src).target() ] }
	var schemes: [Scheme] {
		[]
	}
	
	var projSettings: Settings {
		
		
		return .empty
	}
	var settingsGroup: [String: Settings] {
		[:]
	}
	var packages: [String:SwiftPackage] {
		
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
	
	var specOptions: SpecOptions {
		
		
		return .init(bundleIdPrefix: "org.kivy")
	}
	var fileGroups: [String] {
		["Resources"]
	}
	var configFiles: [String:String] {
		[:]
	}
	var attributes: [String : Any] {
		[:]
	}
	
	var projectReferences: [ProjectReference] {
		[]
	}
	
	func projectBasePath() async throws -> Path {
		let base: Path = .current + "\(name).xcodeproj"
		if !base.exists {
			try! base.mkpath()
		}
		return base
		
	}
	
	
	
	func project() async throws ->  Project {
		//try await projectBasePath()
		return Project(
			basePath: .current,
			name: name,
			configs: configs,
			targets: targets,
			aggregateTargets: [],
			settings: projSettings,
			settingGroups: settingsGroup,
			schemes: schemes,
			breakpoints: [],
			packages: packages,
			options: specOptions,
			fileGroups: fileGroups,
			configFiles: configFiles,
			attributes: attributes,
			projectReferences: []
		)
	}
	func generateWorkspace() throws -> XCWorkspace {
		let selfReference = XCWorkspaceDataFileRef(location: .current(""))
		let dataElement = XCWorkspaceDataElement.file(selfReference)
		let workspaceData = XCWorkspaceData(children: [dataElement])
		return XCWorkspace(data: workspaceData)
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
