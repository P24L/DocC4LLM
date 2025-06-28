import Foundation

public protocol ArchiveFileProvider {
    /// Načte data ze souboru na dané relativní cestě (např. "documentation/atprotokit.json")
    func loadData(at relativePath: String) throws -> Data
    /// Ověří existenci souboru na dané relativní cestě
    func fileExists(at relativePath: String) -> Bool
    /// (Volitelné) Vrátí seznam souborů v adresáři na dané relativní cestě
    func listFiles(in relativeDirectory: String) throws -> [String]
} 