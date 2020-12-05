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

  let dateFormatter = DateFormatter()

  let supportedFileTypes: [CFString?] = [kUTTypeJPEG, kUTTypeGIF, kUTTypeTIFF, kUTTypeImage, "public.heic" as CFString]

  init() {
    exifToolPath = Bundle.main.path(forResource: "exiftool", ofType: "")!
    dateFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
  }

  func valueFor(tag: Tag, file: File) throws -> String {
      switch tag{
      case .Date:
        return try dateFor(file: file)
      case .Description:
        return try descriptionFor(file: file)
      case .Title:
        return try titleFor(file: file)
      }
  }

  func write(tagsValue: [Tag: String], file: File) throws {
    var tagsArgs = [Tag: [String]]()

    for (tag, value) in tagsValue {
      switch tag{
      case .Date:
        tagsArgs[tag] = writeDateArgs(date: value)
      case .Description:
        tagsArgs[tag] = writeDescriptionArgs(description: value)
      case .Title:
        tagsArgs[tag] = writeTitleArgs(title: value)
      }
    }

    if tagsArgs.count > 0 {
      try writeTags(URL: file.URL, tagsArguments: tagsArgs);
    }
  }

  func deleteValueFor(tags: [Tag], file: File) throws {
    var tagsValue: [Tag: String] = [Tag: String]()
    for tag in tags {
      tagsValue[tag] = ""
    }
    try write(tagsValue: tagsValue, file: file)
  }

  private func dateFor(file: File) throws -> String {
    return try read(URL: file.URL, arguments: ["-dateTimeOriginal", "-s3"]).replacingOccurrences(of: "\\n*", with: "", options: .regularExpression)
  }

  private func descriptionFor(file: File) throws -> String {
    return try read(URL: file.URL, arguments: ["-imageDescription", "-s3"]).replacingOccurrences(of: "\\n*", with: "", options: .regularExpression)
  }

  private func titleFor(file: File) throws -> String {
    return try read(URL: file.URL, arguments: ["-title", "-s3"]).replacingOccurrences(of: "\\n*", with: "", options: .regularExpression)
  }

  private func writeDateArgs(date: String) -> [String] {
    let tag = "-dateTimeOriginal"
    if date == "" {
      return ["\(tag)="]
    } else {
      return ["\(tag)=\(date)"]
    }
  }

  private func writeDescriptionArgs(description: String) -> [String] {
    let tag = "-imageDescription"
    if description == "" {
      return ["\(tag)="]
    } else {
      return ["\(tag)=\(description)"]
    }
  }

  private func writeTitleArgs(title: String) -> [String] {
    let tag = "-title"
    if title == "" {
      return ["\(tag)="]
    } else {
      return ["\(tag)=\(title)"]
    }
  }

  private func read(URL: URL, arguments: [String]) throws -> String {
    let output = execute(URL: URL, arguments: arguments)

    if let error = validateReadResult(output: output) {
      throw error
    }

    return output
  }

  private func writeTags(URL: URL, tagsArguments: [Tag: [String]]) throws {
    var arguments = [String]()

    for (_, tagArguments) in tagsArguments {
      arguments += tagArguments
    }

    // Run all tags
    do {
      try write(URL: URL, arguments: arguments)
    } catch MetaWriteError.NotUpdated {
      // Retry tag by tag
      if tagsArguments.count > 1 {
        for (_, tagArguments) in tagsArguments {
          do {
            try write(URL: URL, arguments: tagArguments)
          } catch {
            // Ignore
          }
        }
      }

      throw MetaWriteError.NotUpdated
    } catch let error {
      throw error
    }
  }

  private func write(URL: URL, arguments: [String]) throws {
    var defaultArgs = [String]()

    if overwriteFile {
      defaultArgs.append("-overwrite_original")
    }

    let output = execute(URL: URL, arguments: defaultArgs + arguments)

    if let error = validateWriteResult(output: output) {
      throw error
    }
  }

  private func validateReadResult(output: String) -> MetaWriteError? {
    let error = "Warning: Invalid EXIF text encoding for UserComment"
    if output.range(of: error) != nil {
      return MetaWriteError.CannotRead
    }
    return nil
  }

  private func validateWriteResult(output: String) -> MetaWriteError? {
    if output.range(of: "1 image files updated") == nil{
      return MetaWriteError.NotUpdated
    }
    return nil
  }

  private func execute(URL: URL, arguments: [String]) -> String {
    var defaultArgs = [String]()

    if ignoreMinorErrors {
      defaultArgs.append("-m")
    }

    // Setup the task
    let task = Process()
    task.launchPath = exifToolPath
    task.arguments = defaultArgs + arguments + [URL.path]

    // Pipe the standard out to an NSPipe
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe

    task.launch()

    let data: NSData = pipe.fileHandleForReading.readDataToEndOfFile() as NSData
    task.waitUntilExit()

    return NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue)! as String
  }
}
