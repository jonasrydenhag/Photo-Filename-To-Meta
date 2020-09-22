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
      
      photo.read(tags: tags)
      
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
  
  internal override func createFileFrom(URL: NSURL, baseURL: NSURL) -> File? {
    do {
      let file = try Photo(fileURL: URL, baseURL: baseURL, metaWriter: metaWriter)
      return file
      
    } catch Photo.PhotoExceptions.NotSupported {
      return super.createFileFrom(URL: URL, baseURL: baseURL)
      
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
        try copyIfNeeded(file: photo)
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
  
  private func resetLatestRunStatus(files: [Photo]) {
    for file in files {
      file.resetLatestRunStatus()
    }
  }
}
