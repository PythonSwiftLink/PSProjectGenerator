

import Foundation
import XcodeGenKit
import ProjectSpec
import PathKit
import Yams

func loadSwiftPackages(from packageSpec: PathKit.Path, output: inout [String: SwiftPackage]) throws {
	let spec = (try Yams.load(yaml: .init(contentsOf: packageSpec.url)) as! ProjectSpecDictionary)
	if let packages = spec["packages"] as? [String: [String:Any]] {
		try packages.forEach { (ref: String, package: [String : Any]) in
			output[ref] = try SwiftPackage(jsonDictionary: package)
		}
	}
	
}

func loadSwiftPackages(from spec: SpecData, output: inout [String: SwiftPackage]) throws {
	if let packages = spec.packages {
//		
//		try packages.forEach { (ref: String, package: [String : Any]) in
//			output[ref] = try SwiftPackage(jsonDictionary: package)
//		}
	}
}

func loadPackageDependencies(from projectSpec: PathKit.Path, output: inout [ProjectSpec.Dependency] ) throws {
	guard let spec = try Yams.load(yaml: projectSpec.read()) as? [String: Any] else { return }
	if let packages = spec["packages"] as? [String: [String:Any]] {
		packages.forEach { (ref: String, package: [String : Any]) in
			if let products = package["products"] as? [String] {
				for product in products {
					output.append(
						.init(type: .package(products: [product]), reference: ref)
					)
				}
			}
		}
	}
}

func loadPythonPackageInfo(from projectSpec: PathKit.Path, imports: inout [String], pyswiftProducts: inout [String]) throws -> Bool {
	
	guard let spec = try Yams.load(yaml: projectSpec.read()) as? [String: Any] else { return false }

	if let packages = spec["packages"] as? [String:[String:Any]] {
        //print(packages)
		packages.forEach { (ref: String, package: [String : Any]) in
			//print(ref)
			if let python_imports = package["python_imports"] as? [String:Any] {
				if let modules = python_imports["modules"] as? [String] {
					imports.append(contentsOf: modules)
				}
				if let products = python_imports["products"] as? [String] {
					pyswiftProducts.append(contentsOf: products)
				}
			}
		}
		return true
	}
	return false
}


func loadInfoPlistInfo(from projectSpec: PathKit.Path, plist: inout [String:Any]) throws {
	guard let spec = try Yams.load(yaml: projectSpec.read()) as? [String: Any] else { return }
	if let infoplist = spec["info_plist"] as? [String:Any] {
		plist.merge(infoplist)
	}
}


func loadExtraPipFolders(from projectSpec: PathKit.Path, pips: inout [ProjectSpec.TargetSource]) throws {
	guard let spec = try Yams.load(yaml: projectSpec.read()) as? [String: Any] else { return }
	if let folders = spec["pip_folders"] as? [[String:String]] {
		folders.forEach { folder in
			if let path = folder["path"] {
				pips.append(
					.init(path: path, group: "Resources", type: .file, buildPhase: .resources)
				)
			}
		}
	}
}

func loadBasePlistKeys(from url: URL,  keys: inout [String:Any]) throws {
	
	guard let spec = try Yams.load(yaml: .init(contentsOf: url)) as? [String: Any] else { return }
	keys.merge(spec)
}

func loadBuildConfigKeys(from projectSpec: PathKit.Path, keys: inout [String:Any]) throws {
	// DEVELOPMENT_TEAM
	guard let spec = try Yams.load(yaml: projectSpec.read()) as? [String: Any] else { return }
	if let team = spec["development_team"] as? [String:String] {
		if let id = team["id"] {
			keys["DEVELOPMENT_TEAM"] = id
		}
	}
}

func loadRequirementsFiles(from projectSpec: PathKit.Path, site_path: Path) throws {
	let spec = try Yams.load(yaml: projectSpec.read()) as! [String: Any]
	if let requirements = spec["pip_requirements"] as? [[String:String]] {
		requirements.forEach { req in
			if let path = req["path"] {
				pipInstall(.init(path), site_path: site_path)
			}
		}
		
	}
}
