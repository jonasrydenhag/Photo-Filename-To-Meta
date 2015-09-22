//
//  Tag.swift
//  Photo Meta
//
//  Created by Jonas Rydenhag on 2015-08-23.
//  Copyright (c) 2015 Jonas Rydenhag. All rights reserved.
//

import Foundation

class Tag {
  
  static let TitleTag = "title"
  static let DateTag = "date"
  private (set) var name: String
  var value: String
  
  init(name: String) {
    self.name = name
    self.value = ""
  }
}
