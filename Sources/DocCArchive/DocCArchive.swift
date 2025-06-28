//
//  DocCArchive.swift
//  DocCArchive
//
//  Created by Helge Heß.
//  Copyright © 2021 ZeeZide GmbH. All rights reserved.
//

import Foundation

/**
 * Represents an on-disk DocC archive.
 *
 * ### Filesystem Structure:
 *
 * - data/
 *   - documentation/
 *     - slotcreator.json
 *     - slotcreator/
 *       - activity.json
 *       - activity/
 *         - `perform(with:).json` (yes, w/ :)
 *   - tutorials/
 * - css/
 *   - document-topic.HASH.css
 *   - documentation-topic~topic~tutorials-overview.HASH.css
 *   - index.HASH.css
 *   - topic.HASH.css
 *   - tutorial-overview.HASH.css
 *
 * ### Hashes
 *
 * Presumably the hashes are included for forcing cache updates, not sure
 * how they are calculated.
 * They are rather short `a4cce634` (4 bytes), i.e. not MD5 or SHA.
 */
public struct DocCArchive {
  // TBD: Maybe this should be a class, or at least a CoW, to avoid the copying
  //      for the subfolders.

  public typealias Document       = DocCSchema_0_1.Document
  public typealias InlineContent  = DocCSchema_0_1.InlineContent
  public typealias Fragment       = DocCSchema_0_1.Fragment
  public typealias Content        = DocCSchema_0_1.Content
  public typealias Section        = DocCSchema_0_1.Section
  public typealias Reference      = DocCSchema_0_1.Reference
  public typealias TopicReference = DocCSchema_0_1.TopicReference
  public typealias ImageReference = DocCSchema_0_1.ImageReference

  public let fileProvider: ArchiveFileProvider

  // Původní property zůstávají kvůli zpětné kompatibilitě, ale budou se používat jen v LocalFileProvider
  public let url              : URL
  public let dataURL          : URL
  public let documentationURL : URL?
  public let tutorialsURL     : URL?

  private var fm : FileManager { .default }

  /**
   * Note: This does synchronous file access.
   */
  public init(fileProvider: ArchiveFileProvider) {
    self.fileProvider = fileProvider
    // Pro LocalFileProvider lze získat url/dataURL, pro HTTPFileProvider budou nil
    if let local = fileProvider as? LocalFileProvider {
      self.url = local.rootURL
      self.dataURL = local.rootURL.appendingPathComponent("data")
      let docURL = self.dataURL.appendingPathComponent("documentation")
      let tutURL = self.dataURL.appendingPathComponent("tutorials")
      let fm = FileManager.default
      var isDir: ObjCBool = false
      var documentationURL: URL? = nil
      var tutorialsURL: URL? = nil
      if fm.fileExists(atPath: docURL.path, isDirectory: &isDir), isDir.boolValue {
        documentationURL = docURL
      }
      if fm.fileExists(atPath: tutURL.path, isDirectory: &isDir), isDir.boolValue {
        tutorialsURL = tutURL
      }
      self.documentationURL = documentationURL
      self.tutorialsURL = tutorialsURL
    } else {
      self.url = URL(string: "http://invalid.local")! // placeholder
      self.dataURL = URL(string: "http://invalid.local/data")!
      self.documentationURL = nil
      self.tutorialsURL = nil
    }
  }
  
  /// Původní inicializátor pro zpětnou kompatibilitu (lokální archiv)
  public init(contentsOf url: URL) throws {
    let provider = LocalFileProvider(rootURL: url)
    self.init(fileProvider: provider)
    // ... původní kontrola existence složek atd. lze přesunout do LocalFileProvider, nebo zde ponechat pro kompatibilitu
  }
  
  
  // MARK: - Lookup Static Resources
  
  public func stylesheetURLs() -> [ URL ] {
    if fileProvider is LocalFileProvider {
      return fm.contentsOfDirectory(at: url.appendingPathComponent("css"))
    } else {
      return []
    }
  }
  public func userImageURLs() -> [ URL ] {
    if fileProvider is LocalFileProvider {
      return fm.contentsOfDirectory(at: url.appendingPathComponent("images"))
    } else {
      return []
    }
  }
  public func systemImageURLs() -> [ URL ] {
    if fileProvider is LocalFileProvider {
      return fm.contentsOfDirectory(at: url.appendingPathComponent("img"))
    } else {
      return []
    }
  }
  public func userVideoURLs() -> [ URL ] {
    if fileProvider is LocalFileProvider {
      return fm.contentsOfDirectory(at: url.appendingPathComponent("videos"))
    } else {
      return []
    }
  }
  public func userDownloadURLs() -> [ URL ] {
    if fileProvider is LocalFileProvider {
      return fm.contentsOfDirectory(at: url.appendingPathComponent("downloads"))
    } else {
      return []
    }
  }

  public func favIcons() -> [ URL ] {
    if fileProvider is LocalFileProvider {
      return fm.contentsOfDirectory(at: url).filter {
        $0.lastPathComponent.hasPrefix("favicon.")
      }
    } else {
      return []
    }
  }
  
  
  // MARK: - Package Contents
  
  public struct DocumentFolder {
    public init(path: [String], archive: DocCArchive) {
      self.path = path
      self.archive = archive
    }
    public  let path    : [ String ]
    public  let archive : DocCArchive
    public  var level   : Int { return path.count }

    // Vrací seznam všech JSON souborů v dané složce (relativní cesta)
    public func pagePaths() -> [ String ] {
      let relativeDir = path.joined(separator: "/")
      do {
        let files = try archive.fileProvider.listFiles(in: relativeDir)
        return files.filter { $0.hasSuffix(".json") }
      } catch {
        print("ERROR: failed to list files in directory: \(relativeDir)")
        return []
      }
    }

    // Vrací podadresáře v dané složce (relativní cesta)
    public func subfolderPaths() -> [ String ] {
      let relativeDir = path.joined(separator: "/")
      do {
        let files = try archive.fileProvider.listFiles(in: relativeDir)
        // Vrací pouze adresáře (v HTTP variantě není podporováno, takže vrací prázdné pole)
        // Pro LocalFileProvider lze rozlišit, pro HTTPFileProvider ne
        if let local = archive.fileProvider as? LocalFileProvider {
          let dirURL = local.rootURL.appendingPathComponent(relativeDir)
          return try local.fileManager.contentsOfDirectory(atPath: dirURL.path).filter { name in
            var isDir: ObjCBool = false
            let fullPath = dirURL.appendingPathComponent(name).path
            local.fileManager.fileExists(atPath: fullPath, isDirectory: &isDir)
            return isDir.boolValue
          }
        } else {
          return []
        }
      } catch {
        return []
      }
    }

    // Načte dokument podle relativní cesty
    public func document(at relativePath: String) throws -> Document {
      let data = try archive.fileProvider.loadData(at: relativePath)
      return try JSONDecoder().decode(DocCArchive.Document.self, from: data)
    }
  }
  
  public func documentationFolder() -> DocumentFolder? {
    // Opraveno: začínáme v data/documentation
    let docPath = ["data", "documentation"]
    if fileProvider.fileExists(at: docPath.joined(separator: "/")) {
      return DocumentFolder(path: docPath, archive: self)
    } else {
      return nil
    }
  }
  public func tutorialsFolder() -> DocumentFolder? {
    if fileProvider is LocalFileProvider {
      guard let url = tutorialsURL else { return nil }
      return DocumentFolder(path: [ url.lastPathComponent ], archive: self)
    } else {
      return DocumentFolder(path: [ "tutorials" ], archive: self)
    }
  }
  
  // Načte dokument podle relativní cesty (pro LocalFileProvider lze použít URL, pro HTTPFileProvider pouze relativní cestu)
  public func document(at relativePath: String) throws -> Document {
    let data = try fileProvider.loadData(at: relativePath)
    return try JSONDecoder().decode(DocCArchive.Document.self, from: data)
  }

  // Výpis všech složek v data/ (používá se v testech)
  public func fetchDataFolderPathes() -> Set<String> {
    do {
      let folders = try fileProvider.listFiles(in: "")
      return Set(folders)
    } catch {
      return []
    }
  }
  
}

public extension DocCArchive {
  
  typealias DocCSchema = DocCSchema_0_1
  enum DocCSchema_0_1 {}
  
}

public enum DocCArchiveLoadingError: Swift.Error {

  case didNotFindArchive           (URL)
  case archiveIsNotADirectory      (URL)
  case archiveContainsNoContent    (URL)
  
  case unsupportedInlineContentType(String)
  case unsupportedContentType      (String)
  case unsupportedSectionKind      (String)
  case unsupportedFragmentKind     (String)
  case unsupportedMetaDataRole     (String)
  case unsupportedRole             (String)
  case unsupportedTaskContent      (String)
  case expectedStep                (String)
}
