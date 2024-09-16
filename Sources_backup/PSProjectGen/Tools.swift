

import Foundation
import PathKit

@discardableResult
func pythonScript(_ script: String) -> String {
	let task = Process()
	let pipe = Pipe()
	let inputFile: Path = try! .uniqueTemporary() + "tmp.py"
	try! inputFile.write(script, encoding: .utf8)
	task.standardOutput = pipe
	task.standardError = pipe
	task.arguments = [inputFile.string]
	//task.launchPath = "/usr/local/bin/python3.10"
	task.executableURL = .init(filePath: "/usr/local/bin/python3")
	task.standardInput = nil
	task.launch()
	
	let data = pipe.fileHandleForReading.readDataToEndOfFile()
	let output = String(data: data, encoding: .utf8)!
	try! inputFile.delete()
	return output
}

@discardableResult
func gitClone(_ repo: String) -> String {
	let task = Process()
	let pipe = Pipe()
	task.standardOutput = pipe
	task.standardError = pipe
	task.arguments = ["clone", repo]
	task.executableURL = .init(filePath: "/usr/bin/git")
	task.standardInput = nil
	task.launch()
	
	let data = pipe.fileHandleForReading.readDataToEndOfFile()
	let output = String(data: data, encoding: .utf8)!
	print(output)
	return output
}

@discardableResult
func pipInstall(_ requirements: Path, site_path: Path) -> String {
	let task = Process()
	let pipe = Pipe()
	task.standardOutput = pipe
	task.standardError = pipe
	task.arguments = ["install","-r", requirements.string, "-t", site_path.string]
	task.executableURL = .init(filePath: "/usr/local/bin/pip3.10")
	task.standardInput = nil
	task.launch()
	
	let data = pipe.fileHandleForReading.readDataToEndOfFile()
	let output = String(data: data, encoding: .utf8)!
	print(output)
	return output
}
