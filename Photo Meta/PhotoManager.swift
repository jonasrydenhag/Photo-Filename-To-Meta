//
//  PhotoManager.swift
//  Photo Meta
//
//  Created by Jonas Rydenhag on 2015-10-11.
//  Copyright © 2015 Jonas Rydenhag. All rights reserved.
//

import Foundation

class PhotoManager {

  private let fileManager: ViewController
  private let runner: ExifToolRunner
  private let photos: [Photo]
  private (set) var running = false
  private (set) var cancel = false
  var kept: [String: [Photo]] = [String : [Photo]]()
  
  init(photos: [Photo], runner: ExifToolRunner, fileManager: ViewController) {
    self.photos = photos
    self.runner = runner
    self.fileManager = fileManager
  }
  
  func read(tags: [Tag], afterEach: () -> Void) {
    running = true
    
    for photo in photos {
      if cancel {
        break
      }
      
      photo.read(tags)
      
      afterEach()
    }
    
    running = false
    cancel = false
  }
  
  func write(tags: [Tag], keepExistingTags: Bool = true, withSelected: [Photo] = [], afterEach: () -> Void) {
    run(tags, keepExistingTags: keepExistingTags, withSelected: withSelected, afterEach: afterEach)
  }
  
  func delete(tags: [Tag], afterEach: () -> Void) {
    run(tags, deleteTags: true, afterEach: afterEach)
  }
  
  func cancelRun() {
    cancel = true
  }
  
  private func run(tags: [Tag], keepExistingTags: Bool = true, deleteTags: Bool = false, withSelected: [Photo] = [], afterEach: () -> Void) {
    running = true
    kept = [String : [Photo]]()
    let runPhotos: [Photo]
    
    if withSelected.count > 0 {
      runPhotos = withSelected 
    } else {
      runPhotos = photos
    }
    
    resetLatestRunStatus(runPhotos)
    
    for photo in runPhotos {
      if cancel {
        break
      }
      
      do {
        try fileManager.copyIfNeeded(photo)
      } catch {
        continue
      }
        
      if deleteTags {
        photo.deleteValueFor(tags)
        
      } else {
        photo.write(tags, keepExistingTags: keepExistingTags)
        if keepExistingTags && photo.kept.count > 0 {
          for tag in photo.kept {
            if kept[tag.name] == nil {
              kept[tag.name] = []
            }
            kept[tag.name]!.append(photo)
          }
        }
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