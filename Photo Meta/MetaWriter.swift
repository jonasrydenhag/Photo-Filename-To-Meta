//
//  MetaWriter.swift
//  Photo Meta
//
//  Created by Jonas Rydenhag on 2015-10-12.
//  Copyright © 2015 Jonas Rydenhag. All rights reserved.
//

import Foundation

protocol MetaWriter {
  
  var supportedFileTypes: [CFString!] { get }
  
  func valueFor(tag: Tag, file: File) -> String
  
  func write(tagsValue: [Tag: String], file: File)
  
  func deleteValueFor(tags: [Tag], file: File)
  
}
