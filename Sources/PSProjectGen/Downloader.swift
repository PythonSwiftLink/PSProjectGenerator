//
//  File.swift
//  
//
//  Created by CodeBuilder on 08/10/2023.
//

import Foundation
import Zip
import PathKit

func download(url: URL) async throws -> Data {
	let (data, _) = try await URLSession.shared.data(from: url)
	return data

}

func download(url: URL) async throws -> URL {
	let (downloadURL, response) = try await URLSession.shared.download(from: url)
	return downloadURL
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
