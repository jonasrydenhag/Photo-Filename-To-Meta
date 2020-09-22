//
//  MetaWriter.swift
//  Photo Meta
//
//  Created by Jonas Rydenhag on 2015-10-12.
//  Copyright © 2015 Jonas Rydenhag. All rights reserved.
//

import Foundation

enum MetaWriteError: Error {
  case NotUpdated
  case CannotRead
}

protocol MetaWriter {
  
  var supportedFileTypes: [CFString?] { get }
  
  var dateFormatter: DateFormatter { get }
  
  func valueFor(tag: Tag, file: File) throws -> String
  
  func write(tagsValue: [Tag: String], file: File) throws
  
  func deleteValueFor(tags: [Tag], file: File) throws
  
}
