//
//  Tag.swift
//  Photo Meta
//
//  Created by Jonas Rydenhag on 2015-08-23.
//  Copyright (c) 2015 Yasai, Inc. All rights reserved.
//

import Foundation

class Tag {
  
  static let TitleTag = "title"
  static let DateTag = "date"
  
  private (set) var name: String
  
  init(name: String) {
    self.name = name
  }
}
