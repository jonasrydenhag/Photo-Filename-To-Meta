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
  
  func valueFor(tag: Tag, file: Photo) -> String {
      switch tag{
      case .Title:
        return titleFor(file)
      case .Date:
        return dateFor(file)
      }
  }
  
  override init() {
    exifToolPath = NSBundle.mainBundle().pathForResource("exiftool", ofType: "")!
    
    super.init()
  }
  
  func titleFor(file: Photo) -> String {
    return run(file.URL, arguments: ["-title", "-s3"], synchronous: true).stringByReplacingOccurrencesOfString("\\n*", withString: "", options: .RegularExpressionSearch)
  }
  
  func dateFor(file: Photo) -> String {
    return run(file.URL, arguments: ["-dateTimeOriginal", "-s3"], synchronous: true).stringByReplacingOccurrencesOfString("\\n*", withString: "", options: .RegularExpressionSearch)
  }
  
  func write(tagsValue: [Tag: String], file: Photo, overwriteFile: Bool = true) {
    var defaultArgs = Array<String>()
    var tagsArgs = Array<String>()
    
    if overwriteFile {
      defaultArgs.append("-overwrite_original")
    }
    
    for (tag, value) in tagsValue {
      switch tag{
      case .Title:
        tagsArgs += writeTitleArgs(value)
      case .Date:
        tagsArgs += writeDateArgs(value)
      }
    }
    
    if tagsArgs.count > 0 {
      run(file.URL, arguments: tagsArgs + defaultArgs, synchronous: true);
    }
  }
  
  func deleteValueFor(tags: [Tag], file: Photo, overwriteFile: Bool = true) {
    var tagsValue: [Tag: String] = [Tag: String]()
    for tag in tags {
      tagsValue[tag] = ""
    }
    write(tagsValue, file: file, overwriteFile: overwriteFile)
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
  
  private func run(URL: NSURL, arguments: [String], synchronous: Bool = false) -> String {
    var defaultArgs = Array<String>()
    
    if ignoreMinorErrors {
      defaultArgs.append("-m")
    }
    
    // Setup the task
    let task = NSTask()
    task.launchPath = exifToolPath
    task.arguments = defaultArgs + arguments + [URL.path!]

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
      _ = NSString(data: data, encoding: NSASCIIStringEncoding)
    }
  }
}
