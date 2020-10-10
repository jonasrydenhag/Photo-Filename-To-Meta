//
//  Photo.swift
//  Photo Meta
//
//  Created by Jonas Rydenhag on 2015-08-23.
//  Copyright (c) 2015 Jonas Rydenhag. All rights reserved.
//

import Foundation

class Photo: FileURL {
  enum PhotoExceptions: Error {
    case NotSupported
  }

  enum WriteStatus {
    case Success
    case Partially
    case Failed
    case Unset
  }

  var date: Date? {
    get {
      return targetFile?.date ?? sourceFile.date
    }
  }

  var filename: String {
    get {
      return targetFile?.filename ?? sourceFile.filename
    }
  }

  private (set) var latestRunStatus = WriteStatus.Unset

  var relativePath: String {
    get {
      return targetFile?.relativePath ?? sourceFile.relativePath
    }
  }

  let sourceFile: ReadOnlyPhotoFile

  var targetFile: PhotoFile?

  var title: String {
    get {
      return sourceFile.title
    }
  }

  init(_ URL: URL, baseURL: URL, metaWriter: MetaWriter) throws {
    self.sourceFile = try ReadOnlyPhotoFile(URL, baseURL: baseURL, metaWriter: metaWriter)
  }

  func write(tags: [Tag], overwriteValues: Bool = false) {
    let writeTags = sourceFile.prepareWriteMetaData(forTags: tags, onlyEmpty: overwriteValues == false)

    do {
      try targetFile!.write(tags: writeTags)

      if writeTags.count == tags.count {
        latestRunStatus = WriteStatus.Success
      } else if writeTags.count < tags.count {
        latestRunStatus = WriteStatus.Partially
      }
    } catch {
      handleWriteErrorFor(tags: writeTags)
    }
  }

  func resetLatestRunStatus() {
    latestRunStatus = .Unset
  }

  func deleteValueFor(tags: [Tag]) {
    do {
      try targetFile!.deleteValueFor(tags: tags)

      latestRunStatus = WriteStatus.Success
    } catch {
      handleDeleteErrorFor(tags: tags)
    }
  }

  func parseMetaValueFor(tags: [Tag]) {
    targetFile?.parseMetaValueFor(tags: tags) ?? sourceFile.parseMetaValueFor(tags: tags)
  }

  func parsedTagValue(for tag: Tag) -> String? {
    if let targetFile = self.targetFile {
      return targetFile.parsedTagValues[tag]
    } else {
      return sourceFile.parsedTagValues[tag]
    }
  }

  private func handleWriteErrorFor(tags: [Tag: String]) {
    for (tag, value) in tags {
      if value == targetFile?.parsedTagValues[tag] {
        latestRunStatus = WriteStatus.Partially
        break
      } else {
        latestRunStatus = WriteStatus.Failed
      }
    }
  }

  private func handleDeleteErrorFor(tags: [Tag]) {
    for tag in tags {
      if targetFile?.parsedTagValues[tag] == "" {
        latestRunStatus = WriteStatus.Partially
        break
      } else {
        latestRunStatus = WriteStatus.Failed
      }
    }
  }
}
