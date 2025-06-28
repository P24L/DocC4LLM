import Foundation

public class HTTPFileProvider: ArchiveFileProvider {
    let baseURL: URL
    let session: URLSession
    
    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    public func loadData(at relativePath: String) throws -> Data {
        guard let url = URL(string: relativePath, relativeTo: baseURL) else {
            throw URLError(.badURL)
        }
        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<Data, Error> = .failure(URLError(.unknown))
        let task = session.dataTask(with: url) { data, response, error in
            if let data = data {
                result = .success(data)
            } else {
                result = .failure(error ?? URLError(.unknown))
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        switch result {
        case .success(let data):
            return data
        case .failure(let error):
            throw error
        }
    }
    
    public func fileExists(at relativePath: String) -> Bool {
        guard let url = URL(string: relativePath, relativeTo: baseURL) else {
            return false
        }
        var exists = false
        let semaphore = DispatchSemaphore(value: 0)
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        let task = session.dataTask(with: request) { _, response, _ in
            if let httpResponse = response as? HTTPURLResponse {
                exists = (200...299).contains(httpResponse.statusCode)
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        return exists
    }
    
    public func listFiles(in relativeDirectory: String) throws -> [String] {
        // Pro PoC není implementováno (není běžně dostupné přes HTTP)
        throw NSError(domain: "HTTPFileProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: "Listing files is not supported over HTTP"])
    }
} 