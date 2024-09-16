
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
	let pips: [String]?
	let pip_requirements: [PipRequirement]?
	let packages: [String: SwiftPackageData]?
	let toolchain_recipes: [String]?
	
	enum CodingKeys: CodingKey {
		case development_team
		case info_plist
		case pip_folders
		case pips
		case pip_requirements
		case packages
		case toolchain_recipes
	}
	
	public init(from decoder: Decoder) throws {
		let container: KeyedDecodingContainer<SpecData.CodingKeys> = try decoder.container(keyedBy: SpecData.CodingKeys.self)
		
		self.development_team = try container.decodeIfPresent(DevelopmentTeamData.self, forKey: SpecData.CodingKeys.development_team)
		self.info_plist = try! container.decodeIfPresent([String : String].self, forKey: SpecData.CodingKeys.info_plist)
		self.pip_folders = try! container.decodeIfPresent([PipFolder].self, forKey: SpecData.CodingKeys.pip_folders)
		self.pips = try! container.decodeIfPresent([String].self, forKey: SpecData.CodingKeys.pips)
		self.pip_requirements = try! container.decodeIfPresent([PipRequirement].self, forKey: SpecData.CodingKeys.pip_requirements)
		self.packages = try! container.decodeIfPresent([String : SwiftPackageData].self, forKey: SpecData.CodingKeys.packages)
		self.toolchain_recipes = try! container.decodeIfPresent([String].self, forKey: SpecData.CodingKeys.toolchain_recipes)
		print(self)
	}
}

import Yams
extension PathKit.Path {
	public func specData() throws -> SpecData {
		try YAMLDecoder().decode(SpecData.self, from: read())
	}
}
