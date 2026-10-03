import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public actor BuildDataClient {
	private var releaseCache: [String: [GitHubRelease]] = [:]
	private let token: String?

	public init(token: String? = ProcessInfo.processInfo.environment["GITHUB_TOKEN"]) {
		self.token = token
	}

	public func appStoreInfo(ids: [Int]) async -> [Int: AppStoreInfo] {
		guard !ids.isEmpty else { return [:] }
		guard let url = URL(string: "https://itunes.apple.com/lookup?id=\(ids.map(String.init).joined(separator: ","))") else { return [:] }
		do {
			let (data, response) = try await URLSession.shared.data(from: url)
			guard (response as? HTTPURLResponse)?.statusCode == 200 else { return [:] }
			let payload = try JSONDecoder().decode(AppStoreLookup.self, from: data)
			return Dictionary(uniqueKeysWithValues: payload.results.map { ($0.trackId, $0) })
		} catch {
			return [:]
		}
	}

	public func releases(repository: String) async throws -> [GitHubRelease] {
		if let cached = releaseCache[repository] { return cached }
		let releases: [GitHubRelease] = try await github(path: "repos/sindresorhus/\(repository)/releases?per_page=100")
		let filtered = releases.filter { !$0.draft && !$0.prerelease }
		releaseCache[repository] = filtered
		return filtered
	}

	public func recentRepositories() async throws -> [GitHubRepository] {
		let repos: [GitHubRepository] = try await github(path: "users/sindresorhus/repos?type=owner&sort=created&per_page=20")
		return repos.filter { !$0.archived && !$0.fork }
	}

	private func github<T: Decodable>(path: String) async throws -> T {
		guard let url = URL(string: "https://api.github.com/\(path)") else { throw URLError(.badURL) }
		var request = URLRequest(url: url)
		request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
		request.setValue("sindresorhus.com-static-generator", forHTTPHeaderField: "User-Agent")
		if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
		let (data, response) = try await URLSession.shared.data(for: request)
		guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
			throw URLError(.badServerResponse)
		}
		return try JSONDecoder().decode(T.self, from: data)
	}
}

private struct AppStoreLookup: Decodable {
	let results: [AppStoreInfo]
}
