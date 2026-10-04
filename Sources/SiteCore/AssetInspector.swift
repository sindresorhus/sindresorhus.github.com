import Foundation

public enum AssetInspector {
	public static func mediaAssets(in directory: URL, publicPrefix: String) throws -> [MediaAsset] {
		guard FileManager.default.fileExists(atPath: directory.path) else {
			return []
		}

		let files = try FileManager.default.contentsOfDirectory(
			at: directory,
			includingPropertiesForKeys: nil
		)
		let videos = files
			.filter { $0.lastPathComponent.hasPrefix("video") && $0.pathExtension.lowercased() == "mp4" }
			.sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
		let screenshots = files
			.filter {
				$0.lastPathComponent.hasPrefix("screenshot")
					&& ["png", "jpg", "jpeg"].contains($0.pathExtension.lowercased())
			}
			.sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }

		return try (videos + screenshots).map { file in
			guard let size = size(of: file) else {
				throw AssetInspectorError.unreadableDimensions(file.path)
			}
			return MediaAsset(
				path: "\(publicPrefix)/\(file.lastPathComponent)",
				width: size.width,
				height: size.height
			)
		}
	}

	private static func size(of file: URL) -> (width: Int, height: Int)? {
		guard let data = try? Data(contentsOf: file) else { return nil }
		switch file.pathExtension.lowercased() {
		case "png": return pngSize(data)
		case "jpg", "jpeg": return jpegSize(data)
		case "mp4": return mp4Size(data)
		default: return nil
		}
	}

	private static func pngSize(_ data: Data) -> (Int, Int)? {
		guard data.count >= 24 else { return nil }
		let signature = [UInt8](data.prefix(8))
		guard signature == [137, 80, 78, 71, 13, 10, 26, 10] else { return nil }
		let width = Int(data.readUInt32BE(at: 16))
		let height = Int(data.readUInt32BE(at: 20))
		return (width, height)
	}

	private static func jpegSize(_ data: Data) -> (Int, Int)? {
		guard data.count > 4, data[0] == 0xFF, data[1] == 0xD8 else { return nil }
		var offset = 2
		while offset + 9 < data.count {
			guard data[offset] == 0xFF else { offset += 1; continue }
			let marker = data[offset + 1]
			offset += 2
			if marker == 0xD8 || marker == 0xD9 { continue }
			guard offset + 2 <= data.count else { return nil }
			let length = Int(data.readUInt16BE(at: offset))
			guard length >= 2, offset + length <= data.count else { return nil }
			if [0xC0,0xC1,0xC2,0xC3,0xC5,0xC6,0xC7,0xC9,0xCA,0xCB,0xCD,0xCE,0xCF].contains(marker), length >= 7 {
				let height = Int(data.readUInt16BE(at: offset + 3))
				let width = Int(data.readUInt16BE(at: offset + 5))
				return (width, height)
			}
			offset += length
		}
		return nil
	}

	private static func mp4Size(_ data: Data) -> (Int, Int)? {
		func boxes(start: Int, end: Int, type: String) -> [(Int, Int)] {
			var result: [(Int, Int)] = []
			var offset = start
			while offset + 8 <= end {
				var size = Int(data.readUInt32BE(at: offset))
				var headerSize = 8
				if size == 1, offset + 16 <= end {
					size = Int(data.readUInt64BE(at: offset + 8))
					headerSize = 16
				} else if size == 0 {
					size = end - offset
				}
				guard size >= headerSize, offset + size <= end else { break }
				if String(data: data[(offset + 4)..<(offset + 8)], encoding: .isoLatin1) == type {
					result.append((offset + headerSize, offset + size))
				}
				offset += size
			}
			return result
		}

		for movie in boxes(start: 0, end: data.count, type: "moov") {
			for track in boxes(start: movie.0, end: movie.1, type: "trak") {
				for header in boxes(start: track.0, end: track.1, type: "tkhd") {
					guard header.0 < data.count else { continue }
					let sizeOffset = header.0 + (data[header.0] == 1 ? 88 : 76)
					guard sizeOffset + 8 <= data.count else { continue }
					let width = Int(round(Double(data.readUInt32BE(at: sizeOffset)) / 65_536))
					let height = Int(round(Double(data.readUInt32BE(at: sizeOffset + 4)) / 65_536))
					if width > 0, height > 0 { return (width, height) }
				}
			}
		}
		return nil
	}
}

private extension Data {
	func readUInt16BE(at offset: Int) -> UInt16 {
		(UInt16(self[offset]) << 8) | UInt16(self[offset + 1])
	}

	func readUInt32BE(at offset: Int) -> UInt32 {
		(UInt32(self[offset]) << 24) | (UInt32(self[offset + 1]) << 16) | (UInt32(self[offset + 2]) << 8) | UInt32(self[offset + 3])
	}

	func readUInt64BE(at offset: Int) -> UInt64 {
		var value: UInt64 = 0
		for byte in self[offset..<(offset + 8)] { value = (value << 8) | UInt64(byte) }
		return value
	}
}


public enum AssetInspectorError: Error, CustomStringConvertible {
	case unreadableDimensions(String)

	public var description: String {
		switch self {
		case .unreadableDimensions(let path):
			"Could not read media dimensions from \(path)"
		}
	}
}
