# DocC4LLM

<h2>DocCArchive for LLM
</h2>

DocC4LLM is a fork of DocCArchive that extends the original library with export functionality for Large Language Models (LLMs). It allows you to convert DocC documentation archives into formats suitable for LLM consumption.

## Features

- **Export to Markdown**: Convert DocC archives to structured Markdown format
- **Export to Plain Text**: Convert DocC archives to plain text format with clear file separators
- **CLI Tool**: Command-line interface for easy batch processing
- **LLM-Optimized**: Output is flattened and structured for optimal LLM consumption
- **Robust Error Handling**: Gracefully handles unsupported content types
- **Recursive Processing**: Automatically processes all subfolders in DocC archives

## Installation

### Swift Package Manager

Add DocC4LLM to your project:

```swift
// swift-tools-version:5.0

import PackageDescription

let package = Package(
  name         : "myproject",
  dependencies : [
    .package(url: "https://github.com/P24L/DocC4LLM.git", from: "0.1.0")
  ],
  targets: [ .target(name: "myproject", dependencies: [ "DocCArchive" ]) ]
)
```

### Building from Source

```bash
git clone https://github.com/P24L/DocC4LLM.git
cd DocC4LLM
swift build
swift test
```

## Usage

### Command Line Interface

The `docc4llm` CLI tool provides easy access to export functionality:

```bash
# Export to plain text (default)
docc4llm export MyFramework.doccarchive

# Export to markdown
docc4llm export MyFramework.doccarchive --format markdown

# Export to file
docc4llm export MyFramework.doccarchive --output docs.txt

# Export to markdown file
docc4llm export MyFramework.doccarchive --format markdown --output docs.md
```

### Programmatic Usage

```swift
import DocCArchive

// Open a DocC archive
let archiveURL = URL(fileURLWithPath: "MyFramework.doccarchive")
let archive = try DocCArchive(contentsOf: archiveURL)

// Export individual documents
for document in archive.documents {
    let markdown = document.exportToMarkdown()
    let plainText = document.exportToPlainText()
    
    // Use the exported content...
    print(markdown)
}
```

## Output Format

### Plain Text Format

```
=== START FILE: data/documentation/atprotokit/appbskylexicon/feed/feedviewpostdefinition.json ===

Structure
AppBskyLexicon.Feed.FeedViewPostDefinition
A definition model for a feed's view.

Declaration

struct FeedViewPostDefinition

Parameters

feedContext: The feed generator's context. Optional

=== END FILE ===
```

### Markdown Format

```markdown
# doc://atprotokit-main.ATProtoKit/documentation/ATProtoKit/AppBskyLexicon/Feed/FeedViewPostDefinition

**Structure**

**AppBskyLexicon.Feed.FeedViewPostDefinition**

**Abstract:**
A definition model for a feed's view.

## Declaration

```swift
struct FeedViewPostDefinition
```

## Parameters

**feedContext:** The feed generator's context. Optional
```

## What Gets Exported

The export functions include:
- ✅ Document identifier URL
- ✅ Role heading (Structure, Function, etc.)
- ✅ Title and abstract
- ✅ Declarations (code syntax)
- ✅ Parameters and their descriptions
- ✅ Topics and content sections
- ✅ Tutorial steps

The export functions ignore:
- ❌ See Also sections
- ❌ Relationships
- ❌ Default Implementations
- ❌ Tables
- ❌ Lists
- ❌ Images
- ❌ Links
- ❌ Thematic breaks (horizontal rules)

## Error Handling

The tool gracefully handles:
- Unsupported content types (skips with warning)
- Missing or corrupted documents (continues processing)
- Various DocC archive formats and versions

## Original DocCArchive

This project is based on the original [DocCArchive](https://github.com/DoccZz/DocCArchive) by the Always Right Institute and ZeeZide. The original library provides comprehensive parsing of DocC archives and is used by DocC4LLM for the underlying document processing.

## License

Apache-2.0 License - see LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Online Mode and Export from URL

DocC4LLM now supports exporting documentation directly from online DocC archives (e.g., hosted on the web). Instead of a local path, you can provide a URL to the main index JSON file (e.g., `https://atprotokit.cjrriley.com/data/documentation/atprotokit.json`).

### HTTPFileProvider

- The HTTP(S) file provider implementation allows loading individual JSON files directly from the web.
- Recursion and reference traversal matches the behavior of the Vue.js SPA DocC: the exporter only follows references from the main index.
- Filtering: only paths starting with `data/documentation/` are processed (the prefix will be parameterizable in the future).
- Failed or external URLs are logged to `failed_urls.txt` and ignored.
- The online mode is currently a Proof-of-Concept (PoC) and does not handle caching or advanced network errors.

### How to Export from a URL

```bash
# Export from an online DocC archive (provide the URL to the main index)
docc4llm export https://atprotokit.cjrriley.com/data/documentation/atprotokit.json --format markdown --output docs.md
```

- The entry point is the main index JSON (e.g., `atprotokit.json`).
- Recursion will automatically follow all references and download the required files.
- The output is identical to exporting from a local archive.

### Online Mode Limitations
- Directory listing over HTTP is not supported (limitation of HTTPFileProvider).
- Missing or external files are logged and ignored.
- Recommended for publicly available DocC archives with a structure similar to a local .doccarchive.
