//
//  NetworkPeer.swift
//  DungeonKit
//
//  Created by Scott James Remnant on 2/18/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import Foundation


/// NetworkPeerType identifies the specific type of peer in the DungeonNet.
public enum NetworkPeerType {
    case dungeonMaster
    case initiativeOrder
}

/// NetworkPeer manages peer relationships between this device, and other DungeonNet devices at the same table.
///
/// Each device both advertises its own network service, and searches for other advertising devices in the area. Connections are established in either direction, with the peer type determining the relationship. Once established the connection is handled by a `NetworkConnection` object, with individual messages represented as `NetworkMessage` instances.
open class NetworkPeer: NSObject, NetServiceDelegate, NetServiceBrowserDelegate {
    
    static let serviceDomain = "local."

    static let serviceType = "_dungeonnet._tcp"

    /// Type of this peer.
    open let type: NetworkPeerType
    
    /// Type of peers this one will accept.
    open let acceptedTypes: [NetworkPeerType]
    
    /// Underlying advertised network service.
    open let netService: NetService
    
    /// Underlying network service browser.
    open let netServiceBrowser: NetServiceBrowser
    
    /// Unique peer identifier.
    open let uuid: UUID

    /// Delegate to receive noitifications of new connections.
    open var delegate: NetworkPeerDelegate?
    
    public required init(type: NetworkPeerType, name: String, acceptedTypes: [NetworkPeerType]) {
        self.type = type
        self.acceptedTypes = acceptedTypes
        
        // In order for the advertised service name to be easily identifiable, add the device name.
        let serviceName = "\(name) (\(UIDevice.current.name))"
        self.netService = NetService(domain: NetworkPeer.serviceDomain, type: NetworkPeer.serviceType, name: serviceName, port: 0)
        
        self.netServiceBrowser = NetServiceBrowser()
        
        self.uuid = UUID()
        
        super.init()
        
        netService.includesPeerToPeer = true
        netService.delegate = self
        
        netServiceBrowser.includesPeerToPeer = true
        netServiceBrowser.delegate = self
    }
    
    deinit {
        stop()
    }
    
    var isRunning = false

    /// Starts advertising and scanning for connections.
    open func start() {
        guard !isRunning else { return }
        
        print("NET: Starting peer with identifier \(uuid.uuidString).")
        netService.publish(options: .listenForConnections)
        netServiceBrowser.searchForServices(ofType: NetworkPeer.serviceType, inDomain: NetworkPeer.serviceDomain)

        isRunning = true
    }
    
    open var peers: [UUID: NetworkConnection] = [:]
    
    /// Estabished connections with other peers.
    open var connections: [NetworkConnection] {
        return Array(peers.values)
    }
    
    func establishConnection(inputStream: InputStream, outputStream: OutputStream, service: NetService?) {
        // Open the streams.
        inputStream.open()
        outputStream.open()

        // Perform an exchange of peer identifiers and types, first send ours.
        var handshakeBytes: [UInt8] = Array(repeating: 0, count: 17)
        (uuid as NSUUID).getBytes(&handshakeBytes)
        
        switch type {
        case .dungeonMaster:
            handshakeBytes[16] = 0x00
        case .initiativeOrder:
            handshakeBytes[16] = 0x01
        }
        
        let bytesWritten = outputStream.write(&handshakeBytes, maxLength: 17)
        guard bytesWritten == 17 else {
            if bytesWritten < 0 {
                print("NET: Error in output stream: \(outputStream.streamError?.localizedDescription)")
            } else {
                print("NET: Short header write on output stream")
            }

            inputStream.close()
            outputStream.close()
            return
        }
        
        // And then receive from the other peer.
        let bytesRead = inputStream.read(&handshakeBytes, maxLength: 17)
        guard bytesRead == 17 else {
            if bytesRead < 0 {
                print("NET: Error in input stream: \(inputStream.streamError?.localizedDescription)")
            } else {
                print("NET: Short header read on input stream")
            }
            
            inputStream.close()
            outputStream.close()
            return
        }
        
        let remoteUUID = NSUUID(uuidBytes: &handshakeBytes) as UUID
        let remoteType: NetworkPeerType
        switch handshakeBytes[16] {
        case 0x00:
            remoteType = .dungeonMaster
        case 0x01:
            remoteType = .initiativeOrder
        default:
            print("NET: Invalid remote peer type \(handshakeBytes[16]) received.")
            inputStream.close()
            outputStream.close()
            return
        }
        
        print("NET: Peer identifier \(remoteUUID.uuidString), type \(remoteType).")
        if let _ = peers[remoteUUID] {
            print("     Already connected, dropping.")
            inputStream.close()
            outputStream.close()
            return
        }
        
        if !acceptedTypes.contains(remoteType) {
            print("     Not an accepted peer type, dropping.")
            inputStream.close()
            outputStream.close()
            return
        }
        
        // Connection is a new one.
        let connection = NetworkConnection(peer: self, inputStream: inputStream, outputStream: outputStream, service: service)
        peers[remoteUUID] = connection
        
        self.delegate?.networkPeer(self, didEstablishConnection: connection)
    }
    
    func removeConnection(_ connection: NetworkConnection) {
        for (uuid, peerConnection) in peers {
            if peerConnection == connection {
                print("NET: Removed connection to peer \(uuid.uuidString).")
                peers[uuid] = nil
            }
        }
    }

    /// Stops advertising and scanning for connections, and disconnects all existing connections.
    ///
    /// To resume, call `start()` again.
    open func stop() {
        guard isRunning else { return }
        
        print("NET: Stopping peer.")
        netService.stop()
        netServiceBrowser.stop()
        
        for connection in connections {
            connection.close()
        }

        isRunning = false
    }
    
    /// Broadcast a message to all connections.
    open func broadcastMessage(_ message: NetworkMessage) {
        for connection in connections {
            connection.sendMessage(message)
        }
    }

    // MARK: NSNetServiceDelegate
    
    open func netServiceWillPublish(_ sender: NetService) {
        print("NET: Will publish service.")
        
        netService.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
    }
    
    open func netServiceDidPublish(_ sender: NetService) {
        print("NET: Published service as \(sender.name).")
    }
    
    open func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        print("NET: Publishing was not successful.\n     \(errorDict)")
        
        netService.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        
        // Retry once we get back to the main loop.
        DispatchQueue.main.async {
            self.netService.publish(options: .listenForConnections)
        }
    }
    
    open func netServiceDidStop(_ sender: NetService) {
        print("NET: Publishing has stopped.")
        
        netService.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
    }
    
    open func netService(_ sender: NetService, didAcceptConnectionWith inputStream: InputStream, outputStream: OutputStream) {
        print("NET: Accepted connection.")
        
        // According to rdar://problem/15626440, this will be called on the wrong queue.
        DispatchQueue.main.async {
            self.establishConnection(inputStream: inputStream, outputStream: outputStream, service: nil)
        }
    }
    
    // MARK: NSNetServiceBrowserDelegate
    
    open func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        print("NET: Will search for services.")
    
        netServiceBrowser.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
    }
    
    open func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        print("NET: Search was not successful.\n     \(errorDict)")
    
        netServiceBrowser.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        
        // Retry once we get back to the main loop.
        DispatchQueue.main.async {
            self.netServiceBrowser.searchForServices(ofType: NetworkPeer.serviceType, inDomain: NetworkPeer.serviceDomain)
        }
    }
    
    open func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        print("NET: Searching has stopped.")

        netServiceBrowser.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
    }
    
    open func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("NET: Found service \(service.name), moreComing: \(moreComing).")
        
        guard service != netService else {
            print("     Ignoring our own")
            return
        }

        // Obtain the input and output stream for the service.
        var inputStream: InputStream?
        var outputStream: OutputStream?
        guard service.getInputStream(&inputStream, outputStream: &outputStream) else {
            print("NET: Failed to get streams")
            return
        }
        
        establishConnection(inputStream: inputStream!, outputStream: outputStream!, service: service)
    }
    
    open func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        print("NET: Lost service \(service.name), moreComing: \(moreComing).")
        service.stopMonitoring()
        service.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
    }
    
}

/// NetworkPeerDelegate is implemented to receive notifications and updates about changes to a `NetworkPeer`.
public protocol NetworkPeerDelegate {

    /// Called when a connection is established between two peer devices.
    ///
    /// The `connection` is passed already opened, and will be closed if not referenced by the delegate.
    func networkPeer(_ peer: NetworkPeer, didEstablishConnection connection: NetworkConnection)

}
