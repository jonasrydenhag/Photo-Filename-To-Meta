//
//  Photo.swift
//  Photo Meta
//
//  Created by Jonas Rydenhag on 2015-08-23.
//  Copyright (c) 2015 Jonas Rydenhag. All rights reserved.
//

import Foundation

class Photo: File {

  enum PhotoExceptions: ErrorType {
    case NotSupported
  }
  
  enum WriteStatus {
    case Success
    case Partially
    case Failed
    case Unset
  }
  
  private (set) var latestRunStatus = WriteStatus.Unset
  private (set) var tagsValue: [Tag: String] = [Tag: String]()
  var fileName: String {
    get {
      return extractTitle()
    }
  }
  let dateFormatter = NSDateFormatter()
  var metaWriter: MetaWriter
  
  init(fileURL: NSURL, baseURL: NSURL, metaWriter: MetaWriter) throws {
    self.metaWriter = metaWriter
    try super.init(fileURL: fileURL, baseURL: baseURL)
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    
    if !self.fileTypeConformsTo(metaWriter.supportedFileTypes) {
      throw PhotoExceptions.NotSupported
    }
  }
  
  func write(tags: [Tag], overwriteValues: Bool = false) {
    var writeTags: [Tag: String] = [Tag: String]()
    
    for tag in tags {
      if !overwriteValues && valueFor(tag) != "" {
        continue
      }
      
      switch tag {
      case .Title:
        let title = extractTitle()
        
        if title != "" {
          let value = title
          writeTags[tag] = value
        }
      case .Date:
        if let date = extractDate() {
          let value = dateFormatter.stringFromDate(date)
          writeTags[tag] = value
        }
      }
    }
    
    do {
      try metaWriter.write(writeTags, file: self)
      
      for (tag, value) in writeTags {
        valueFor(tag, value: value)
      }
      
      if writeTags.count == tags.count {
        latestRunStatus = WriteStatus.Success
      } else if writeTags.count < tags.count {
        latestRunStatus = WriteStatus.Partially
      }
      
    } catch {
      handleWriteErrorFor(writeTags)
    }
  }
  
  func resetLatestRunStatus() {
    latestRunStatus = .Unset
  }
  
  func deleteValueFor(tags: [Tag]) {
    do {
      try metaWriter.deleteValueFor(tags, file: self)
      for tag in tags {
        tagsValue[tag] = nil
      }
      latestRunStatus = WriteStatus.Success
      
    } catch {
      handleDeleteErrorFor(tags)
    }
  }
  
  func read(tags: [Tag]) {
    for tag in tags {
      tagsValue[tag] = nil
      valueFor(tag)
    }
  }
  
  private func handleWriteErrorFor(tags: [Tag: String]) {
    // Update with current values
    read(Array(tags.keys))
    
    for (tag, value) in tags {
      if value == valueFor(tag) {
        latestRunStatus = WriteStatus.Partially
        break
      } else {
        latestRunStatus = WriteStatus.Failed
      }
    }
  }
  
  private func handleDeleteErrorFor(tags: [Tag]) {
    // Update with current values
    read(tags)
    
    for tag in tags {
      if valueFor(tag) != "" {
        latestRunStatus = WriteStatus.Partially
        break
      } else {
        latestRunStatus = WriteStatus.Failed
      }
    }
  }
  
  private func valueFor(tag: Tag, value: String = "") -> String? {
    if tagsValue[tag] == nil && value == "" {
      do {
        var tagValue = try metaWriter.valueFor(tag, file: self)
        
        if tag == Tag.Date {
          if let date = metaWriter.dateFormatter.dateFromString(tagValue) {
            tagValue = dateFormatter.stringFromDate(date)
          }
        }
        
        tagsValue[tag] = tagValue
      } catch {
        // Ignore value
      }
      
    } else if value != "" {
      tagsValue[tag] = value
    }
    return tagsValue[tag]
  }
  
  private func extractTitle() -> String {
      return URL.URLByDeletingPathExtension!.lastPathComponent!
  }
  
  private func extractDate() -> NSDate? {
    let regex = try! NSRegularExpression(pattern:"[0-9][0-9?][0-9?][0-9?]-[0-1?][0-9?]-[0-3?][0-9?]-*[0-9]*[0-9]*", options:[])
    
    let results = regex.matchesInString(fileName,
      options: [], range: NSMakeRange(0, (fileName as NSString).length))
      
    let dates = results.map { (self.fileName as NSString).substringWithRange($0.range)}
    
    if let firstDate = dates.first {
      if firstDate.characters.count < 10 {
        return nil
      }
      let formattedDate = "\(formatYear(firstDate))-\(formatMonth(firstDate))-\(formatDay(firstDate)) 00:00:\(formatEnumerator(firstDate))";
      
      return dateFormatter.dateFromString(formattedDate)
      
    } else {
      return nil
    }

  }
  
  private func formatYear(fullDate: String) -> String {
    let yearCand = (fullDate as NSString).substringWithRange(NSRange(location: 0, length: 4))
    var year = ""
    
    var stringPos = 0;
    for char in yearCand.characters {
      if char == "?" {
        switch stringPos {
        case 0:
          year += "1"
        case 1:
          year += "9"
        default:
          year += "0"
        }
      } else {
        year.append(char)
      }
      
      stringPos++
    }
    
    return year
  }
  
  private func formatMonth(fullDate: String) -> String {
    let monthCand = (fullDate as NSString).substringWithRange(NSRange(location: 5, length: 2))
    var month = ""
    
    var stringPos = 0;
    for char in monthCand.characters {
      if char == "?" {
        switch stringPos {
        case 1:
          month += "1"
        default:
          month += "0"
        }
      } else if stringPos == 1 && month == "0" && char == "0" {
          month += "1"
      } else {
        month.append(char)
      }
      
      stringPos++
    }
    
    return month
  }
  
  private func formatDay(fullDate: String) -> String {
    let dayCand = (fullDate as NSString).substringWithRange(NSRange(location: 8, length: 2))
    var day = ""
    
    var stringPos = 0;
    for char in dayCand.characters {
      if char == "?" {
        switch stringPos {
        case 1:
          day += "1"
        default:
          day += "0"
        }
      } else if stringPos == 1 && day == "0" && char == "0" {
          day += "1"
      } else {
        day.append(char)
      }
      
      stringPos++
    }
    
    return day
  }
  
  private func formatEnumerator(fullDate: String) -> String {
    if fullDate.characters.count < 13 {
      return "00"
      
    } else {
      let enumCand = (fullDate as NSString).substringWithRange(NSRange(location: 11, length: 2))
      var enumResult = ""
      
      var stringPos = 0;
      for char in enumCand.characters {
        if char == "?" {
            enumResult += "0"
        } else {
          enumResult.append(char)
        }
        
        stringPos++
      }
      
      return enumResult
    }
  }
  
  private func fileTypeConformsTo(types: [CFString!]) -> Bool {
    let pathExtension = URL.pathExtension!
    let fileUTI: Unmanaged<CFString>! = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, nil)
    let fileUTICF: CFString! = fileUTI.takeRetainedValue()
    
    for kUTType in types {
      if UTTypeConformsTo(fileUTICF, kUTType) {
        return true;
      }
    }
    
    return false;
  }
}
