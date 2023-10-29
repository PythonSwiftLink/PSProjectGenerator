
import Foundation
import PathKit



public extension PathKit.Path {
	var isLibA: Bool {
		self.extension == "a"
	}
}


extension PathKit.Path: Decodable {
	public init(from decoder: Decoder) throws {
		self = .init(try decoder.singleValueContainer().decode(String.self))
	}
	public init(_ url: URL) {
		self = .init(url.path())
	}
	
	var iphoneos: Self { self + "iphoneos"}
	var iphonesimulator: Self { self + "iphonesimulator"}
}
