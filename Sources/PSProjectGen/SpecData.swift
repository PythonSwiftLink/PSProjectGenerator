
import Foundation
import PathKit

public struct DevelopmentTeamData: Decodable {
	let id: String?
}

public struct PipFolder: Decodable {
	let path: String
}

public struct PipRequirement: Decodable {
	let path: String
}

public struct SwiftPackageData: Decodable {
	
	struct PythonImports: Decodable {
		let products: [String]
		let modules: [String]
	}
	
	let url: String?
	let path: String?
	let branch: String?
	let from: String?
	let python_imports: PythonImports?
}

public struct SpecData: Decodable {
	let development_team: DevelopmentTeamData?
	let info_plist: [String:String]?
	let pip_folders: [PipFolder]?
	let pip_requirements: [PipRequirement]?
	let packages: [String: SwiftPackageData]?
	
}

import Yams
extension PathKit.Path {
	public func specData() throws -> SpecData {
		try YAMLDecoder().decode(SpecData.self, from: read())
	}
}
