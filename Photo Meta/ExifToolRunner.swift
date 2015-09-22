//
//  ExifToolRunner.swift
//  Photo Meta
//
//  Created by Jonas Rydenhag on 2015-08-22.
//  Copyright (c) 2015 Jonas Rydenhag. All rights reserved.
//

import Foundation

class ExifToolRunner: NSObject {
  
  let exifToolPath: String
  
  let ignoreMinorErrors = true
  
  let supportedFileTypes: [CFString!] = [kUTTypeJPEG, kUTTypeGIF, kUTTypeTIFF]
  
  func valueFor(tag: Tag, file: File) -> String {
      switch tag.name {
      case Tag.TitleTag:
        return titleFor(file)
      case Tag.DateTag:
        return dateFor(file)
      default:
        return ""
      }
  }
  
  override init() {
    exifToolPath = NSBundle.mainBundle().pathForResource("exiftool", ofType: "")!
    
    super.init()
  }
  
  func titleFor(file: File) -> String {
    return run(file.path, arguments: ["-title", "-s3"], synchronous: true).stringByReplacingOccurrencesOfString("\\n*", withString: "", options: .RegularExpressionSearch)
  }
  
  func dateFor(file: File) -> String {
    return run(file.path, arguments: ["-dateTimeOriginal", "-s3"], synchronous: true).stringByReplacingOccurrencesOfString("\\n*", withString: "", options: .RegularExpressionSearch)
  }
  
  func write(tags: [Tag], file: File, overwriteFile: Bool = true) {
    var defaultArgs = Array<String>()
    var tagsArgs = Array<String>()
    
    if overwriteFile {
      defaultArgs.append("-overwrite_original")
    }
    
    for tag in tags {
      switch tag.name {
      case Tag.TitleTag:
        tagsArgs += writeTitleArgs(tag.value)
      case Tag.DateTag:
        tagsArgs += writeDateArgs(tag.value)
      default: ()
      }
    }
    
    if tagsArgs.count > 0 {
      run(file.path, arguments: tagsArgs + defaultArgs, synchronous: true);
    }
  }
  
  func deleteValueFor(tags: [Tag], file: File, overwriteFile: Bool = true) {
    for tag in tags {
      tag.value = ""
    }
    write(tags, file: file, overwriteFile: overwriteFile)
  }
  
  private func writeTitleArgs(title: String) -> [String] {
    let tag = "-title"
    if title == "" {
      return ["\(tag)="]
    } else {
      return ["\(tag)=\(title)"]
    }
  }
  
  private func writeDateArgs(date: String) -> [String] {
    let tag = "-dateTimeOriginal"
    if date == "" {
      return ["\(tag)="]
    } else {
      return ["\(tag)=\(date)"]
    }
  }
  
  private func run(path: String, arguments: [String], synchronous: Bool = false) -> String {
    var defaultArgs = Array<String>()
    
    if ignoreMinorErrors {
      defaultArgs.append("-m")
    }
    
    // Setup the task
    let task = NSTask()
    task.launchPath = exifToolPath
    task.arguments = defaultArgs + arguments + [path]

    // Pipe the standard out to an NSPipe
    let pipe = NSPipe()
    task.standardOutput = pipe
    task.standardError = pipe
    
    if synchronous {
      return runSynchronous(task, pipe: pipe)
      
    } else {
      runAsynchronous(task, pipe: pipe, observer: self, selector: "receivedData:")
      return ""
    }
  }
  
  private func runSynchronous(task: NSTask, pipe: NSPipe) -> String {
    task.launch()
  
    let data: NSData = pipe.fileHandleForReading.readDataToEndOfFile()
    task.waitUntilExit()
    
    return NSString(data: data, encoding: NSUTF8StringEncoding) as! String
  }
  
  private func runAsynchronous(task: NSTask, pipe: NSPipe, observer: AnyObject, selector: Selector) {
    let fh = pipe.fileHandleForReading
    fh.waitForDataInBackgroundAndNotify()
    
    // Set up the observer function
    NSNotificationCenter.defaultCenter().addObserver(observer, selector: selector, name:"NSFileHandleDataAvailableNotification", object: fh)
    
    task.launch()
  }

  func receivedData(notification: NSNotification) {
    // Unpack the FileHandle from the notification
    let fh:NSFileHandle = notification.object as! NSFileHandle
    // Get the data from the FileHandle
    let data = fh.availableData
    // Only deal with the data if it actually exists
    if data.length > 1 {
      // Since we just got the notification from fh, we must tell it to notify us again when it gets more data
      fh.waitForDataInBackgroundAndNotify()
      // Convert the data into a string
      let string = NSString(data: data, encoding: NSASCIIStringEncoding)
    }
  }
  
  func runPhotoScript(path: String) {
    // Setup the task
    let task = NSTask()
    task.launchPath = "/Users/jonas/Library/Mobile Documents/com~apple~CloudDocs/Projekt/Foto meta projekt/photo.sh"
    task.arguments = ["-p \(exifToolPath)", path]
    
    // Pipe the standard out to an NSPipe, and set it to notify us when it gets data
    let pipe = NSPipe()
    task.standardOutput = pipe
    
    runAsynchronous(task, pipe: pipe, observer: self, selector: "receivedData:")
  }
}
