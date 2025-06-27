#!/usr/bin/env swift

import Foundation
import DocCArchive

// MARK: - Helper Functions

func collectJSONs(in folder: DocCArchive.DocumentFolder) -> [URL] {
    var urls = folder.pageURLs()
    for subfolder in folder.subfolders() {
        urls += collectJSONs(in: subfolder)
    }
    return urls
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
            let jsonURLs = collectJSONs(in: docsFolder)
            
            for pageURL in jsonURLs {
                do {
                    let document = try archive.document(at: pageURL)
                    
                    // Add file separator with relative path
                    let relativePath = pageURL.path.replacingOccurrences(of: archiveURL.path + "/", with: "")
                    output += "=== START FILE: \(relativePath) ===\n\n"
                    
                    switch format.lowercased() {
                    case "markdown":
                        output += document.exportToMarkdown()
                    case "plain":
                        output += document.exportToPlainText()
                    default:
                        print("Error: Unsupported format '\(format)'. Use 'markdown' or 'plain'.")
                        exit(1)
                    }
                    
                    output += "\n=== END FILE ===\n\n"
                    
                } catch {
                    print("Warning: Could not decode document \(pageURL.lastPathComponent): \(error)")
                    continue // pokračovat s dalším dokumentem
                }
            }
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
    
    exportArchive(path: archivePath, format: format, outputPath: outputPath, useRelativePaths: useRelativePaths)
    
case "help", "--help", "-h":
    printUsage()
    
default:
    print("Error: Unknown command '\(command)'")
    printUsage()
    exit(1)
} 