//
//  NetworkConnection.swift
//  DungeonKit
//
//  Created by Scott James Remnant on 2/7/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import Foundation

/// NetworkConnection objects are created both by `NetworkServer` and `NetworkClient` and represent a bi-directional communication channel between devices.
///
/// Messages can be exchanged between the devices in the form of `NetworkMessage` objects, and incoming and outgoing queue of those is maintained within the connection object.
public class NetworkConnection: NSObject, NSStreamDelegate {
    
    /// Peer that established or accepted this connection.
    public weak var peer: NetworkPeer?
    
    /// Underlying input stream.
    public let inputStream: NSInputStream
    
    /// Underlying output stream.
    public let outputStream: NSOutputStream
    
    /// Underlying service that we are connected to.
    ///
    /// This is only present where the connection was established to an advertising peer, rather than accepted as a result of our advertising. It's used to (hopefully) track the loss of the service.
    public let service: NSNetService?
    
    /// Delegate object that receives notifications about new messages, and the connection being closed.
    public var delegate: NetworkConnectionDelegate?
    
    var opened = true
    var inputBuffer: [UInt8] = []
    var outgoingMessages: [NetworkMessage] = []
    
    public required init(peer: NetworkPeer, inputStream: NSInputStream, outputStream: NSOutputStream, service: NSNetService? = nil) {
        self.peer = peer
        self.inputStream = inputStream
        self.outputStream = outputStream
        self.service = service
        super.init()
        
        inputStream.delegate = self
        outputStream.delegate = self
        
        inputStream.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        outputStream.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)

        service?.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    
    deinit {
        close()
    }

    /// Closes the network stream, removing it from the run loop and disassociating it from the peer.
    public func close() {
        guard opened else { return }
        
        print("NET: Closing connection.")
        peer?.removeConnection(self)
        
        inputStream.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        outputStream.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)

        service?.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)

        inputStream.close()
        outputStream.close()
        
        NSOperationQueue.mainQueue().addOperationWithBlock {
            self.delegate?.connectionDidClose(self)
        }

        opened = false
    }
    
    /// Send a message to the remote peer.
    ///
    /// The message is only immediately sent if there is space available on the output stream, otherwise it is queued.
    public func sendMessage(message: NetworkMessage) {
        print("NET: Queued message.\n     \(message)")
        outgoingMessages.append(message)
        if outputStream.hasSpaceAvailable {
            writeOutgoingMessages()
        }
    }
    
    /// Read incoming messages from the input stream.
    func readIncomingMessages() {
        // Drain the input buffer.
        while inputStream.hasBytesAvailable {
            var buffer: [UInt8] = Array(count: 1024, repeatedValue: 0)
            let bytesRead = inputStream.read(&buffer, maxLength: buffer.count)

            inputBuffer.appendContentsOf(buffer.prefixUpTo(bytesRead))
        }
        
        // Parse messages from the buffer, each is prefixed by the size of the message so we know when we have complete messages.
        while inputBuffer.count > sizeof(Int) {
            let length = UnsafePointer<Int>(inputBuffer).memory
            guard inputBuffer.count >= sizeof(Int) + length else { break }
            
            // Complete message in the buffer.
            inputBuffer.removeFirst(sizeof(Int))
            let bytes: [UInt8] = Array(inputBuffer.prefixUpTo(length))
            guard let message = NetworkMessage(bytes: bytes) else {
                print("NET: Received unparseable message, closing connection.")
                close()
                break
            }
            
            inputBuffer.removeFirst(length)
            print("NET: Received message.\n     \(message)")
            delegate?.connection(self, didReceiveMessage: message)
        }
    }
    
    /// Write outgoing messages to the output stream.
    func writeOutgoingMessages() {
        while outgoingMessages.count > 0 && outputStream.hasSpaceAvailable {
            let message = outgoingMessages.removeFirst()
            print("NET: Sending message.\n     \(message)")
            var bytes = message.toBytes()
            
            var count = bytes.count
            let length = withUnsafePointer(&count) { p in
                return UnsafeBufferPointer(start: UnsafePointer<UInt8>(p), count: sizeofValue(count))
            }
            
            bytes.insertContentsOf(length, at: 0)
            let bytesWritten = outputStream.write(bytes, maxLength: bytes.count)
            guard bytesWritten == bytes.count else {
                print("NET: Short write while sending message, closing connection.")
                close()
                break
            }
        }
    }
    
    // MARK: NSStreamDelegate
    
    public func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        let stream = aStream == inputStream ? "Input" : aStream == outputStream ? "Output" : "Unknown"
        switch eventCode {
        case NSStreamEvent.OpenCompleted:
            print("NET: \(stream): Open completed.")
        case NSStreamEvent.HasBytesAvailable:
            readIncomingMessages()
        case NSStreamEvent.HasSpaceAvailable:
            writeOutgoingMessages()
        case NSStreamEvent.ErrorOccurred:
            print("NET: \(stream): An error occurred.\n     \(aStream.streamError!)")
            close()
        case NSStreamEvent.EndEncountered:
            print("NET: \(stream): End of stream encountered.")
            close()
        default:
            print("NET: \(stream): Unexpected stream event occurred, \(eventCode).")
            
        }
    }

}

/// NetworkConnectionDelegate is implemented by objects that wish to be informed about changes to a `NetworkConnection`.
public protocol NetworkConnectionDelegate {
    
    /// A message was received on the connection.
    func connection(connection: NetworkConnection, didReceiveMessage message: NetworkMessage)
    
    /// The connection was closed.
    func connectionDidClose(connection: NetworkConnection)
    
}
