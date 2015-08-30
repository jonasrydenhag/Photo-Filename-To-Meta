//
//  File.swift
//  Photo Meta
//
//  Created by Jonas Rydenhag on 2015-08-23.
//  Copyright (c) 2015 Yasai, Inc. All rights reserved.
//

import Foundation

class File {
  
  private (set) var URL: NSURL
  private (set) var path: String
  private (set) var valid: Bool = false
  private (set) var tagValues: [String : String] = [String : String]()
  var fileName: String {
    get {
      return extractTitle()
    }
  }
  let dateFormatter = NSDateFormatter()
  var runner: ExifToolRunner
  var kept = Array<Tag>()
  var extractionFailed = Array<Tag>()
  
  init(fileURL: NSURL, runner: ExifToolRunner) {
    self.URL = fileURL
    self.path = fileURL.path!
    self.runner = runner
    self.valid = self.fileTypeConformsTo(runner.supportedFileTypes)
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    extractDate()
  }
  
  func write(tags: [Tag], keepExistingTags: Bool = true, overwriteFile: Bool = false) {
    var writeTags = Array<Tag>()
    kept = Array<Tag>()
    extractionFailed = Array<Tag>()
    
    for tag in tags {
      var output: String
      
      var write = true
      if keepExistingTags && valueFor(tag) != "" {
        write = false;
        kept.append(tag)
        continue
      }
      
      switch tag.name {
      case Tag.TitleTag:
        let title = extractTitle()
        
        if title != "" {
          tag.value = title
          writeTags.append(tag)
          valueFor(tag, value: tag.value)
        } else {
          extractionFailed.append(tag)
        }
      case Tag.DateTag:
        if let date = extractDate() {
          tag.value = dateFormatter.stringFromDate(date)
          writeTags.append(tag)
          valueFor(tag, value: tag.value)
        } else {
          extractionFailed.append(tag)
        }
      default:
        continue
      }
    }
    
    runner.write(writeTags, file: self, overwriteFile: overwriteFile)
  }
  
  func deleteValueFor(tags: [Tag], overwriteFile: Bool = false) {
    kept = Array<Tag>()
    runner.deleteValueFor(tags, file: self, overwriteFile: overwriteFile)
    for tag in tags {
      tagValues[tag.name] = nil
    }
  }
  
  private func valueFor(tag: Tag, value: String = "") -> String {
    if tagValues[tag.name] == nil && value == "" {
      tagValues[tag.name] = runner.valueFor(tag, file: self)
    } else if value != "" {
      tagValues[tag.name] = value
    }
    return tagValues[tag.name]!
  }
  
  private func extractTitle() -> String {
      return path.lastPathComponent.stringByDeletingPathExtension
  }
  
  private func extractDate() -> NSDate? {
    let regex = NSRegularExpression(pattern:"[0-9][0-9?][0-9?][0-9?]-[0-1?][0-9?]-[0-3?][0-9?]-*[0-9]*[0-9]*", options:nil, error:nil)!
    
    let results = regex.matchesInString(fileName,
      options: nil, range: NSMakeRange(0, (fileName as NSString).length))
      as! [NSTextCheckingResult]
    let dates = map(results) { (self.fileName as NSString).substringWithRange($0.range)}
    
    if let firstDate = dates.first {
      if count(firstDate) < 10 {
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
      
      stringPos++
    }
    
    return year
  }
  
  private func formatMonth(fullDate: String) -> String {
    let monthCand = (fullDate as NSString).substringWithRange(NSRange(location: 5, length: 2))
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
      } else if stringPos == 1 && char == "0" {
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
    for char in dayCand {
      if char == "?" {
        switch stringPos {
        case 1:
          day += "1"
        default:
          day += "0"
        }
      } else if stringPos == 1 && char == "0" {
          day += "1"
      } else {
        day.append(char)
      }
      
      stringPos++
    }
    
    return day
  }
  
  private func formatEnumerator(fullDate: String) -> String {
    if count(fullDate) < 13 {
      return "00"
      
    } else {
      let enumCand = (fullDate as NSString).substringWithRange(NSRange(location: 11, length: 2))
      var enumResult = ""
      
      var stringPos = 0;
      for char in enumCand {
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
    let pathExtension = path.pathExtension
    let fileUTI: Unmanaged<CFString>! = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, nil)
    let fileUTICF: CFString! = fileUTI.takeRetainedValue()
    
    for kUTType in types {
      if UTTypeConformsTo(fileUTICF, kUTType) != 0 {
        return true;
      }
    }
    
    return false;
  }
}
