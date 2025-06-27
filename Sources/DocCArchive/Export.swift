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