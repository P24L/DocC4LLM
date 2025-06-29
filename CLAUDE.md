# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

Build the project:
```bash
swift build
```

Run tests:
```bash
swift test
```

Run the CLI tool:
```bash
swift run docc4llm export <path> [options]
```

Build release version:
```bash
swift build -c release
```

## Architecture Overview

DocC4LLM is a Swift package that extends DocCArchive with LLM export functionality. The codebase is structured into three main components:

### Core Library (Sources/DocCArchive/)
- **DocCArchive.swift**: Main entry point, handles both local and HTTP archive access via pluggable `ArchiveFileProvider` protocol
- **Export.swift**: Document export functionality with `exportToMarkdown()` and `exportToPlainText()` methods
- **File Providers**: 
  - `LocalFileProvider`: Local .doccarchive file access
  - `HTTPFileProvider`: Online DocC archive access via HTTP
- **Schema_0_1/**: Complete DocC schema definition for version 0.1, including Document, Content, Section, and Reference types

### CLI Tool (Sources/docc4llm/)
- **main.swift**: Command-line interface with export command, supports both local archives and online URLs

### Key Design Patterns
- Uses pluggable `ArchiveFileProvider` protocol for different data sources (local files vs HTTP)
- Document export uses recursive content processing with format-specific renderers
- Online mode performs breadth-first traversal following document references from main index
- Error handling: gracefully skips unsupported content types and logs failed URLs

### Export Capabilities
- Exports: document metadata, declarations, parameters, content sections, tutorial steps
- Ignores: See Also sections, tables, lists, images, links, thematic breaks
- Formats: Markdown (with code blocks) and plain text (with file separators)

## Online Mode
The tool supports exporting from online DocC archives by providing URL to main index JSON. It follows references recursively and filters paths with `data/documentation/` prefix. Failed URLs are logged to `failed_urls.txt`.

## Project Status
- **Core functionality**: Complete - exports local .doccarchive files to markdown/plain text
- **Online mode**: Implemented as PoC - supports HTTP-based DocC archives
- **Current state**: Stable, ready for production use on both local and online archives
- **See**: [online_checklist.md](online_checklist.md) for detailed online mode implementation status
- **See**: [.instruction.md](.instruction.md) for comprehensive project overview and future roadmap