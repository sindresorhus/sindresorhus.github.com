import Foundation

/**
A random number generator that gives the same numbers for the same seed (SplitMix64).
*/
struct SeededRandomNumberGenerator: RandomNumberGenerator {
	private var state: UInt64

	init(seed: UInt64) {
		self.state = seed
	}

	/**
	A generator that gives the same numbers for the same key during a day (UTC), and other numbers the next day.
	*/
	static func daily(_ key: String, on date: Date) -> Self {
		Self(seed: key.stableHash ^ UInt64(date.timeIntervalSince1970 / (24 * 60 * 60)))
	}

	mutating func next() -> UInt64 {
		state &+= 0x9E37_79B9_7F4A_7C15
		var value = state
		value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
		value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
		return value ^ (value >> 31)
	}
}

extension String {
	/**
	A hash that is the same in every process (FNV-1a), unlike `hashValue`.
	*/
	var stableHash: UInt64 {
		utf8.reduce(0xCBF2_9CE4_8422_2325) { ($0 ^ UInt64($1)) &* 0x100_0000_01B3 }
	}

	/**
	Shortens the text to fit a search result snippet (160 characters), cutting at a word boundary.
	*/
	var shortenedForSnippet: String {
		let maximumLength = 160

		guard count > maximumLength else {
			return self
		}

		let shortened = prefix(maximumLength - 1)
		let wordBoundary = shortened.lastIndex(of: " ") ?? shortened.endIndex
		return shortened[..<wordBoundary].replacing(/[,.:;]$/, with: "") + "…"
	}
}

extension Int {
	/**
	A rounded count, like `1.5M+` or `12K+`.
	*/
	var abbreviatedCount: String {
		if self >= 1_000_000 {
			return "\((Double(self) / 1_000_000).formatted(.number.precision(.fractionLength(0...1)).locale(Locale(identifier: "en_US_POSIX"))))M+"
		}

		if self >= 1000 {
			return "\(self / 1000)K+"
		}

		return String(self)
	}
}

extension Array {
	/**
	`nil` for an empty array, like for leaving an empty list out of JSON.
	*/
	var nilIfEmpty: Self? {
		isEmpty ? nil : self
	}
}

extension CharacterSet {
	/**
	The characters `encodeURIComponent` leaves unescaped.
	*/
	static let urlQueryValueAllowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.!~*'()")
}

extension Data {
	typealias Size = (width: Int, height: Int)

	var pngSize: Size? {
		guard
			count >= 24,
			starts(with: [137, 80, 78, 71, 13, 10, 26, 10])
		else {
			return nil
		}

		return (Int(bigEndianUInt32(at: 16)), Int(bigEndianUInt32(at: 20)))
	}

	/**
	Reads the size from the first start-of-frame marker.
	*/
	var jpegSize: Size? {
		guard starts(with: [0xFF, 0xD8]) else {
			return nil
		}

		let startOfFrameMarkers: Set<UInt8> = [0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF]
		var offset = startIndex + 2

		while offset + 9 < endIndex {
			guard self[offset] == 0xFF else {
				offset += 1
				continue
			}

			let marker = self[offset + 1]
			offset += 2

			if marker == 0xD8 || marker == 0xD9 {
				continue
			}

			let length = Int(bigEndianUInt16(at: offset))
			guard length >= 2, offset + length <= endIndex else {
				return nil
			}

			if startOfFrameMarkers.contains(marker), length >= 7 {
				return (Int(bigEndianUInt16(at: offset + 5)), Int(bigEndianUInt16(at: offset + 3)))
			}

			offset += length
		}

		return nil
	}

	/**
	Reads the size from the track header (`tkhd`) box of the first video track. Ignores rotation metadata.
	*/
	var mp4Size: Size? {
		func boxes(in range: Range<Int>, type: String) -> [Range<Int>] {
			var result = [Range<Int>]()
			var offset = range.lowerBound

			while offset + 8 <= range.upperBound {
				var size = Int(bigEndianUInt32(at: offset))
				var headerSize = 8

				if size == 1, offset + 16 <= range.upperBound {
					size = Int(bigEndianUInt64(at: offset + 8))
					headerSize = 16
				} else if size == 0 {
					size = range.upperBound - offset
				}

				guard size >= headerSize, offset + size <= range.upperBound else {
					break
				}

				if String(decoding: self[(offset + 4)..<(offset + 8)], as: UTF8.self) == type {
					result.append((offset + headerSize)..<(offset + size))
				}

				offset += size
			}

			return result
		}

		for movie in boxes(in: startIndex..<endIndex, type: "moov") {
			for track in boxes(in: movie, type: "trak") {
				for header in boxes(in: track, type: "tkhd") {
					// The size is 16.16 fixed-point and comes after fields that are larger in version 1.
					let sizeOffset = header.lowerBound + (self[header.lowerBound] == 1 ? 88 : 76)

					guard sizeOffset + 8 <= endIndex else {
						continue
					}

					let width = Int((Double(bigEndianUInt32(at: sizeOffset)) / 65_536).rounded())
					let height = Int((Double(bigEndianUInt32(at: sizeOffset + 4)) / 65_536).rounded())

					// Audio tracks have zero size.
					if width > 0, height > 0 {
						return (width, height)
					}
				}
			}
		}

		return nil
	}

	fileprivate func bigEndianUInt16(at offset: Int) -> UInt16 {
		self[offset..<(offset + 2)].reduce(0) { $0 << 8 | UInt16($1) }
	}

	fileprivate func bigEndianUInt32(at offset: Int) -> UInt32 {
		self[offset..<(offset + 4)].reduce(0) { $0 << 8 | UInt32($1) }
	}

	fileprivate func bigEndianUInt64(at offset: Int) -> UInt64 {
		self[offset..<(offset + 8)].reduce(0) { $0 << 8 | UInt64($1) }
	}
}

extension URL {
	/**
	The pixel size of a PNG, JPEG, or MP4 file, or `nil` when it cannot be read.

	Only the needed part of the file is read: the header of an image, and the movie box of a video, so large videos are fast.
	*/
	var mediaSize: Data.Size? {
		guard let handle = try? FileHandle(forReadingFrom: self) else {
			return nil
		}

		defer {
			try? handle.close()
		}

		switch pathExtension.lowercased() {
		case "png":
			return (try? handle.read(upToCount: 24))?.pngSize
		case "jpg", "jpeg":
			// The size is in the first frame header, after the metadata, which is almost always smaller than this.
			return (try? handle.read(upToCount: 262_144))?.jpegSize
		case "mp4":
			return (try? handle.movieBox())?.mp4Size
		default:
			return nil
		}
	}
}

extension FileHandle {
	/**
	The `moov` box of an MP4 file, with its header. It has the track sizes, and is small, unlike the media data.
	*/
	fileprivate func movieBox() throws -> Data? {
		var offset: UInt64 = 0

		while true {
			try seek(toOffset: offset)

			guard
				let header = try read(upToCount: 16),
				header.count >= 8
			else {
				return nil
			}

			var size = UInt64(header.bigEndianUInt32(at: 0))

			if size == 1, header.count >= 16 {
				size = header.bigEndianUInt64(at: 8)
			}

			// A size of 0 means the box goes to the end of the file, so there is no box after it.
			guard size >= 8 else {
				return nil
			}

			if String(decoding: header[4..<8], as: UTF8.self) == "moov" {
				try seek(toOffset: offset)
				return try read(upToCount: Int(size))
			}

			offset += size
		}
	}
}
