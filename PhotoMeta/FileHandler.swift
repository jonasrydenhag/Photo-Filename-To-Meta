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
  
  let sourceURL: NSURL
  let targetURL: NSURL
  private (set) var files: [File] = []
  
  init(sourceURL: NSURL, targetURL: NSURL) {
    self.sourceURL = sourceURL
    self.targetURL = targetURL
    super.init()
    self.collectFiles()
  }
  
  func rename(_ file: File, to: String) throws {
    try renameSource(file, to)
    try renameTarget(file, to)
  }

  internal func collectFiles() {
    if sourceURL.path == nil {
      return
    }
    
    var baseUrlIsDir: ObjCBool = false
    if fileExists(atPath: sourceURL.path!, isDirectory: &baseUrlIsDir) && baseUrlIsDir.boolValue == false {
      addFileFrom(path: sourceURL.path!, baseURL: sourceURL.deletingLastPathComponent! as NSURL)
      
    } else {
      let enumerator: FileManager.DirectoryEnumerator? = __enumerator(at: sourceURL as URL, includingPropertiesForKeys: nil, options: [], errorHandler: nil)
      
      while let fileURL: NSURL = enumerator?.nextObject() as? NSURL {
        addFileFrom(path: fileURL.path!, baseURL: sourceURL)
      }
    }
  }
  
  internal func createFileFrom(URL: NSURL, baseURL: NSURL) -> File? {
    do {
      let file = try File(fileURL: URL, baseURL: baseURL)
      return file
    } catch  {
      return nil
    }
  }
  
  internal func copyIfNeeded(file: File) throws {
    if !fileExists(atPath: file.URL.path!) {
      throw File.FileExceptions.FileDoesNotExist
    }
    if sourceURL.path != targetURL.path {
      try copy(file: file, toDir: targetURL)
    }
  }
  
  private func addFileFrom(path: String, baseURL: NSURL) {
    var isDir: ObjCBool = false
    let URL = NSURL(fileURLWithPath: path, isDirectory: false)
    
    if !fileExists(atPath: path, isDirectory: &isDir) || isDir.boolValue || URL.lastPathComponent == ".DS_Store"{
      return
    }
    
    if let file = createFileFrom(URL: URL, baseURL: baseURL) {
      files.append(file)
    }
  }
  
  private func prepareCopyDestPath(file: File, toDir: NSURL) throws -> String {
    var fromBaseDir: ObjCBool = false
    var destPath: String
    let relativeFilePath = file.relativePath
    let relativeURL = NSURL(fileURLWithPath: relativeFilePath, isDirectory: false)
    
    fileExists(atPath: file.URL.path!, isDirectory:&fromBaseDir)
    
    var targetPath = toDir.path! + "/"
    destPath = targetPath + relativeFilePath
    
    if relativeURL.deletingLastPathComponent?.relativePath != "." {
      targetPath += relativeURL.deletingLastPathComponent!.relativePath + "/"
      
      if destPath != file.URL.path {
        var targetPathDir: ObjCBool = false
        if fileExists(atPath: targetPath, isDirectory: &targetPathDir) && targetPathDir.boolValue == false {
          try removeItem(atPath: targetPath)
        }
        
        try createDirectory(atPath: targetPath, withIntermediateDirectories: true, attributes: nil)
      }
    }
    
    if destPath != file.URL.path && fileExists(atPath: destPath) {
      try removeItem(atPath: destPath)
    }
    
    return destPath
  }
  
  @discardableResult private func copy(file: File, toDir: NSURL) throws -> File? {
    var isDir: ObjCBool = false
    if !fileExists(atPath: toDir.path!, isDirectory:&isDir) || isDir.boolValue == false {
      throw PathExceptions.TargetURLNotDir
    }
    
    let destPath = try prepareCopyDestPath(file: file, toDir: targetURL)
  
    if destPath == file.URL.path {
      return nil
    }
    
    try copyItem(atPath: file.URL.path!, toPath: destPath)
    let URL = NSURL(fileURLWithFileSystemRepresentation: destPath, isDirectory: false, relativeTo: targetURL as URL)
    
    return file.changeURL(fileURL: URL, baseURL: toDir)
  }

  private func renameSource(_ file: File, _ to: String) throws {
    let toSourceUrl = URL(fileURLWithPath: to, relativeTo: sourceURL as URL)

    let fileSourceUrl = URL(fileURLWithPath: file.URL.lastPathComponent!, relativeTo: sourceURL as URL)

    try moveItem(at: fileSourceUrl, to: toSourceUrl)

    if file.baseURL == sourceURL {
      file.changeURL(fileURL: toSourceUrl as NSURL, baseURL: sourceURL)
    }
  }

  private func renameTarget(_ file: File, _ to: String) throws {
    let toTargetUrl = URL(fileURLWithPath: to, relativeTo: targetURL as URL)

    if file.baseURL == targetURL {
      try moveItem(at: file.URL as URL, to: toTargetUrl)

      file.changeURL(fileURL: toTargetUrl as NSURL, baseURL: targetURL)
    }
  }
}
