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
    case FileDoesNotExist
    case MissingBaseURL
    case NotAFile
  }

  private (set) var baseURL: URL

  private (set) var URL: URL

  init(_ URL: URL) throws {
    self.URL = URL

    if let baseURL = URL.baseURL {
      self.baseURL = baseURL
    } else {
      throw FileExceptions.MissingBaseURL
    }

    if self.URL.hasDirectoryPath {
      throw FileExceptions.NotAFile
    }
  }

  func change(URL: URL) {
    self.URL = URL
  }
}
