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

    case Hello(version: Int)
    
    case BeginEncounter(title: String)
    case InsertCombatant(toIndex: Int, name: String, initiative: Int?, isCurrentTurn: Bool, isAlive: Bool)
    case DeleteCombatant(fromIndex: Int)
    case UpdateCombatant(index: Int, name: String, initiative: Int?, isCurrentTurn: Bool, isAlive: Bool)
    case MoveCombatant(fromIndex: Int, toIndex: Int)
    case Round(round: Int)
    
    case Initiative(name: String, initiative: Int)
    case EndTurn(name: String)
    
    init?(bytes: [UInt8]) {
        guard bytes.count > 0 else { return nil }
        switch bytes[0] {
        case 0x00:
            // Version
            guard bytes.count == 2 else { return nil }
            
            self = .Hello(version: Int(bytes[1]))
        case 0x01:
            // BeginEncounter
            guard bytes.count >= 1 else { return nil }

            guard let title = String(bytes: bytes.suffixFrom(1), encoding: NSUTF8StringEncoding) else { return nil }

            self = .BeginEncounter(title: title)
        case 0x02:
            // InsertCombatant
            guard bytes.count >= 5 else { return nil }

            let toIndex = Int(bytes[1])
            let initiative: Int? = bytes[2] == 0x80 ? nil : Int(Int8(bitPattern: bytes[2]))
            let isCurrentTurn = bytes[3] != 0 ? true : false
            let isAlive = bytes[4] != 0 ? true : false
            guard let name = String(bytes: bytes.suffixFrom(5), encoding: NSUTF8StringEncoding) else { return nil }

            self = .InsertCombatant(toIndex: toIndex, name: name, initiative: initiative, isCurrentTurn: isCurrentTurn, isAlive: isAlive)
        case 0x03:
            // DeleteCombatant
            guard bytes.count == 2 else { return nil }
            
            self = .DeleteCombatant(fromIndex: Int(bytes[1]))
        case 0x04:
            // UpdateCombatant
            guard bytes.count >= 5 else { return nil }
            
            let index = Int(bytes[1])
            let initiative: Int? = bytes[2] == 0x80 ? nil : Int(Int8(bitPattern: bytes[2]))
            let isCurrentTurn = bytes[3] != 0 ? true : false
            let isAlive = bytes[4] != 0 ? true : false
            guard let name = String(bytes: bytes.suffixFrom(5), encoding: NSUTF8StringEncoding) else { return nil }
            
            self = .UpdateCombatant(index: index, name: name, initiative: initiative, isCurrentTurn: isCurrentTurn, isAlive: isAlive)
        case 0x05:
            // MoveCombatant
            guard bytes.count == 3 else { return nil }

            self = .MoveCombatant(fromIndex: Int(bytes[1]), toIndex: Int(bytes[2]))
        case 0x06:
            // Round
            guard bytes.count == 2 else { return nil }
            
            self = .Round(round: Int(bytes[1]))
        case 0x07:
            // Initiative
            guard bytes.count >= 2 else { return nil }
            
            let initiative = Int(Int8(bitPattern: bytes[1]))
            guard let name = String(bytes: bytes.suffixFrom(2), encoding: NSUTF8StringEncoding) else { return nil }
            
            self = .Initiative(name: name, initiative: initiative)
        case 0x08:
            // EndTurn
            guard bytes.count >= 1 else { return nil }
            
            guard let name = String(bytes: bytes.suffixFrom(1), encoding: NSUTF8StringEncoding) else { return nil }

            self = .EndTurn(name: name)
        default:
            return nil
        }
    }
    
    func toBytes() -> [UInt8] {
        var bytes: [UInt8] = []
        
        switch self {
        case let .Hello(version):
            bytes.append(0x00)
            bytes.append(UInt8(version))
        case let .BeginEncounter(title):
            bytes.append(0x01)
            bytes.appendContentsOf(title.utf8)
        case let .InsertCombatant(toIndex, name, initiative, isCurrentTurn, isAlive):
            bytes.append(0x02)
            bytes.append(UInt8(toIndex))
            bytes.append(initiative.map({ UInt8(bitPattern: Int8($0)) }) ?? 0x80)
            bytes.append(isCurrentTurn ? 1 : 0)
            bytes.append(isAlive ? 1 : 0)
            bytes.appendContentsOf(name.utf8)
        case let .DeleteCombatant(fromIndex):
            bytes.append(0x03)
            bytes.append(UInt8(fromIndex))
        case let .UpdateCombatant(index, name, initiative, isCurrentTurn, isAlive):
            bytes.append(0x04)
            bytes.append(UInt8(index))
            bytes.append(initiative.map({ UInt8(bitPattern: Int8($0)) }) ?? 0x80)
            bytes.append(isCurrentTurn ? 1 : 0)
            bytes.append(isAlive ? 1 : 0)
            bytes.appendContentsOf(name.utf8)
        case let .MoveCombatant(fromIndex, toIndex):
            bytes.append(0x05)
            bytes.append(UInt8(fromIndex))
            bytes.append(UInt8(toIndex))
        case let .Round(round):
            bytes.append(0x06)
            bytes.append(UInt8(round))
        case let .Initiative(name, initiative):
            bytes.append(0x07)
            bytes.append(UInt8(bitPattern: Int8(initiative)))
            bytes.appendContentsOf(name.utf8)
        case let .EndTurn(name):
            bytes.append(0x08)
            bytes.appendContentsOf(name.utf8)
        }
        
        return bytes
    }
    
}
