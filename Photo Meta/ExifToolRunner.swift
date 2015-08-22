//
//  ExifToolRunner.swift
//  Photo Meta
//
//  Created by Jonas Rydenhag on 2015-08-22.
//  Copyright (c) 2015 Yasai, Inc. All rights reserved.
//

import Foundation

class ExifToolRunner: NSObject {
  
  func runTool(path: String) {
    // Setup the task
    let task = NSTask()
    task.launchPath = "/Users/jonas/Library/Mobile Documents/com~apple~CloudDocs/Projekt/Foto meta projekt/photo.sh"
    task.arguments = ["-p /usr/local/bin/exiftool", path]
    
    // Pipe the standard out to an NSPipe, and set it to notify us when it gets data
    let pipe = NSPipe()
    task.standardOutput = pipe
    let fh = pipe.fileHandleForReading
    fh.waitForDataInBackgroundAndNotify()
    
    // Set up the observer function
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "receivedData:", name:"NSFileHandleDataAvailableNotification", object: fh)

    // You can also set a function to fire after the task terminates
    task.terminationHandler = {task -> Void in
      // Handle the task ending here
      NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
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
      println(string!)
    }
  }
}
