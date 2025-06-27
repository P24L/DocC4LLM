// swift-tools-version:5.0

import PackageDescription

let package = Package(
  name     : "DocC4LLM",
  products : [ 
    .library(name: "DocCArchive", targets: [ "DocCArchive" ]),
    .executable(name: "docc4llm", targets: [ "docc4llm" ])
  ],
  targets  : [
    .target    (name: "DocCArchive"),
    .target(name: "docc4llm", dependencies: [ "DocCArchive" ]),
    .testTarget(name: "DocCArchiveTests", dependencies: [ "DocCArchive" ])
  ]
)
