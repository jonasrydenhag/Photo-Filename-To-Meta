//
//  FileManager.swift
//  Photo Meta
//
//  Created by Jonas Rydenhag on 2015-10-12.
//  Copyright © 2015 Jonas Rydenhag. All rights reserved.
//

import Foundation

class FileManager {

  enum PathExceptions: ErrorType {
    case TargetURLNotDir
  }
  
  private let nsFileManager = NSFileManager.defaultManager()
  let sourceURL: NSURL
  let targetURL: NSURL
  private (set) var files: [File] = []
  
  init(sourceURL: NSURL, targetURL: NSURL) {
    self.sourceURL = sourceURL
    self.targetURL = targetURL
  }
  
  internal func collectFiles() {
    if sourceURL.path == nil {
      return
    }
    
    var baseUrlIsDir: ObjCBool = false
    if nsFileManager.fileExistsAtPath(sourceURL.path!, isDirectory:&baseUrlIsDir) && !baseUrlIsDir {
      addFileFrom(sourceURL.path!, baseURL: sourceURL.URLByDeletingLastPathComponent!)
      
    } else {
      let enumerator: NSDirectoryEnumerator? = nsFileManager.enumeratorAtURL(sourceURL, includingPropertiesForKeys: nil, options: [], errorHandler: nil)
      
      while let fileURL: NSURL = enumerator?.nextObject() as? NSURL {
        addFileFrom(fileURL.path!, baseURL: sourceURL)
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
  
  internal func copyIfNeeded(file: Photo) throws {
    if !nsFileManager.fileExistsAtPath(file.URL.path!) {
      throw File.FileExceptions.FileDoesNotExist
    }
    if sourceURL.path != targetURL.path {
      try copy(file, toDir: targetURL)
    }
  }
  
  private func addFileFrom(path: String, baseURL: NSURL) {
    var isDir: ObjCBool = false
    let URL = NSURL(fileURLWithPath: path, isDirectory: false)
    
    if !nsFileManager.fileExistsAtPath(path, isDirectory: &isDir) || isDir || URL.lastPathComponent == ".DS_Store"{
      return
    }
    
    if let file = createFileFrom(URL, baseURL: baseURL) {
      files.append(file)
    }
  }
  
  private func prepareCopyDestPath(file: File, toDir: NSURL) throws -> String {
    var fromBaseDir: ObjCBool = false
    var destPath: String
    let relativeFilePath = file.relativePath
    let relativeURL = NSURL(fileURLWithPath: relativeFilePath, isDirectory: false)
    
    nsFileManager.fileExistsAtPath(file.URL.path!, isDirectory:&fromBaseDir)
    
    var targetPath = toDir.path! + "/"
    destPath = targetPath + relativeFilePath
    
    if relativeURL.URLByDeletingLastPathComponent?.relativePath != "." {
      targetPath += relativeURL.URLByDeletingLastPathComponent!.relativePath! + "/"
      
      if destPath != file.URL.path {
        var targetPathDir: ObjCBool = false
        if nsFileManager.fileExistsAtPath(targetPath, isDirectory:&targetPathDir) && !targetPathDir {
          try nsFileManager.removeItemAtPath(targetPath)
        }
        
        try nsFileManager.createDirectoryAtPath(targetPath, withIntermediateDirectories: true, attributes: nil)
      }
    }
    
    if destPath != file.URL.path && nsFileManager.fileExistsAtPath(destPath) {
      try nsFileManager.removeItemAtPath(destPath)
    }
    
    return destPath
  }
  
  private func copy(file: File, toDir: NSURL) throws -> File? {
    var isDir: ObjCBool = false
    if !nsFileManager.fileExistsAtPath(toDir.path!, isDirectory:&isDir) || !isDir {
      throw PathExceptions.TargetURLNotDir
    }
    
    let destPath = try prepareCopyDestPath(file, toDir: targetURL)
  
    if destPath == file.URL.path {
      return nil
    }
    
    try nsFileManager.copyItemAtPath(file.URL.path!, toPath: destPath)
    let URL = NSURL(fileURLWithFileSystemRepresentation: destPath, isDirectory: false, relativeToURL: targetURL)
    
    return file.changeURL(URL, baseURL: toDir)
  }
}
