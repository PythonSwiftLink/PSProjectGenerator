//
//  File.swift
//  
//
//  Created by CodeBuilder on 08/10/2023.
//

import Foundation
import Zip
import PathKit
import Yams

func download(url: URL) async throws -> Data {
	let (data, _) = try await URLSession.shared.data(from: url)
	return data

}

func download(url: URL) async throws -> URL {
	let (downloadURL, _) = try await URLSession.shared.download(from: url)
	return downloadURL
}

func downloadAsset(url: URL) async throws -> URL {
	let (downloadURL, _) = try await URLSession.shared.download(from: url)
	let downloadPath = Path(downloadURL)
	let filename = url.lastPathComponent
    let new_url = downloadURL.deletingLastPathComponent().appending(path: filename)
    let new_url_path = new_url.asPath
    if new_url_path.exists { try new_url_path.delete() }
    try? downloadPath.move(new_url_path)
	return new_url
}

func downloadZipUnPacked(url: String, dst: Path) async throws -> Path {
	let download: Path = .init( try await download(url: .init(string: url)! ).path() )
	if dst.exists { try dst.delete() }
	try download.move(dst)
	let parent = dst.parent()
	try Zip.unzipFile(dst.url, destination: parent.url, overwrite: true, password: nil)
	try dst.delete()
	return parent
}

func downloadZipUnPacked(url: URL, dst: Path) async throws -> Path {
	let download: Path = .init( try await download(url: url ).path() )
	if dst.exists { try dst.delete() }
	try download.move(dst)
	let parent = dst.parent()
	try Zip.unzipFile(dst.url, destination: parent.url, overwrite: true, password: nil)
	try dst.delete()
	return parent
}

//public func GithubAPI(_ url: String) async throws {
//	let releases: Data = try await download(url: .init(string: url)! )
//	debugPrint(try JSONSerialization.jsonObject(with: releases))
//}

public protocol KSLReleaseProtocol {
	func downloadFiles() async throws -> [URL]?
}

public struct ReleaseAssetDownloader {
	
	class KivyCore: KSLReleaseProtocol {
		
		init() {
			
		}
		
		
		func downloadFiles() async throws -> [URL]? {
			var outputs = [URL]()
			let kivy_release = try await loadGithub(owner: "KivySwiftLink", repo: "KivyCore")
			if let release = kivy_release.releases.first  {
				let zips = release.assets.compactMap { r in
					switch r.name {
					case "site-packages.zip", "dist_files.zip":
						
						return URL(string: r.browser_download_url )
					default: return nil
					}
					
				}
				for zip in zips {
                    print(zip)
					let dest: URL = try await downloadAsset(url: zip)
					outputs.append(dest)
				}
				
				return outputs
			}
			
			return nil
		}
	}
	
	class KivyExtra: KSLReleaseProtocol {
		
		let recipes: [String]
		
		init(recipes: [String]) {
			self.recipes = recipes
		}
		
		
		func downloadFiles() async throws -> [URL]? {
			guard let kivy_release = try await loadGithub(owner: "PythonSwiftLink", repo: "KivyExtra").releases.first else {
				return nil
			}
			var output: [URL] = []
			for recipe in recipes.lazy.map(\.localizedLowercase).compactMap(\.kivy_extra_name) {
				if let dist_asset = kivy_release.assets.first(where: {$0.name == "\(recipe)_dist.zip"}) {
					let dest: URL = try await download(url: .init(string: dist_asset.browser_download_url)!)
					output.append(dest)
				}
				if let site_asset = kivy_release.assets.first(where: {$0.name == "\(recipe)_site.zip"}) {
					let dest: URL = try await download(url: .init(string: site_asset.browser_download_url)!)
					output.append(dest)
				}
				switch recipe {
				case .kiwisolver: break
				case .ffpyplayer: break
				case .ffmpeg: break
				case .pillow: break
				case .materialyoucolor: break
				case .matplotlib: break
				}
				
			}
			
			return output
		}
	}
	
}



public class SiteFilesDownload {
	enum SiteFolders: String {
		case kivy = "site-packages"
		case numpy = "numpy-site"
	}
	let target: SiteFolders
	let working_dir: Path
	let temp_dir: Path
	
	
	init(target: SiteFolders, working_dir: Path) throws {
		self.target = target
		self.working_dir = working_dir
		self.temp_dir = try .processUniqueTemporary()
	}
	func downloadDistLink() async throws -> URL? {
		switch target {
		case .kivy:
			let kivy_release = try await loadGithub(owner: "PythonSwiftLink", repo: "KivyCore")
			if let release = kivy_release.releases.first, let dist = release.assets.first(where: {$0.name == "kivy_dist.zip"}) {
				return .init(string: dist.browser_download_url)
			}
		case .numpy:
			let kivy_release = try await loadGithub(owner: "PythonSwiftLink", repo: "KivyNumpy")
			if let release = kivy_release.releases.first, let dist = release.assets.first(where: {$0.name == "numpy_dist.zip"}) {
				return .init(string: dist.browser_download_url)
			}
			
		}
		return nil
	}
	
	
	
}

extension String {
	var kivy_extra_name: recipeKeys? { .init(rawValue: self) }
}

extension Array where Element == String {
	
}

public class DistFilesDownload {
	enum DistTargets: String {
		case kivy = "kivy_dist"
		case numpy = "numpy_dist"
		case python = "python_dist"
	}
	
	
	
	let target: DistTargets
	let working_dir: Path
	let temp_dir: Path
	
	let ios_folder_name = "iphoneos"
	let sim_folder_name = "iphonesimulator"
	var ios_folder: Path {
		temp_dir + "dist_lib" + ios_folder_name
	}
	var sim_folder: Path {
		temp_dir + "dist_lib" + sim_folder_name
	}
	
	
	
	init(target: DistTargets, working_dir: Path) async throws {
		self.target = target
		self.working_dir = working_dir
		self.temp_dir = try .processUniqueTemporary()// + target.rawValue
		
		//try await downloadTargetAndExtract()
		
	}
	
	func downloadTargetAndExtract() async throws {
		guard let url = try await downloadDistLink() else { return }
		var download: Path = .init( try await download(url: url ).path() )
		let new_loc = temp_dir + "\(target.rawValue).zip"
		try download.move(new_loc)
		download = new_loc
//		
		let dst = temp_dir + target.rawValue
		try dst.mkpath()
		try Zip.unzipFile(download.url, destination: temp_dir.url, overwrite: true, password: nil)
		try download.delete()
		for file in ios_folder.filter(\.isLibA) {
			try file.move( working_dir + "dist_lib" + ios_folder_name + file.lastComponent )
		}
		for file in sim_folder.filter(\.isLibA) {
			try file.move( working_dir + "dist_lib" + sim_folder_name + file.lastComponent )
		}
		try dst.delete()
	}
	
	
	func downloadDistLink() async throws -> URL? {
		switch target {
		case .kivy:
			let kivy_release = try await loadGithub(owner: "PythonSwiftLink", repo: "KivyCore")
			if let release = kivy_release.releases.first, let dist = release.assets.first(where: {$0.name == "kivy_dist.zip"}) {
				return .init(string: dist.browser_download_url)
			}
		case .numpy:
			let kivy_release = try await loadGithub(owner: "PythonSwiftLink", repo: "KivyNumpy")
			if let release = kivy_release.releases.first, let dist = release.assets.first(where: {$0.name == "numpy_dist.zip"}) {
				return .init(string: dist.browser_download_url)
			}
		case .python:
			let kivy_release = try await loadGithub(owner: "PythonSwiftLink", repo: "KivyPythonCore")
			if let release = kivy_release.releases.first, let dist = release.assets.first(where: {$0.name == "python_dist.zip"}) {
				return .init(string: dist.browser_download_url)
			}
		}
		return nil
	}
}



public final class AssetsDownloader: Decodable {
	
	let owner: String
	let repo: String
	let version: String
	let assets: [Asset]
	
	var workingFolder: Path?
	var temp: Path
	
	enum CodingKeys: CodingKey {
		case owner
		case repo
		case version
		case assets
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.owner = try container.decode(String.self, forKey: .owner)
		self.repo = try container.decode(String.self, forKey: .repo)
		self.version = try container.decode(String.self, forKey: .version)
		self.assets = try container.decode([AssetsDownloader.Asset].self, forKey: .assets)
		self.temp = try .uniqueTemporary()
	}
	
	deinit {
		
		try? self.temp.delete()
	}
}


extension AssetsDownloader {
	public struct Asset: Decodable {
		
		enum AssetType: String, Decodable {
			case dist_folder
			case site_package
			case python_stdlib
		}
		
		let asset: String
		let type: AssetType
		let extract_name: String
	}
}

extension AssetsDownloader {
	public typealias AssetCompletion = ((_ key: String,_ download: Path) async throws ->() )

	public func downloadAssets(completion: @escaping AssetCompletion ) async throws {
		for asset in self.assets {
			// https://github.com/PythonSwiftLink/KivyNumpy/releases/download/310.1.0/numpy_dist.zip
			// https://github.com/\(owner)/\(repo)/releases/latest/download/\(asset.asset)
			if let url: URL = .init(string: "https://github.com/\(owner)/\(repo)/releases/latest/download/\(asset.asset)") {
				print("downloading <\(url)>:")
				var download: Path = .init( try await download(url: url ).path() )
				let new_loc = temp + asset.asset
				try download.move(new_loc)
				download = new_loc
				//
				try Zip.unzipFile(download.url, destination: temp.url, overwrite: true, password: nil)
				//temp.forEach({print($0)})
				
				let extract_folder = temp + asset.extract_name
				try await completion(asset.asset, extract_folder)
				try? extract_folder.delete()
//				let dst = temp + target.rawValue
//				try dst.mkpath()
//				try Zip.unzipFile(download.url, destination: temp.url, overwrite: true, password: nil)
//				try download.delete()
			}
		}
	}
}
