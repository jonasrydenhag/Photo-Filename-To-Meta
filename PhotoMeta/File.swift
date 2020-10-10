//
//  File.swift
//  Photo Meta
//
//  Created by Jonas Rydenhag on 2015-10-11.
//  Copyright © 2015 Jonas Rydenhag. All rights reserved.
//

import Foundation

class File: FileURL {
  enum FileExceptions: Error {
    case NotAFile
    case FileDoesNotExist
  }

  private (set) var baseURL: URL

  var relativePath: String {
    get {
      return URL.path.replacingOccurrences(of: baseURL.path + "/", with: "", options: NSString.CompareOptions.literal, range: nil)
    }
  }

  private (set) var URL: URL

  init(fileURL: URL, baseURL: URL) throws {
    self.URL = fileURL
    self.baseURL = baseURL

    if self.URL.hasDirectoryPath {
      throw FileExceptions.NotAFile
    }
  }

  func change(URL: URL) {
    self.URL = URL
  }
}
