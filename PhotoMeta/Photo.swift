//
//  Photo.swift
//  Photo Meta
//
//  Created by Jonas Rydenhag on 2015-08-23.
//  Copyright (c) 2015 Jonas Rydenhag. All rights reserved.
//

import Foundation

class Photo: File {

  enum PhotoExceptions: Error {
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
  let dateFormatter = DateFormatter()
  var metaWriter: MetaWriter
  
  init(fileURL: NSURL, baseURL: NSURL, metaWriter: MetaWriter) throws {
    self.metaWriter = metaWriter
    try super.init(fileURL: fileURL, baseURL: baseURL)
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    
    if !self.fileTypeConformsTo(types: metaWriter.supportedFileTypes) {
      throw PhotoExceptions.NotSupported
    }
  }
  
  func write(tags: [Tag], overwriteValues: Bool = false) {
    var writeTags: [Tag: String] = [Tag: String]()
    
    for tag in tags {
      if !overwriteValues && valueFor(tag: tag) != "" {
        continue
      }
      
      switch tag {
      case .Date:
        if let date = extractDate() {
          let value = dateFormatter.string(from: date as Date)
          writeTags[tag] = value
        }
      case .Description, .Title:
        let title = extractTitle()
        
        if title != "" {
          let value = title
          writeTags[tag] = value
        }
      }
    }
    
    do {
      try metaWriter.write(tagsValue: writeTags, file: self)
      
      for (tag, value) in writeTags {
        valueFor(tag: tag, value: value)
      }
      
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
      try metaWriter.deleteValueFor(tags: tags, file: self)
      for tag in tags {
        tagsValue[tag] = nil
      }
      latestRunStatus = WriteStatus.Success
      
    } catch {
      handleDeleteErrorFor(tags: tags)
    }
  }
  
  func read(tags: [Tag]) {
    for tag in tags {
      tagsValue[tag] = nil
      valueFor(tag: tag)
    }
  }
  
  private func handleWriteErrorFor(tags: [Tag: String]) {
    // Update with current values
    read(tags: Array(tags.keys))
    
    for (tag, value) in tags {
      if value == valueFor(tag: tag) {
        latestRunStatus = WriteStatus.Partially
        break
      } else {
        latestRunStatus = WriteStatus.Failed
      }
    }
  }
  
  private func handleDeleteErrorFor(tags: [Tag]) {
    // Update with current values
    read(tags: tags)
    
    for tag in tags {
      if valueFor(tag: tag) != "" {
        latestRunStatus = WriteStatus.Partially
        break
      } else {
        latestRunStatus = WriteStatus.Failed
      }
    }
  }
  
  @discardableResult private func valueFor(tag: Tag, value: String = "") -> String? {
    if tagsValue[tag] == nil && value == "" {
      do {
        var tagValue = try metaWriter.valueFor(tag: tag, file: self)
        
        if tag == Tag.Date {
          if let date = metaWriter.dateFormatter.date(from: tagValue) {
            tagValue = dateFormatter.string(from: date)
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
    return URL.deletingPathExtension!.lastPathComponent
  }

  private func extractDate() -> Date? {
    let regex = try! NSRegularExpression(pattern:"[0-9][0-9?][0-9?][0-9?]-[0-1?][0-9?]-[0-3?][0-9?]-*[0-9]*[0-9]*", options:[])
    
    let results = regex.matches(in: fileName,
      options: [], range: NSMakeRange(0, (fileName as NSString).length))
      
    let dates = results.map { (self.fileName as NSString).substring(with: $0.range)}
    
    if let firstDate = dates.first {
      if firstDate.count < 10 {
        return nil
      }
      let formattedDate = "\(formatYear(fullDate: firstDate))-\(formatMonth(fullDate: firstDate))-\(formatDay(fullDate: firstDate)) 00:00:\(formatEnumerator(fullDate: firstDate))";
      
      return dateFormatter.date(from: formattedDate)
      
    } else {
      return nil
    }

  }

  private func formatYear(fullDate: String) -> String {
    let yearCand = (fullDate as NSString).substring(with: NSRange(location: 0, length: 4))
    var year = ""
    
    var stringPos = 0;
    for char in yearCand {
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
      
      stringPos += 1
    }
    
    return year
  }
  
  private func formatMonth(fullDate: String) -> String {
    let monthCand = (fullDate as NSString).substring(with: NSRange(location: 5, length: 2))
    var month = ""
    
    var stringPos = 0;
    for char in monthCand {
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
      
      stringPos += 1
    }
    
    return month
  }
  
  private func formatDay(fullDate: String) -> String {
    let dayCand = (fullDate as NSString).substring(with: NSRange(location: 8, length: 2))
    var day = ""
    
    var stringPos = 0;
    for char in dayCand {
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
      
      stringPos += 1
    }
    
    return day
  }
  
  private func formatEnumerator(fullDate: String) -> String {
    if fullDate.count < 13 {
      return "00"
      
    } else {
      let enumCand = (fullDate as NSString).substring(with: NSRange(location: 11, length: 2))
      var enumResult = ""
      
      var stringPos = 0;
      for char in enumCand {
        if char == "?" {
            enumResult += "0"
        } else {
          enumResult.append(char)
        }
        
        stringPos += 1
      }
      
      return enumResult
    }
  }
  
  private func fileTypeConformsTo(types: [CFString?]) -> Bool {
    let pathExtension = URL.pathExtension!
    let fileUTI: Unmanaged<CFString>! = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as CFString, nil)
    let fileUTICF: CFString! = fileUTI.takeRetainedValue()
    
    for kUTType in types {
      if UTTypeConformsTo(fileUTICF, kUTType!) {
        return true;
      }
    }
    
    return false;
  }
}
