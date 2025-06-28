#!/usr/bin/env swift

import Foundation
import DocCArchive

// MARK: - Helper Functions

func collectJSONs(in folder: DocCArchive.DocumentFolder, basePath: String = "") -> [String] {
    var paths: [String] = []
    let currentPath = basePath.isEmpty ? folder.path.joined(separator: "/") : basePath
    // Přidej všechny JSON soubory v aktuálním adresáři
    for file in folder.pagePaths() {
        let fullPath = currentPath.isEmpty ? file : currentPath + "/" + file
        paths.append(fullPath)
    }
    // Rekurzivně projdi všechny podadresáře
    for subfolderName in folder.subfolderPaths() {
        let subfolder = DocCArchive.DocumentFolder(path: folder.path + [subfolderName], archive: folder.archive)
        let subfolderBase = currentPath.isEmpty ? subfolderName : currentPath + "/" + subfolderName
        paths.append(contentsOf: collectJSONs(in: subfolder, basePath: subfolderBase))
    }
    return paths
}

// MARK: - Online Recursive Export

func collectOnlineJSONsRecursively(archive: DocCArchive, entryPath: String, visited: inout Set<String>, maxDepth: Int = 2, prefix: String) -> [String] {
    var result: [String] = []
    var queue: [(String, Int, [String: Any]?)] = [(entryPath, 0, nil)]
    while !queue.isEmpty {
        let (current, depth, parentDict) = queue.removeFirst()
        if visited.contains(current) { continue }
        visited.insert(current)
        result.append(current)
        if depth >= maxDepth { continue }
        do {
            let data = try archive.fileProvider.loadData(at: current)
            if let str = String(data: data, encoding: .utf8), str.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("<") {
                // Pravděpodobně HTML/404, přeskoč
                continue
            }
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            guard let dict = json as? [String: Any] else { continue }
            // topicSections
            if let topicSections = dict["topicSections"] as? [[String: Any]] {
                for section in topicSections {
                    if let identifiers = section["identifiers"] as? [String] {
                        for id in identifiers {
                            if let relPath = pathForIdentifier(id, in: dict) {
                                queue.append((relPath, depth + 1, dict))
                            }
                        }
                    }
                }
            }
            // items (např. v "links" nebo "items" v contentu)
            if let items = dict["items"] as? [String] {
                for id in items {
                    if let relPath = pathForIdentifier(id, in: dict) {
                        queue.append((relPath, depth + 1, dict))
                    }
                }
            }
            // references (pole nebo slovník)
            if let references = dict["references"] as? [String: Any] {
                for (id, _) in references {
                    if let relPath = pathForIdentifier(id, in: dict) {
                        queue.append((relPath, depth + 1, dict))
                    }
                }
            } else if let referencesArr = dict["references"] as? [[String: Any]] {
                for ref in referencesArr {
                    if let id = ref["identifier"] as? String, let relPath = pathForIdentifier(id, in: dict) {
                        queue.append((relPath, depth + 1, dict))
                    }
                }
            }
        } catch {
            // Chyby řešíme až při dekódování dokumentu
        }
    }
    return result
}

// MARK: - Command Line Interface

func printUsage() {
    print("""
    DocC4LLM - Export DocC documentation for LLM consumption
    
    Usage: docc4llm <command> [options]
    
    Commands:
        export <path> [options]    Export .doccarchive to text format
    
    Export Options:
        --format <format>          Output format: markdown, plain (default: plain)
        --output <path>            Output file path (default: stdout)
        --relative-paths           Use relative paths in output
    
    Examples:
        docc4llm export MyFramework.doccarchive
        docc4llm export MyFramework.doccarchive --format markdown --output docs.md
        docc4llm export MyFramework.doccarchive --relative-paths
    """)
}

func exportArchive(path: String, format: String, outputPath: String?, useRelativePaths: Bool) {
    let archiveURL = URL(fileURLWithPath: path)
    
    guard FileManager.default.fileExists(atPath: path) else {
        print("Error: Archive not found at \(path)")
        exit(1)
    }
    
    do {
        let archive = try DocCArchive(contentsOf: archiveURL)
        var output = ""
        
        // Get documents from documentation folder
        if let docsFolder = archive.documentationFolder() {
            let jsonPaths = collectJSONs(in: docsFolder)
            for relativePath in jsonPaths {
                do {
                    let document = try archive.document(at: relativePath)
                    // Add file separator with relative path
                    output += "=== START FILE: \(relativePath) ===\n\n"
                    switch format.lowercased() {
                    case "markdown":
                        output += document.exportToMarkdown()
                    case "plaintext":
                        output += document.exportToPlainText()
                    default:
                        output += document.exportToMarkdown()
                    }
                    output += "\n\n=== END FILE ===\n\n"
                } catch {
                    print("[WARNING] Failed to decode document at \(relativePath): \(error)")
                }
            }
        } else {
            print("[ERROR] Documentation folder not found in archive.")
        }
        
        if let outputPath = outputPath {
            try output.write(toFile: outputPath, atomically: true, encoding: .utf8)
            print("Exported to: \(outputPath)")
        } else {
            print(output)
        }
        
    } catch {
        print("Error: \(error)")
        exit(1)
    }
}

// MARK: - Main

let arguments = Array(CommandLine.arguments.dropFirst())

guard !arguments.isEmpty else {
    printUsage()
    exit(1)
}

let command = arguments[0]

switch command {
case "export":
    guard arguments.count >= 2 else {
        print("Error: Missing archive path")
        printUsage()
        exit(1)
    }
    
    let archivePath = arguments[1]
    var format = "plain"
    var outputPath: String?
    var useRelativePaths = false
    
    // Parse options
    var i = 2
    while i < arguments.count {
        switch arguments[i] {
        case "--format":
            guard i + 1 < arguments.count else {
                print("Error: Missing format value")
                exit(1)
            }
            format = arguments[i + 1]
            i += 2
            
        case "--output":
            guard i + 1 < arguments.count else {
                print("Error: Missing output path")
                exit(1)
            }
            outputPath = arguments[i + 1]
            i += 2
            
        case "--relative-paths":
            useRelativePaths = true
            i += 1
            
        default:
            print("Error: Unknown option '\(arguments[i])'")
            printUsage()
            exit(1)
        }
    }
    
    if archivePath.hasPrefix("http://") || archivePath.hasPrefix("https://") {
        // ONLINE VARIANTA
        guard let url = URL(string: archivePath) else {
            print("Error: Invalid URL: \(archivePath)")
            exit(1)
        }
        // baseURL = vše před "/data/documentation/atprotokit.json"
        let baseURLString: String
        if let range = archivePath.range(of: "/data/documentation/atprotokit.json") {
            baseURLString = String(archivePath[..<range.lowerBound])
        } else {
            print("Error: For PoC, URL must end with /data/documentation/atprotokit.json")
            exit(1)
        }
        guard let baseURL = URL(string: baseURLString) else {
            print("Error: Invalid base URL: \(baseURLString)")
            exit(1)
        }
        let provider = HTTPFileProvider(baseURL: baseURL)
        let archive = DocCArchive(fileProvider: provider)
        let entryPath = "data/documentation/atprotokit.json"
        var visited = Set<String>()
        let allPaths = collectOnlineJSONsRecursively(archive: archive, entryPath: entryPath, visited: &visited, maxDepth: 2, prefix: "data/documentation/")
        print("[INFO] Nalezené JSON soubory:")
        for path in allPaths {
            print("  \(path)")
        }
        var output = ""
        var failedURLs: [String] = []
        for relativePath in allPaths {
            do {
                let data = try archive.fileProvider.loadData(at: relativePath)
                if let str = String(data: data, encoding: .utf8), str.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("<") {
                    if let fullURL = URL(string: relativePath, relativeTo: baseURL) {
                        print("[SKIP] Pravděpodobně HTML/404: \(relativePath) => \(fullURL.absoluteString)")
                        failedURLs.append(fullURL.absoluteString)
                    } else {
                        print("[SKIP] Pravděpodobně HTML/404: \(relativePath)")
                        failedURLs.append(relativePath)
                    }
                    continue
                }
                let document = try JSONDecoder().decode(DocCArchive.Document.self, from: data)
                output += "=== START FILE: \(relativePath) ===\n\n"
                switch format.lowercased() {
                case "markdown":
                    output += document.exportToMarkdown()
                case "plaintext":
                    output += document.exportToPlainText()
                default:
                    output += document.exportToMarkdown()
                }
                output += "\n\n=== END FILE ===\n\n"
            } catch {
                if let fullURL = URL(string: relativePath, relativeTo: baseURL) {
                    print("[ERROR] Nelze dekódovat: \(relativePath) => \(fullURL.absoluteString)")
                    failedURLs.append(fullURL.absoluteString)
                } else {
                    print("[ERROR] Nelze dekódovat: \(relativePath)")
                    failedURLs.append(relativePath)
                }
                print("[ERROR] Chyba: \(error)")
            }
        }
        if let outputPath = outputPath {
            try? output.write(toFile: outputPath, atomically: true, encoding: .utf8)
            print("Exported to: \(outputPath)")
        } else {
            print(output)
        }
        // Zapiš neúspěšné URL do souboru
        let failedFile = "failed_urls.txt"
        try? failedURLs.joined(separator: "\n").write(toFile: failedFile, atomically: true, encoding: .utf8)
        print("[INFO] Seznam neúspěšných URL zapsán do \(failedFile)")
    } else {
        // LOKÁLNÍ VARIANTA
        exportArchive(path: archivePath, format: format, outputPath: outputPath, useRelativePaths: useRelativePaths)
    }
    
case "help", "--help", "-h":
    printUsage()
    
default:
    print("Error: Unknown command '\(command)'")
    printUsage()
    exit(1)
} 