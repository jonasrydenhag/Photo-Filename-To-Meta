//
//  File.swift
//  Photo Meta
//
//  Created by Jonas Rydenhag on 2015-10-11.
//  Copyright © 2015 Jonas Rydenhag. All rights reserved.
//

import Foundation

class File {

  enum FileExceptions: ErrorType {
    case NotAFile
    case FileDoesNotExist
  }
  
  private (set) var URL: NSURL
  private (set) var baseURL: NSURL
  var relativePath: String {
    get {
      return URL.path!.stringByReplacingOccurrencesOfString(baseURL.path! + "/", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
    }
  }
  
  init(fileURL: NSURL, baseURL: NSURL) throws {
    self.URL = fileURL
    self.baseURL = baseURL
    
    if self.URL.resourceSpecifier == NSURLFileResourceTypeDirectory {
      throw FileExceptions.NotAFile
    }
  }
  
  func changeURL(fileURL: NSURL, baseURL: NSURL) -> File {
    self.URL = fileURL
    self.baseURL = baseURL
    return self
  }
}