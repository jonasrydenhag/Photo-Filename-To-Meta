//
//  ReadOnlyPhotoFile.swift
//  PhotoMeta
//
//  Created by Jonas Rydenhag on 2020-10-03.
//  Copyright © 2020 Jonas Rydenhag. All rights reserved.
//

import Foundation

class ReadOnlyPhotoFile: File {
  var date: Date? {
    get {
      if let date = filenameDate() {
        return date
      }

      return dateMeta()
    }
  }

  let dateFormatter = DateFormatter()

  var filename: String {
    get {
      return URL.lastPathComponent
    }
  }

  var metaWriter: MetaWriter

  public internal(set) var parsedTagValues: [Tag: String] = [Tag: String]()

  var title: String {
    get {
      return filenameTitle()
    }
  }

  init(_ URL: URL, metaWriter: MetaWriter) throws {
    self.metaWriter = metaWriter
    try super.init(URL)
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

    if !self.fileTypeConformsTo(types: metaWriter.supportedFileTypes) {
      throw Photo.PhotoExceptions.NotSupported
    }
  }

  func prepareWriteMetaData(forTags tags: [Tag], onlyEmpty: Bool = true) -> [Tag: String] {
    var tagsData: [Tag: String] = [Tag: String]()

    for tag in tags {
      if onlyEmpty && metaValueFor(tag: tag) != "" {
        continue
      }

      switch tag {
      case .Date:
        if let date = filenameDate() {
          let value = dateFormatter.string(from: date as Date)
          tagsData[tag] = value
        }
      case .Description, .Title:
        let title = filenameTitle()

        if title != "" {
          tagsData[tag] = title
        }
      }
    }

    return tagsData
  }

  func parseMetaValueFor(tags: [Tag]) {
    for tag in tags {
      parseMetaValueFor(tag: tag)
    }
  }

  private func metaValueFor(tag: Tag) -> String? {
    if parsedTagValues[tag] == nil {
      parseMetaValueFor(tag: tag)
    }

    return parsedTagValues[tag]
  }

  private func parseMetaValueFor(tag: Tag) {
    do {
      var tagValue = try metaWriter.valueFor(tag: tag, file: self)

      if tag == Tag.Date {
        if let date = metaWriter.dateFormatter.date(from: tagValue) {
          tagValue = dateFormatter.string(from: date)
        }
      }

      parsedTagValues[tag] = tagValue
    } catch {
      parsedTagValues[tag] = nil
    }
  }

  private func dateMeta() -> Date? {
    do {
      let dateValue = try metaWriter.valueFor(tag: Tag.Date, file: self)

      return metaWriter.dateFormatter.date(from: dateValue)
    } catch {
      // Ignore value
    }

    return nil
  }

  private func filenameDate() -> Date? {
    let regex = try! NSRegularExpression(pattern:"[0-9][0-9?][0-9?][0-9?]-[0-1?][0-9?]-[0-3?][0-9?]-*[0-9]*[0-9]*", options:[])

    let results = regex.matches(in: title,
      options: [], range: NSMakeRange(0, (title as NSString).length))

    let dates = results.map { (self.title as NSString).substring(with: $0.range)}

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

  private func filenameTitle() -> String {
    return URL.deletingPathExtension().lastPathComponent
  }

  private func fileTypeConformsTo(types: [CFString?]) -> Bool {
    let pathExtension = URL.pathExtension
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
