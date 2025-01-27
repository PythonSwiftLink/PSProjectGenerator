
import Foundation
import PathKit



public extension PathKit.Path {
	var isLibA: Bool {
		self.extension == "a"
	}
}

fileprivate func pathsToAdd() -> [String] {[
    "/usr/local/bin",
    "/opt/homebrew/bin"
]}

extension String {
    mutating func extendedPath() {
        self += ":\(pathsToAdd().joined(separator: ":"))"
    }
    mutating func strip() {
        self.removeLast(1)
    }
}

extension URL {
    var asPath: Path {
        .init(path())
    }
}

extension PathKit.Path {

	public init(_ url: URL) {
		self = .init(url.path())
	}
	
	var iphoneos: Self { self + "iphoneos"}
	var iphonesimulator: Self { self + "iphonesimulator"}
}

extension Bundle {
    func path(forResource: String, withExtension: String?) -> Path? {
        url(forResource: forResource, withExtension: withExtension)?.asPath
    }
}

extension Process {
    var executablePath: Path? {
        get {
            if let path = executableURL?.path() {
                return .init(path)
            }
            return nil
        }
        set {
            executableURL = newValue?.url
        }
    }
}

func which_python() throws -> Path {
    let proc = Process()
    //proc.executableURL = .init(filePath: "/bin/zsh")
    proc.executableURL = .init(filePath: "/usr/bin/which")
    proc.arguments = ["python3.11"]
    let pipe = Pipe()
    
    proc.standardOutput = pipe
    var env = ProcessInfo.processInfo.environment
    //env["PATH"]?.extendedPath()
    proc.environment = env
    
    try! proc.run()
    proc.waitUntilExit()
    
    guard
        let data = try? pipe.fileHandleForReading.readToEnd(),
        var path = String(data: data, encoding: .utf8)
    else { fatalError() }
    path.strip()
    return .init(path)
}

func which_pip3() throws -> Path {
    let proc = Process()
    //proc.executableURL = .init(filePath: "/bin/zsh")
    proc.executableURL = .init(filePath: "/usr/bin/which")
    proc.arguments = ["pip3.11"]
    let pipe = Pipe()
    
    proc.standardOutput = pipe
    var env = ProcessInfo.processInfo.environment
    env["PATH"]?.extendedPath()
    proc.environment = env
    
    try! proc.run()
    proc.waitUntilExit()
    
    guard
        let data = try? pipe.fileHandleForReading.readToEnd(),
        var path = String(data: data, encoding: .utf8)
    else { fatalError() }
    path.strip()
    return .init(path)
}

