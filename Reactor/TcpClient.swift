//
//  Connection.swift
//  TrackiPad
//
//  Created by Admin on 11.03.16.
//  Copyright © 2016 Admin. All rights reserved.
//

import UIKit
import SpriteKit

typealias Byte = UInt8

class TcpClient : NSObject, NSStreamDelegate {
    var isConnect : Bool = false
    var sendXCoordinate: Int  = -1
    var sendDirection : String = ""
    
        private var inputStream: NSInputStream!
    private var outputStream: NSOutputStream!
    
    func toByteArray<T>(var value: T) -> [Byte] {
        return withUnsafePointer(&value) {
            Array(UnsafeBufferPointer(start: UnsafePointer<Byte>($0), count: sizeof(T)))
        }
    }
    
    func fromByteArray<T>(value: [Byte], _: T.Type) -> T {
        return value.withUnsafeBufferPointer {
            return UnsafePointer<T>($0.baseAddress).memory
        }
    }


    func connect(serverAddress : String, serverPort: UInt32) {
        print("connecting...")

      //  let b = toByteArray(id)
      //  var serverAddress: String = String(b[0])
      //  serverAddress += "."
      //  serverAddress +=  String(b[1])
     //   serverAddress += "."
     //   serverAddress +=  String(b[2])
     //   serverAddress += "."
     //   serverAddress +=  String(b[3])
        
        
        var readStream:  Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        
        
        
        CFStreamCreatePairWithSocketToHost(nil,  serverAddress, serverPort, &readStream, &writeStream)
        
        // Documentation suggests readStream and writeStream can be assumed to
        // be non-nil. If you believe otherwise, you can test if either is nil
        // and implement whatever error-handling you wish.
        
        self.inputStream = readStream!.takeRetainedValue()
        self.outputStream = writeStream!.takeRetainedValue()
        
        self.inputStream.delegate = self
        self.outputStream.delegate = self
        
        self.inputStream.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        self.outputStream.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        
        self.inputStream.open()
        self.outputStream.open()
        
        self.isConnect = true
    }
    
    
    func write(string: String)
    {
        let data: NSData = string.dataUsingEncoding(NSUTF8StringEncoding)!
        outputStream.write(UnsafePointer<UInt8>(data.bytes), maxLength: data.length)
    }
    
    func stream(stream: NSStream, handleEvent eventCode: NSStreamEvent) {
        
        
        var buffer = [UInt8](count: 4096, repeatedValue: 0)
        var result: Int = 0
        
        if stream == outputStream{
            print("output stream event")
        }
        
        
        switch (eventCode){
        case NSStreamEvent.OpenCompleted:
            NSLog("Stream opened")
            break
        case NSStreamEvent.HasBytesAvailable:
            NSLog("HasBytesAvailable")
            if stream == inputStream{
                while (inputStream.hasBytesAvailable){
                    result = inputStream.read(&buffer, maxLength: buffer.count)
                }
                let output = NSString(bytes: &buffer, length: result, encoding: NSUTF8StringEncoding)
                
                
                
                if !isConnect{isConnect = true}
                else if output?.length > 0
                {
                    var sep : Int = -1
                    for i in 0...result
                    {
                        if buffer[i] == 95
                        {
                            sep = i
                            break
                        }
                    }
                    
                    if sep != -1
                    {
                        sendDirection = (output?.substringToIndex(sep))!
                        let soutx = output?.substringFromIndex(sep+1)
                        sendXCoordinate = 1024 - Int(soutx!)!
                    }
                    
                    
                    
                }
            }
            break
        case NSStreamEvent.ErrorOccurred:
            NSLog("ErrorOccurred")
            break
        case NSStreamEvent.EndEncountered:
            NSLog("EndEncountered")
            break
        default:
            NSLog("unknown.")
        }
    }
}