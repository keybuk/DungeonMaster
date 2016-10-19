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
open class NetworkConnection: NSObject, StreamDelegate {
    
    /// Peer that established or accepted this connection.
    open weak var peer: NetworkPeer?
    
    /// Underlying input stream.
    open let inputStream: InputStream
    
    /// Underlying output stream.
    open let outputStream: OutputStream
    
    /// Underlying service that we are connected to.
    ///
    /// This is only present where the connection was established to an advertising peer, rather than accepted as a result of our advertising. It's used to (hopefully) track the loss of the service.
    open let service: NetService?
    
    /// Delegate object that receives notifications about new messages, and the connection being closed.
    open var delegate: NetworkConnectionDelegate?
    
    var opened = true
    var inputBuffer: [UInt8] = []
    var outgoingMessages: [NetworkMessage] = []
    
    public required init(peer: NetworkPeer, inputStream: InputStream, outputStream: OutputStream, service: NetService? = nil) {
        self.peer = peer
        self.inputStream = inputStream
        self.outputStream = outputStream
        self.service = service
        super.init()
        
        inputStream.delegate = self
        outputStream.delegate = self
        
        inputStream.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        outputStream.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)

        service?.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
    }
    
    deinit {
        close()
    }

    /// Closes the network stream, removing it from the run loop and disassociating it from the peer.
    open func close() {
        guard opened else { return }
        
        print("NET: Closing connection.")
        peer?.removeConnection(self)
        
        inputStream.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        outputStream.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)

        service?.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)

        inputStream.close()
        outputStream.close()
        
        OperationQueue.main.addOperation {
            self.delegate?.connectionDidClose(self)
        }

        opened = false
    }
    
    /// Send a message to the remote peer.
    ///
    /// The message is only immediately sent if there is space available on the output stream, otherwise it is queued.
    open func sendMessage(_ message: NetworkMessage) {
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
            var buffer: [UInt8] = Array(repeating: 0, count: 1024)
            let bytesRead = inputStream.read(&buffer, maxLength: buffer.count)
            if bytesRead < 0 {
                print("NET: Error in input stream: \(inputStream.streamError!.localizedDescription)")
                continue
            }

            inputBuffer.append(contentsOf: buffer.prefix(upTo: bytesRead))
        }
        
        // Parse messages from the buffer, each is prefixed by the size of the message so we know when we have complete messages.
        while inputBuffer.count > MemoryLayout<Int>.size {
            let length = UnsafePointer<Int>(inputBuffer).pointee
            guard inputBuffer.count >= MemoryLayout<Int>.size + length else { break }
            
            // Complete message in the buffer.
            inputBuffer.removeFirst(MemoryLayout<Int>.size)
            let bytes: [UInt8] = Array(inputBuffer.prefix(upTo: length))
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
            let length = withUnsafePointer(to: &count) { p in
                return UnsafeBufferPointer(start: UnsafePointer<UInt8>(p), count: MemoryLayout.size(ofValue: count))
            }
            
            bytes.insert(contentsOf: length, at: 0)
            let bytesWritten = outputStream.write(bytes, maxLength: bytes.count)
            guard bytesWritten == bytes.count else {
                print("NET: Short write while sending message, closing connection.")
                close()
                break
            }
        }
    }
    
    // MARK: NSStreamDelegate
    
    open func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        let stream = aStream == inputStream ? "Input" : aStream == outputStream ? "Output" : "Unknown"
        switch eventCode {
        case Stream.Event.openCompleted:
            print("NET: \(stream): Open completed.")
        case Stream.Event.hasBytesAvailable:
            readIncomingMessages()
        case Stream.Event.hasSpaceAvailable:
            writeOutgoingMessages()
        case Stream.Event.errorOccurred:
            print("NET: \(stream): An error occurred.\n     \(aStream.streamError!)")
            close()
        case Stream.Event.endEncountered:
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
    func connection(_ connection: NetworkConnection, didReceiveMessage message: NetworkMessage)
    
    /// The connection was closed.
    func connectionDidClose(_ connection: NetworkConnection)
    
}
