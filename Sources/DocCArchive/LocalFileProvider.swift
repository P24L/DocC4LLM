import Foundation

public class LocalFileProvider: ArchiveFileProvider {
    let rootURL: URL
    let fileManager: FileManager
    
    public init(rootURL: URL, fileManager: FileManager = .default) {
        self.rootURL = rootURL
        self.fileManager = fileManager
    }
    
    public func loadData(at relativePath: String) throws -> Data {
        let fileURL = rootURL.appendingPathComponent(relativePath)
        return try Data(contentsOf: fileURL)
    }
    
    public func fileExists(at relativePath: String) -> Bool {
        let fileURL = rootURL.appendingPathComponent(relativePath)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    public func listFiles(in relativeDirectory: String) throws -> [String] {
        let dirURL: URL
        if relativeDirectory.isEmpty {
            dirURL = rootURL
        } else {
            dirURL = rootURL.appendingPathComponent(relativeDirectory)
        }
        let files = try fileManager.contentsOfDirectory(atPath: dirURL.path)
        print("[DEBUG][LocalFileProvider] listFiles in: \(dirURL.path) => \(files)")
        return files
    }
} 