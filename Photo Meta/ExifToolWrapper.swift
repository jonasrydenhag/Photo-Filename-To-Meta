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
  
  let dateFormatter = NSDateFormatter()
  
  let supportedFileTypes: [CFString!] = [kUTTypeJPEG, kUTTypeGIF, kUTTypeTIFF]
  
  init() {
    exifToolPath = NSBundle.mainBundle().pathForResource("exiftool", ofType: "")!
    dateFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
  }
  
  func valueFor(tag: Tag, file: File) -> String {
      switch tag{
      case .Title:
        return titleFor(file)
      case .Date:
        return dateFor(file)
      }
  }
  
  func write(tagsValue: [Tag: String], file: File) throws {
    var tagsArgs = [Tag: [String]]()
    
    for (tag, value) in tagsValue {
      switch tag{
      case .Title:
        tagsArgs[tag] = writeTitleArgs(value)
      case .Date:
        tagsArgs[tag] = writeDateArgs(value)
      }
    }
    
    if tagsArgs.count > 0 {
      try writeTags(file.URL, tagsArguments: tagsArgs);
    }
  }
  
  func deleteValueFor(tags: [Tag], file: File) throws {
    var tagsValue: [Tag: String] = [Tag: String]()
    for tag in tags {
      tagsValue[tag] = ""
    }
    try write(tagsValue, file: file)
  }
  
  private func titleFor(file: File) -> String {
    return read(file.URL, arguments: ["-title", "-s3"]).stringByReplacingOccurrencesOfString("\\n*", withString: "", options: .RegularExpressionSearch)
  }
  
  private func dateFor(file: File) -> String {
    return read(file.URL, arguments: ["-dateTimeOriginal", "-s3"]).stringByReplacingOccurrencesOfString("\\n*", withString: "", options: .RegularExpressionSearch)
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
  
  private func read(URL: NSURL, arguments: [String]) -> String {
    return execute(URL, arguments: arguments)
  }
  
  private func writeTags(URL: NSURL, tagsArguments: [Tag: [String]]) throws {
    var arguments = [String]()
    
    for (_, tagArguments) in tagsArguments {
      arguments += tagArguments
    }
    
    // Run all tags
    do {
      try write(URL, arguments: arguments)
      
    } catch MetaWriteError.NotUpdated {
      // Retry tag by tag
      for (_, tagArguments) in tagsArguments {
        do {
          try write(URL, arguments: tagArguments)
        } catch {
          // Ignore
        }
      }
      
      throw MetaWriteError.NotUpdated
      
    } catch let error {
      throw error
    }
  }
  
  private func write(URL: NSURL, arguments: [String]) throws {
    var defaultArgs = [String]()
    
    if overwriteFile {
      defaultArgs.append("-overwrite_original")
    }
    
    let output = execute(URL, arguments: defaultArgs + arguments)
    
    let error = validateWriteResult(output)
    
    if error != nil {
      throw error!
    }
  }
  
  private func validateWriteResult(output: String) -> MetaWriteError? {
    if output.rangeOfString("1 image files updated") == nil{
      return MetaWriteError.NotUpdated
    }
    return nil
  }
  
  private func execute(URL: NSURL, arguments: [String]) -> String {
    var defaultArgs = [String]()
    
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
