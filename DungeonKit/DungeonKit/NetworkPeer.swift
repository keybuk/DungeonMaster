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
    case DungeonMaster
    case InitiativeOrder
}

/// NetworkPeer manages peer relationships between this device, and other DungeonNet devices at the same table.
///
/// Each device both advertises its own network service, and searches for other advertising devices in the area. Connections are established in either direction, with the peer type determining the relationship. Once established the connection is handled by a `NetworkConnection` object, with individual messages represented as `NetworkMessage` instances.
public class NetworkPeer: NSObject, NSNetServiceDelegate, NSNetServiceBrowserDelegate {
    
    static let serviceDomain = "local."

    static let serviceType = "_dungeonnet._tcp"

    /// Type of this peer.
    public let type: NetworkPeerType
    
    /// Type of peers this one will accept.
    public let acceptedTypes: [NetworkPeerType]
    
    /// Underlying advertised network service.
    public let netService: NSNetService
    
    /// Underlying network service browser.
    public let netServiceBrowser: NSNetServiceBrowser
    
    /// Unique peer identifier.
    public let uuid: NSUUID

    /// Delegate to receive noitifications of new connections.
    public var delegate: NetworkPeerDelegate?
    
    public required init(type: NetworkPeerType, name: String, acceptedTypes: [NetworkPeerType]) {
        self.type = type
        self.acceptedTypes = acceptedTypes
        
        // In order for the advertised service name to be easily identifiable, add the device name.
        let serviceName = "\(name) (\(UIDevice.currentDevice().name))"
        self.netService = NSNetService(domain: NetworkPeer.serviceDomain, type: NetworkPeer.serviceType, name: serviceName, port: 0)
        
        self.netServiceBrowser = NSNetServiceBrowser()
        
        self.uuid = NSUUID()
        
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
    public func start() {
        guard !isRunning else { return }
        
        print("NET: Starting peer with identifier \(uuid.UUIDString).")
        netService.publishWithOptions(.ListenForConnections)
        netServiceBrowser.searchForServicesOfType(NetworkPeer.serviceType, inDomain: NetworkPeer.serviceDomain)

        isRunning = true
    }
    
    public var peers: [NSUUID: NetworkConnection] = [:]
    
    /// Estabished connections with other peers.
    public var connections: [NetworkConnection] {
        return Array(peers.values)
    }
    
    func establishConnection(inputStream inputStream: NSInputStream, outputStream: NSOutputStream, service: NSNetService?) {
        // Open the streams.
        inputStream.open()
        outputStream.open()

        // Perform an exchange of peer identifiers and types, first send ours.
        var handshakeBytes: [UInt8] = Array(count: 17, repeatedValue: 0)
        uuid.getUUIDBytes(&handshakeBytes)
        
        switch type {
        case .DungeonMaster:
            handshakeBytes[16] = 0x00
        case .InitiativeOrder:
            handshakeBytes[16] = 0x01
        }
        
        outputStream.write(&handshakeBytes, maxLength: 17)
        
        // And then receive from the other peer.
        inputStream.read(&handshakeBytes, maxLength: 17)
        
        let remoteUUID = NSUUID(UUIDBytes: &handshakeBytes)
        let remoteType: NetworkPeerType
        switch handshakeBytes[16] {
        case 0x00:
            remoteType = .DungeonMaster
        case 0x01:
            remoteType = .InitiativeOrder
        default:
            print("NET: Invalid remote peer type \(handshakeBytes[16]) received.")
            inputStream.close()
            outputStream.close()
            return
        }
        
        print("NET: Peer identifier \(remoteUUID.UUIDString), type \(remoteType).")
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
    
    func removeConnection(connection: NetworkConnection) {
        for (uuid, peerConnection) in peers {
            if peerConnection == connection {
                print("NET: Removed connection to peer \(uuid.UUIDString).")
                peers[uuid] = nil
            }
        }
    }

    /// Stops advertising and scanning for connections, and disconnects all existing connections.
    ///
    /// To resume, call `start()` again.
    public func stop() {
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
    public func broadcastMessage(message: NetworkMessage) {
        for connection in connections {
            connection.sendMessage(message)
        }
    }

    // MARK: NSNetServiceDelegate
    
    public func netServiceWillPublish(sender: NSNetService) {
        print("NET: Will publish service.")
        
        netService.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    
    public func netServiceDidPublish(sender: NSNetService) {
        print("NET: Published service as \(sender.name).")
    }
    
    public func netService(sender: NSNetService, didNotPublish errorDict: [String : NSNumber]) {
        print("NET: Publishing was not successful.\n     \(errorDict)")
        
        netService.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        
        // Retry once we get back to the main loop.
        dispatch_async(dispatch_get_main_queue()) {
            self.netService.publishWithOptions(.ListenForConnections)
        }
    }
    
    public func netServiceDidStop(sender: NSNetService) {
        print("NET: Publishing has stopped.")
        
        netService.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    
    public func netService(sender: NSNetService, didAcceptConnectionWithInputStream inputStream: NSInputStream, outputStream: NSOutputStream) {
        print("NET: Accepted connection.")
        
        // According to rdar://problem/15626440, this will be called on the wrong queue.
        dispatch_async(dispatch_get_main_queue()) {
            self.establishConnection(inputStream: inputStream, outputStream: outputStream, service: nil)
        }
    }
    
    // MARK: NSNetServiceBrowserDelegate
    
    public func netServiceBrowserWillSearch(browser: NSNetServiceBrowser) {
        print("NET: Will search for services.")
    
        netServiceBrowser.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    
    public func netServiceBrowser(browser: NSNetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        print("NET: Search was not successful.\n     \(errorDict)")
    
        netServiceBrowser.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        
        // Retry once we get back to the main loop.
        dispatch_async(dispatch_get_main_queue()) {
            self.netServiceBrowser.searchForServicesOfType(NetworkPeer.serviceType, inDomain: NetworkPeer.serviceDomain)
        }
    }
    
    public func netServiceBrowserDidStopSearch(browser: NSNetServiceBrowser) {
        print("NET: Searching has stopped.")

        netServiceBrowser.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    
    public func netServiceBrowser(browser: NSNetServiceBrowser, didFindService service: NSNetService, moreComing: Bool) {
        print("NET: Found service \(service.name), moreComing: \(moreComing).")
        
        guard service != netService else {
            print("     Ignoring our own")
            return
        }

        // Obtain the input and output stream for the service.
        var inputStream: NSInputStream?
        var outputStream: NSOutputStream?
        guard service.getInputStream(&inputStream, outputStream: &outputStream) else {
            print("NET: Failed to get streams")
            return
        }
        
        establishConnection(inputStream: inputStream!, outputStream: outputStream!, service: service)
    }
    
    public func netServiceBrowser(browser: NSNetServiceBrowser, didRemoveService service: NSNetService, moreComing: Bool) {
        print("NET: Lost service \(service.name), moreComing: \(moreComing).")
        service.stopMonitoring()
        service.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    
}

/// NetworkPeerDelegate is implemented to receive notifications and updates about changes to a `NetworkPeer`.
public protocol NetworkPeerDelegate {

    /// Called when a connection is established between two peer devices.
    ///
    /// The `connection` is passed already opened, and will be closed if not referenced by the delegate.
    func networkPeer(peer: NetworkPeer, didEstablishConnection connection: NetworkConnection)

}