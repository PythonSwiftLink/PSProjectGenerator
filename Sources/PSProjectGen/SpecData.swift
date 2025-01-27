
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
}

fileprivate let newSpecFile = """
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

""".replacingOccurrences(of: "\t", with: "    ")

public func newSpecData() -> String {
	newSpecFile
}



import Yams
extension PathKit.Path {
	public func specData() throws -> SpecData {
		try YAMLDecoder().decode(SpecData.self, from: read())
	}
}
