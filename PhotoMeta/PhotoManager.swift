//
//  PhotoManager.swift
//  Photo Meta
//
//  Created by Jonas Rydenhag on 2015-10-11.
//  Copyright © 2015 Jonas Rydenhag. All rights reserved.
//

import Foundation

class PhotoManager: FileHandler {

  private let metaWriter: MetaWriter = ExifToolWrapper()
  private var photos: [Photo] = []
  private (set) var running = false
  private var cancel = false

  override func collectFiles() {
    super.collectFiles();
    self.photos = self.files.compactMap{ $0 as? Photo }
  }

  func read(tags: [Tag], afterEach: () -> Void) {
    resetLatestRunStatus(files: photos)

    running = true

    for photo in photos {
      if cancel {
        break
      }

      photo.parseMetaValueFor(tags: tags)

      afterEach()
    }

    running = false
    cancel = false
  }

  func write(tags: [Tag], overwriteValues: Bool = false, withSelected: [Photo] = [], afterEach: () -> Void) {
    run(tags: tags, overwriteValues: overwriteValues, withSelected: withSelected, afterEach: afterEach)
  }

  func delete(tags: [Tag], afterEach: () -> Void) {
    run(tags: tags, deleteTags: true, afterEach: afterEach)
  }

  func cancelRun() {
    cancel = true
  }

  func rename(_ photo: Photo, to: String) throws {
    let currentSourceFilename = photo.sourceFile.filename

    try rename(photo.sourceFile, to)

    if let targetFile = photo.targetFile {
      do {
        try rename(targetFile, to)
      } catch {
        try rename(photo.sourceFile, currentSourceFilename)

        throw error
      }
    }
  }

  internal override func createFrom(_ URL: URL, baseURL: URL) -> FileURL? {
    do {
      return try Photo(URL, baseURL: baseURL, metaWriter: metaWriter)
    } catch Photo.PhotoExceptions.NotSupported {
      return super.createFrom(URL, baseURL: baseURL)
    } catch  {
      return nil
    }
  }

  private func run(tags: [Tag], overwriteValues: Bool = false, deleteTags: Bool = false, withSelected: [Photo] = [], afterEach: () -> Void) {
    running = true
    let runPhotos: [Photo]

    if withSelected.count > 0 {
      runPhotos = withSelected 
    } else {
      runPhotos = photos
    }

    resetLatestRunStatus(files: runPhotos)

    for photo in runPhotos {
      if cancel {
        break
      }

      do {
        photo.targetFile = try copy(photoFile: photo.sourceFile)
      } catch {
        continue
      }

      if deleteTags {
        photo.deleteValueFor(tags: tags)
      } else {
        photo.write(tags: tags, overwriteValues: overwriteValues)
      }

      afterEach()
    }

    running = false
    cancel = false
  }

  private func copy(photoFile: ReadOnlyPhotoFile) throws -> PhotoFile {
    let targetURL = try copy(file: photoFile)

    return try PhotoFile(targetURL, baseURL: targetDir, from: photoFile)
  }

  private func resetLatestRunStatus(files: [Photo]) {
    for file in files {
      file.resetLatestRunStatus()
    }
  }
}
