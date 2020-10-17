//
//  FileHandler.swift
//  Photo Meta
//
//  Created by Jonas Rydenhag on 2015-10-12.
//  Copyright © 2015 Jonas Rydenhag. All rights reserved.
//

import Foundation

class FileHandler: FileManager {

  enum PathExceptions: Error {
    case TargetURLNotDir
  }

  let sourceDir: URL
  let targetDir: URL
  private (set) var files: [FileURL] = []

  init(sourceURL: URL, targetURL: URL) {
    self.sourceDir = sourceURL
    self.targetDir = targetURL
    super.init()
    self.collectFiles()
  }

  internal func collectFiles() {
    var baseUrlIsDir: ObjCBool = false
    if fileExists(atPath: sourceDir.path, isDirectory: &baseUrlIsDir) && baseUrlIsDir.boolValue == false {
      add(sourceDir, baseURL: sourceDir.deletingLastPathComponent())
    } else {
      if let urls = __enumerator(at: sourceDir, includingPropertiesForKeys: nil)?.allObjects as? [URL] {
        for url in urls.reversed() {
          add(url, baseURL: sourceDir)
        }
      }
    }
  }

  internal func createFrom(_ URL: URL, baseURL: URL) -> FileURL? {
    do {
      return try File(fileURL: URL, baseURL: baseURL)
    } catch  {
      return nil
    }
  }

  internal func copy(file: File) throws -> URL {
    if !fileExists(atPath: file.URL.path) {
      throw File.FileExceptions.FileDoesNotExist
    }

    var isDir: ObjCBool = false
    if !fileExists(atPath: targetDir.path, isDirectory:&isDir) || isDir.boolValue == false {
      throw PathExceptions.TargetURLNotDir
    }

    let targetURL = try prepareCopyDestPath(sourceFile: file)

    if targetURL.path != file.URL.path {
      try copyItem(at: file.URL, to: targetURL)
    }

    return targetURL
  }

  internal func rename(_ file: File, _ to: String) throws {
    let targetURL = URL(fileURLWithPath: to, relativeTo: file.baseURL as URL)

    try moveItem(at: file.URL, to: targetURL)

    file.change(URL: targetURL)
  }

  private func add(_ URL: URL, baseURL: URL) {
    var isDir: ObjCBool = false

    if !fileExists(atPath: URL.path, isDirectory: &isDir) || isDir.boolValue || URL.lastPathComponent == ".DS_Store"{
      return
    }

    if let file = createFrom(URL, baseURL: baseURL) {
      files.append(file)
    }
  }

  private func prepareCopyDestPath(sourceFile: File) throws -> URL {
    let targetURL = URL(fileURLWithPath: sourceFile.relativePath, relativeTo: targetDir)

    if targetURL.path != sourceFile.URL.path {
      if fileExists(atPath: targetURL.path) {
        try removeItem(at: targetURL)
      }

      try createDirectory(at: targetURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
    }

    return targetURL
  }
}
