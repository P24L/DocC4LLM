//
//  Export.swift
//  DocCArchive
//
//  Created for DocC4LLM project.
//  Copyright © 2024 P24L. All rights reserved.
//

import Foundation

public extension DocCArchive.DocCSchema_0_1.Document {
    
    /// Export document to Markdown format suitable for LLM consumption
    func exportToMarkdown() -> String {
        var output = ""
        
        // Document identifier and title
        output += "# \(identifier.url.absoluteString)\n\n"
        
        // Role heading and title
        if let roleHeading = metadata.roleHeading {
            output += "**\(roleHeading.rawValue)**\n\n"
        }
        
        if !metadata.title.isEmpty {
            output += "**\(metadata.title)**\n\n"
        }
        
        // Abstract
        if let abstract = abstract {
            output += "**Abstract:**\n"
            output += abstract.map { $0.description }.joined(separator: " ")
            output += "\n\n"
        }
        
        // Process primary content sections
        if let primaryContentSections = primaryContentSections {
            for section in primaryContentSections {
                output += processSection(section)
            }
        }
        
        // Process topic sections
        if let topicSections = topicSections {
            output += "## Topics\n\n"
            for section in topicSections {
                output += processTopicSection(section)
            }
        }
        
        return output
    }
    
    /// Export document to plain text format suitable for LLM consumption
    func exportToPlainText() -> String {
        var output = ""
        
        // Document identifier and title
        output += "=== START FILE: \(identifier.url.absoluteString) ===\n\n"
        
        // Role heading and title
        if let roleHeading = metadata.roleHeading {
            output += "\(roleHeading.rawValue)\n"
        }
        
        if !metadata.title.isEmpty {
            output += "\(metadata.title)\n"
        }
        
        // Abstract
        if let abstract = abstract {
            output += "Abstract: "
            output += abstract.map { $0.description }.joined(separator: " ")
            output += "\n\n"
        }
        
        // Process primary content sections
        if let primaryContentSections = primaryContentSections {
            for section in primaryContentSections {
                output += processSectionPlainText(section)
            }
        }
        
        // Process topic sections
        if let topicSections = topicSections {
            output += "Topics\n\n"
            for section in topicSections {
                output += processTopicSectionPlainText(section)
            }
        }
        
        output += "\n=== END FILE ===\n\n"
        return output
    }
    
    // MARK: - Private Helper Methods
    
    private func processTopicSection(_ section: DocCArchive.DocCSchema_0_1.Section) -> String {
        var output = ""
        
        if let title = section.title {
            output += "### \(title)\n\n"
        }
        
        for identifier in section.identifiers {
            if let ref = references[identifier.stringValue] {
                switch ref {
                case .topic(let topic):
                    // Declaration (fragments)
                    if let fragments = topic.fragments {
                        let signature = fragments.map { $0.stringValue }.joined()
                        output += "```swift\n\(signature)\n```\n\n"
                    }
                    // Description (abstract)
                    output += topic.abstract.map { $0.description }.joined(separator: " ") + "\n\n"
                default:
                    break
                }
            }
        }
        
        return output
    }
    
    private func processTopicSectionPlainText(_ section: DocCArchive.DocCSchema_0_1.Section) -> String {
        var output = ""
        
        if let title = section.title {
            output += "\(title)\n\n"
        }
        
        for identifier in section.identifiers {
            if let ref = references[identifier.stringValue] {
                switch ref {
                case .topic(let topic):
                    // Declaration (fragments)
                    if let fragments = topic.fragments {
                        let signature = fragments.map { $0.stringValue }.joined()
                        output += "\(signature)\n\n"
                    }
                    // Description (abstract)
                    output += topic.abstract.map { $0.description }.joined(separator: " ") + "\n\n"
                default:
                    break
                }
            }
        }
        
        return output
    }
    
    private func processSection(_ section: DocCArchive.DocCSchema_0_1.Section) -> String {
        var output = ""
        
        switch section.kind {
        case .declarations(let declarations):
            if !declarations.isEmpty {
                output += "## Declaration\n\n"
                for declaration in declarations {
                    let tokens = declaration.tokens.map { $0.stringValue }.joined(separator: "")
                    if !tokens.isEmpty {
                        output += "```swift\n\(tokens)\n```\n\n"
                    }
                }
            }
            
        case .parameters(let parameters):
            if !parameters.isEmpty {
                output += "## Parameters\n\n"
                for parameter in parameters {
                    let content = parameter.content.map { $0.description }.joined(separator: " ")
                    if !content.isEmpty {
                        output += "**\(parameter.name):** \(content)\n\n"
                    }
                }
            }
            
        case .content(let content):
            if !content.isEmpty {
                output += "## Content\n\n"
                for item in content {
                    let itemOutput = processContent(item)
                    if !itemOutput.isEmpty {
                        output += itemOutput
                    }
                }
            }
            
        case .tasks(let tasks):
            if !tasks.isEmpty {
                output += "## Tasks\n\n"
                for task in tasks {
                    output += "### \(task.title)\n\n"
                    for step in task.stepsSection {
                        let stepOutput = processContent(step)
                        if !stepOutput.isEmpty {
                            output += stepOutput
                        }
                    }
                }
            }
            
        default:
            // Ignore other section types as specified
            break
        }
        
        return output
    }
    
    private func processSectionPlainText(_ section: DocCArchive.DocCSchema_0_1.Section) -> String {
        var output = ""
        
        switch section.kind {
        case .declarations(let declarations):
            if !declarations.isEmpty {
                output += "Declaration\n\n"
                for declaration in declarations {
                    let tokens = declaration.tokens.map { $0.stringValue }.joined(separator: "")
                    if !tokens.isEmpty {
                        output += "\(tokens)\n\n"
                    }
                }
            }
            
        case .parameters(let parameters):
            if !parameters.isEmpty {
                output += "Parameters\n\n"
                for parameter in parameters {
                    let content = parameter.content.map { $0.description }.joined(separator: " ")
                    if !content.isEmpty {
                        output += "\(parameter.name): \(content)\n\n"
                    }
                }
            }
            
        case .content(let content):
            if !content.isEmpty {
                output += "Content\n\n"
                for item in content {
                    let itemOutput = processContentPlainText(item)
                    if !itemOutput.isEmpty {
                        output += itemOutput
                    }
                }
            }
            
        case .tasks(let tasks):
            if !tasks.isEmpty {
                output += "Tasks\n\n"
                for task in tasks {
                    output += "\(task.title)\n\n"
                    for step in task.stepsSection {
                        let stepOutput = processContentPlainText(step)
                        if !stepOutput.isEmpty {
                            output += stepOutput
                        }
                    }
                }
            }
            
        default:
            // Ignore other section types as specified
            break
        }
        
        return output
    }
    
    private func processContent(_ content: DocCArchive.DocCSchema_0_1.Content) -> String {
        switch content {
        case .heading(let text, _, let level):
            let prefix = String(repeating: "#", count: level + 2)
            return "\(prefix) \(text)\n\n"
            
        case .paragraph(let inlineContent):
            let text = inlineContent.map { $0.description }.joined(separator: " ")
            return text.isEmpty ? "" : text + "\n\n"
            
        case .codeListing(let codeListing):
            let syntax = codeListing.syntax ?? "swift"
            let code = codeListing.code.joined(separator: "\n")
            return code.isEmpty ? "" : "```\(syntax)\n\(code)\n```\n\n"
            
        case .step(let step):
            var output = ""
            if !step.content.isEmpty {
                for item in step.content {
                    output += processContent(item)
                }
            }
            return output
            
        case .links:
            // Ignore links content as specified
            return ""
            
        case .thematicBreak:
            // Ignore thematic breaks as specified
            return ""
            
        default:
            // Ignore other content types as specified
            return ""
        }
    }
    
    private func processContentPlainText(_ content: DocCArchive.DocCSchema_0_1.Content) -> String {
        switch content {
        case .heading(let text, _, _):
            return "\(text)\n\n"
            
        case .paragraph(let inlineContent):
            let text = inlineContent.map { $0.description }.joined(separator: " ")
            return text.isEmpty ? "" : text + "\n\n"
            
        case .codeListing(let codeListing):
            let syntax = codeListing.syntax ?? "swift"
            let code = codeListing.code.joined(separator: "\n")
            return code.isEmpty ? "" : "Code:\n\(syntax)\n\(code)\n\n"
            
        case .step(let step):
            var output = ""
            if !step.content.isEmpty {
                for item in step.content {
                    output += processContentPlainText(item)
                }
            }
            return output
            
        case .links:
            // Ignore links content as specified
            return ""
            
        case .thematicBreak:
            // Ignore thematic breaks as specified
            return ""
            
        default:
            // Ignore other content types as specified
            return ""
        }
    }
}

// MARK: - Online Recursive Export (moved from main.swift)

/// Najde všechny online JSON soubory rekurzivně, pouze s daným prefixem a pouze podle hlavního indexu (references).
public func collectOnlineJSONsRecursively(
    archive: DocCArchive,
    entryPath: String,
    visited: inout Set<String>,
    maxDepth: Int = 2,
    currentDepth: Int = 0,
    prefix: String = "data/documentation/"
) -> [String] {
    var result: [String] = []
    var queue: [(String, Int, [String: Any]?)] = [(entryPath, currentDepth, nil)]
    var mainReferences: [String: Any]? = nil
    // Načti hlavní index (entry JSON) a získej jeho references
    do {
        let data = try archive.fileProvider.loadData(at: entryPath)
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        if let dict = json as? [String: Any], let refs = dict["references"] as? [String: Any] {
            mainReferences = refs
        }
    } catch {
        // Pokud selže, pokračuj bez validace (fallback na původní chování)
    }
    while !queue.isEmpty {
        let (current, depth, parentDict) = queue.removeFirst()
        if visited.contains(current) { continue }
        visited.insert(current)
        // Filtrace podle prefixu
        guard current.hasPrefix(prefix) else { continue }
        result.append(current)
        if depth >= maxDepth { continue }
        do {
            let data = try archive.fileProvider.loadData(at: current)
            if let str = String(data: data, encoding: .utf8), str.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("<") {
                continue
            }
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            guard let dict = json as? [String: Any] else { continue }
            // topicSections
            if let topicSections = dict["topicSections"] as? [[String: Any]] {
                for section in topicSections {
                    if let identifiers = section["identifiers"] as? [String] {
                        for id in identifiers {
                            // Ověř, že ID je v hlavním references
                            if let mainRefs = mainReferences, mainRefs[id] != nil, let relPath = pathForIdentifier(id, in: dict) {
                                queue.append((relPath, depth + 1, dict))
                            }
                        }
                    }
                }
            }
            // items (např. v "links" nebo "items" v contentu)
            if let items = dict["items"] as? [String] {
                for id in items {
                    if let mainRefs = mainReferences, mainRefs[id] != nil, let relPath = pathForIdentifier(id, in: dict) {
                        queue.append((relPath, depth + 1, dict))
                    }
                }
            }
            // references (pole nebo slovník)
            if let references = dict["references"] as? [String: Any] {
                for (id, _) in references {
                    if let mainRefs = mainReferences, mainRefs[id] != nil, let relPath = pathForIdentifier(id, in: dict) {
                        queue.append((relPath, depth + 1, dict))
                    }
                }
            } else if let referencesArr = dict["references"] as? [[String: Any]] {
                for ref in referencesArr {
                    if let id = ref["identifier"] as? String, let mainRefs = mainReferences, mainRefs[id] != nil, let relPath = pathForIdentifier(id, in: dict) {
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

/// Najde relativní cestu k identifikátoru v JSON dictu.
public func pathForIdentifier(_ identifier: String, in dict: [String: Any]?) -> String? {
    if let dict = dict {
        if let references = dict["references"] as? [String: Any], let ref = references[identifier] as? [String: Any] {
            if let variants = ref["variants"] as? [[String: Any]] {
                for variant in variants {
                    if let paths = variant["paths"] as? [String], let first = paths.first {
                        return "data" + first + ".json"
                    }
                }
            }
            if let url = ref["url"] as? String {
                return "data" + url + ".json"
            }
        }
        if let referencesArr = dict["references"] as? [[String: Any]] {
            for ref in referencesArr {
                if let id = ref["identifier"] as? String, id == identifier {
                    if let variants = ref["variants"] as? [[String: Any]] {
                        for variant in variants {
                            if let paths = variant["paths"] as? [String], let first = paths.first {
                                return "data" + first + ".json"
                            }
                        }
                    }
                    if let url = ref["url"] as? String {
                        return "data" + url + ".json"
                    }
                }
            }
        }
        if let variants = dict["variants"] as? [[String: Any]] {
            for variant in variants {
                if let paths = variant["paths"] as? [String] {
                    for path in paths {
                        if let lastComponent = identifier.split(separator: "/").last, path.lowercased().contains(lastComponent.lowercased()) {
                            return "data" + path + ".json"
                        }
                    }
                }
            }
        }
    }
    guard identifier.hasPrefix("doc://") else { return nil }
    let path = identifier.replacingOccurrences(of: "doc://ATProtoKit/", with: "data/")
        .replacingOccurrences(of: "/", with: "/")
        .appending(".json")
        .lowercased()
    return path
} 