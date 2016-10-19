//
//  NetworkMessage.swift
//  DungeonKit
//
//  Created by Scott James Remnant on 2/7/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import Foundation

/// NetworkMessage represents an individual message exchanged between DungeonNet peers.
public enum NetworkMessage {
    
    /// Version number that changes with any non-binary compatible changes to this structure.
    public static let version = 0

    case hello(version: Int)
    
    case beginEncounter(title: String)
    case insertCombatant(toIndex: Int, name: String, initiative: Int?, isCurrentTurn: Bool, isAlive: Bool)
    case deleteCombatant(fromIndex: Int)
    case updateCombatant(index: Int, name: String, initiative: Int?, isCurrentTurn: Bool, isAlive: Bool)
    case moveCombatant(fromIndex: Int, toIndex: Int)
    case round(round: Int)
    
    case initiative(name: String, initiative: Int)
    case endTurn(name: String)
    
    init?(bytes: [UInt8]) {
        guard bytes.count > 0 else { return nil }
        switch bytes[0] {
        case 0x00:
            // Version
            guard bytes.count == 2 else { return nil }
            
            self = .hello(version: Int(bytes[1]))
        case 0x01:
            // BeginEncounter
            guard bytes.count >= 1 else { return nil }

            guard let title = String(bytes: bytes.suffix(from: 1), encoding: String.Encoding.utf8) else { return nil }

            self = .beginEncounter(title: title)
        case 0x02:
            // InsertCombatant
            guard bytes.count >= 5 else { return nil }

            let toIndex = Int(bytes[1])
            let initiative: Int? = bytes[2] == 0x80 ? nil : Int(Int8(bitPattern: bytes[2]))
            let isCurrentTurn = bytes[3] != 0 ? true : false
            let isAlive = bytes[4] != 0 ? true : false
            guard let name = String(bytes: bytes.suffix(from: 5), encoding: String.Encoding.utf8) else { return nil }

            self = .insertCombatant(toIndex: toIndex, name: name, initiative: initiative, isCurrentTurn: isCurrentTurn, isAlive: isAlive)
        case 0x03:
            // DeleteCombatant
            guard bytes.count == 2 else { return nil }
            
            self = .deleteCombatant(fromIndex: Int(bytes[1]))
        case 0x04:
            // UpdateCombatant
            guard bytes.count >= 5 else { return nil }
            
            let index = Int(bytes[1])
            let initiative: Int? = bytes[2] == 0x80 ? nil : Int(Int8(bitPattern: bytes[2]))
            let isCurrentTurn = bytes[3] != 0 ? true : false
            let isAlive = bytes[4] != 0 ? true : false
            guard let name = String(bytes: bytes.suffix(from: 5), encoding: String.Encoding.utf8) else { return nil }
            
            self = .updateCombatant(index: index, name: name, initiative: initiative, isCurrentTurn: isCurrentTurn, isAlive: isAlive)
        case 0x05:
            // MoveCombatant
            guard bytes.count == 3 else { return nil }

            self = .moveCombatant(fromIndex: Int(bytes[1]), toIndex: Int(bytes[2]))
        case 0x06:
            // Round
            guard bytes.count == 2 else { return nil }
            
            self = .round(round: Int(bytes[1]))
        case 0x07:
            // Initiative
            guard bytes.count >= 2 else { return nil }
            
            let initiative = Int(Int8(bitPattern: bytes[1]))
            guard let name = String(bytes: bytes.suffix(from: 2), encoding: String.Encoding.utf8) else { return nil }
            
            self = .initiative(name: name, initiative: initiative)
        case 0x08:
            // EndTurn
            guard bytes.count >= 1 else { return nil }
            
            guard let name = String(bytes: bytes.suffix(from: 1), encoding: String.Encoding.utf8) else { return nil }

            self = .endTurn(name: name)
        default:
            return nil
        }
    }
    
    func toBytes() -> [UInt8] {
        var bytes: [UInt8] = []
        
        switch self {
        case let .hello(version):
            bytes.append(0x00)
            bytes.append(UInt8(version))
        case let .beginEncounter(title):
            bytes.append(0x01)
            bytes.append(contentsOf: title.utf8)
        case let .insertCombatant(toIndex, name, initiative, isCurrentTurn, isAlive):
            bytes.append(0x02)
            bytes.append(UInt8(toIndex))
            bytes.append(initiative.map({ UInt8(bitPattern: Int8($0)) }) ?? 0x80)
            bytes.append(isCurrentTurn ? 1 : 0)
            bytes.append(isAlive ? 1 : 0)
            bytes.append(contentsOf: name.utf8)
        case let .deleteCombatant(fromIndex):
            bytes.append(0x03)
            bytes.append(UInt8(fromIndex))
        case let .updateCombatant(index, name, initiative, isCurrentTurn, isAlive):
            bytes.append(0x04)
            bytes.append(UInt8(index))
            bytes.append(initiative.map({ UInt8(bitPattern: Int8($0)) }) ?? 0x80)
            bytes.append(isCurrentTurn ? 1 : 0)
            bytes.append(isAlive ? 1 : 0)
            bytes.append(contentsOf: name.utf8)
        case let .moveCombatant(fromIndex, toIndex):
            bytes.append(0x05)
            bytes.append(UInt8(fromIndex))
            bytes.append(UInt8(toIndex))
        case let .round(round):
            bytes.append(0x06)
            bytes.append(UInt8(round))
        case let .initiative(name, initiative):
            bytes.append(0x07)
            bytes.append(UInt8(bitPattern: Int8(initiative)))
            bytes.append(contentsOf: name.utf8)
        case let .endTurn(name):
            bytes.append(0x08)
            bytes.append(contentsOf: name.utf8)
        }
        
        return bytes
    }
    
}
