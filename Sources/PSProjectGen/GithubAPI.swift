//
//  File 2.swift
//  
//
//  Created by CodeBuilder on 18/10/2023.
//

import Foundation

private var githubCache: [String: GithubAPI] = [:]
public func loadGithub(owner: String, repo: String) async throws -> GithubAPI {
	let key = "\(owner)/\(repo)"
	if let git = githubCache[key] {
		return git
	}
	let git = try await GithubAPI(owner: owner, repo: repo)
	githubCache[key] = git
	return git
}

public struct GithubAPI {
	
	let owner: String
	let repo: String
	
	var releases: [Release] = []
	
	
	var releasesURL: URL {
		.init(string: "https://api.github.com/repos/\(owner)/\(repo)/releases")!
	}
	
	
	public init(owner: String, repo: String) async throws {
		self.owner = owner
		self.repo = repo
		let releasesData: Data = try await download(url: releasesURL)
		releases = try JSONDecoder().decode([Release].self, from: releasesData)
	}
	
	public mutating func handleReleases() async throws {
		let releasesData: Data = try await download(url: releasesURL)
		releases = try JSONDecoder().decode([Release].self, from: releasesData)
//		let releases = try JSONSerialization.jsonObject(with: releasesData) as! [[String: Any]]
		if let release = releases.first {
			
//			debugPrint(release.keys)
//			debugPrint(release["tag_name"]!)
//			let assets = release["assets"] as! [[String: Any]]
//			debugPrint(assets.compactMap({$0["name"]}))
//			debugPrint(assets.compactMap({$0["browser_download_url"]}))
//			if let first_asset = assets.first {
//				debugPrint(first_asset.keys)
//			}
//			for asset in release.assets {
//				print(asset.name, asset.browser_download_url)
//			}
		}
		
	}
	
}


extension GithubAPI {
	
	struct Release: Decodable {
		let name: String
		let tag_name: String
		let url: String
		let assets: [ReleaseAsset]
		
	}
	
	struct ReleaseAsset: Decodable {
		let name: String
		let browser_download_url: String
		let size: Int
		let content_type: String
	}
	
	
}

extension GithubAPI.ReleaseAsset {
	var url: URL? { .init(string: browser_download_url) }
	}
