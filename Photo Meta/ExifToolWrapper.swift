//
//  ExifToolWrapper.swift
//  Photo Meta
//
//  Created by Jonas Rydenhag on 2015-08-22.
//  Copyright (c) 2015 Jonas Rydenhag. All rights reserved.
//

import Foundation

class ExifToolWrapper: MetaWriter {
  
  private let overwriteFile = true
  
  private let exifToolPath: String
  
  private let ignoreMinorErrors = true
  
  let supportedFileTypes: [CFString!] = [kUTTypeJPEG, kUTTypeGIF, kUTTypeTIFF]
  
  init() {
    exifToolPath = NSBundle.mainBundle().pathForResource("exiftool", ofType: "")!
  }
  
  func valueFor(tag: Tag, file: File) -> String {
      switch tag{
      case .Title:
        return titleFor(file)
      case .Date:
        return dateFor(file)
      }
  }
  
  func write(tagsValue: [Tag: String], file: File) {
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
      run(file.URL, arguments: tagsArgs + defaultArgs);
    }
  }
  
  func deleteValueFor(tags: [Tag], file: File) {
    var tagsValue: [Tag: String] = [Tag: String]()
    for tag in tags {
      tagsValue[tag] = ""
    }
    write(tagsValue, file: file)
  }
  
  private func titleFor(file: File) -> String {
    return run(file.URL, arguments: ["-title", "-s3"]).stringByReplacingOccurrencesOfString("\\n*", withString: "", options: .RegularExpressionSearch)
  }
  
  private func dateFor(file: File) -> String {
    return run(file.URL, arguments: ["-dateTimeOriginal", "-s3"]).stringByReplacingOccurrencesOfString("\\n*", withString: "", options: .RegularExpressionSearch)
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
  
  private func run(URL: NSURL, arguments: [String]) -> String {
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
    
    task.launch()
  
    let data: NSData = pipe.fileHandleForReading.readDataToEndOfFile()
    task.waitUntilExit()
    
    return NSString(data: data, encoding: NSUTF8StringEncoding) as! String
  }
}
