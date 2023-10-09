import Foundation
import XcodeGenKit
import ProjectSpec
import XcodeGenCore
import PathKit
import XcodeProj


public class PSProjectGen {
	public init(name: String) {
		self.name = name
	}
	
	
	var name: String
	
	var configs: [Config] {
		[.init(name: "debug", type: .debug),.init(name: "release", type: .release)]
	}
	func targets() async throws -> [Target] {  [ try await KivyProject(name: name).target() ] }
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
			targets: try await targets(),
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
