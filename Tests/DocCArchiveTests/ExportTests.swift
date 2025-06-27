//
//  ExportTests.swift
//  DocCArchiveTests
//
//  Created for DocC4LLM project.
//  Copyright © 2024 P24L. All rights reserved.
//

import XCTest
@testable import DocCArchive

final class ExportTests: XCTestCase {
    
    func testExportToMarkdown() throws {
        // Use existing test fixture
        let data = try loadFixture("SimpleTutorial.json")
        let document = try JSONDecoder().decode(DocCArchive.DocCSchema_0_1.Document.self, from: data)
        
        let markdown = document.exportToMarkdown()
        
        // Verify basic structure
        XCTAssertTrue(markdown.contains("# "))
        XCTAssertTrue(markdown.contains("**"))
        XCTAssertTrue(markdown.contains("## "))
    }
    
    func testExportToPlainText() throws {
        // Use existing test fixture
        let data = try loadFixture("SimpleTutorial.json")
        let document = try JSONDecoder().decode(DocCArchive.DocCSchema_0_1.Document.self, from: data)
        
        let plainText = document.exportToPlainText()
        
        // Verify basic structure
        XCTAssertTrue(plainText.contains("=== START FILE:"))
        XCTAssertTrue(plainText.contains("=== END FILE ==="))
    }
    
    func testExportIgnoresUnsupportedContent() throws {
        // Use existing test fixture with tables
        let data = try loadFixture("TableIssue6.json")
        let document = try JSONDecoder().decode(DocCArchive.DocCSchema_0_1.Document.self, from: data)
        
        let markdown = document.exportToMarkdown()
        let plainText = document.exportToPlainText()
        
        // Should not contain table content
        XCTAssertFalse(markdown.contains("Column 1 Title"))
        XCTAssertFalse(plainText.contains("Column 1 Title"))
        
        // Should still contain supported content
        XCTAssertTrue(markdown.contains("TableDocC"))
        XCTAssertTrue(plainText.contains("TableDocC"))
    }
    
    // MARK: - Helper Methods
    
    private func loadFixture(_ name: String) throws -> Data {
        let fixtureURL = Fixtures.baseURL.appendingPathComponent(name)
        return try Data(contentsOf: fixtureURL)
    }
} 