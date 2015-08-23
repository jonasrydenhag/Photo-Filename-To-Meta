//
//  File.swift
//  Photo Meta
//
//  Created by Jonas Rydenhag on 2015-08-23.
//  Copyright (c) 2015 Yasai, Inc. All rights reserved.
//

import Foundation

class File {
  
  private (set) var URL: NSURL
  private (set) var path: String
  var runner: ExifToolRunner
  
  init(fileURL: NSURL, runner: ExifToolRunner) {
    self.URL = fileURL
    self.path = fileURL.path!
    self.runner = runner
  }
  
  func process (tags: [Tag]) {
    for tag in tags {
      var output: String
      
      switch tag.name {
      case Tag.TitleTag:
        output = runner.titleFor(self)
      case Tag.DateTag:
        output = runner.dateFor(self)
      default:
        output = ""
      }
      
      println(output)
    }
  }
  
  static func fileTypeConfomsTo(inPath: String, types: [CFString!]) -> Bool {
    let pathExtension = inPath.pathExtension
    let fileUTI: Unmanaged<CFString>! = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, nil)
    let fileUTICF: CFString! = fileUTI.takeRetainedValue()
    
    for kUTType in types {
      if UTTypeConformsTo(fileUTICF, kUTType) != 0 {
        return true;
      }
    }
    
    return false;
  }
}
