//
//  PhotoFile.swift
//  PhotoMeta
//
//  Created by Jonas Rydenhag on 2020-10-03.
//  Copyright © 2020 Jonas Rydenhag. All rights reserved.
//

import Foundation

class PhotoFile: ReadOnlyPhotoFile {
  init(_ URL: URL, from readOnlyPhotoFile: ReadOnlyPhotoFile) throws {
    try super.init(URL, metaWriter: readOnlyPhotoFile.metaWriter)

    self.parsedTagValues = readOnlyPhotoFile.parsedTagValues
  }

  func write(tags: [Tag: String]) throws {
    do {
      try metaWriter.write(tagsValue: tags, file: self)

      for (tag, value) in tags {
        parsedTagValues[tag] = value
      }
    } catch {
      // Update with current values
      parseMetaValueFor(tags: Array(tags.keys))

      throw error
    }
  }

  func deleteValueFor(tags: [Tag]) throws {
    do {
      try metaWriter.deleteValueFor(tags: tags, file: self)

      for tag in tags {
        parsedTagValues[tag] = nil
      }
    } catch {
      // Update with current values
      parseMetaValueFor(tags: tags)

      throw error
    }
  }
}
