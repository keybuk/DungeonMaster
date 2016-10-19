//
//  Dice.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/2/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation

enum DieError : Error {
    case invalidSides
    case invalidString
    case invalidMultiplier
}

/// 🎲 Single die with rolled value.
struct Die : Equatable {

    /// Number of sides to the die.
    let sides: Int
    
    /// Value rolled.
    let value: Int

    init(sides: Int) throws {
        switch sides {
        case 4, 6, 8, 10, 12, 20, 100:
            self.sides = sides
        default:
            throw DieError.invalidSides
        }
        
        value = Int(arc4random_uniform(UInt32(sides)) + 1)
    }
    
    /// Re-rolls the die, returning a Die object containing the new value.
    func reroll() -> Die {
        return try! Die(sides: sides)
    }
        
}

func ==(lhs: Die, rhs: Die) -> Bool {
    return lhs.sides == rhs.sides && lhs.value == rhs.value
}


/// Sign joining multiple components of a dice roll.
enum JoiningSign {
    case none
    case plus
    case minus
}

/// Multiple dice with rolled values.
struct Dice : Equatable, CustomStringConvertible {
    
    /// Set of individual die rolled, empty for a constant modifier.
    let dice: [Die]
    
    /// Total value of all dice.
    let value: Int
    
    /// Sign preceeding this.
    let sign: JoiningSign
    
    /// Average value of the set of dice.
    let averageValue: Int
    
    var description: String {
        if dice.count > 0 {
            return String(format: "%dd%d", dice.count, dice[0].sides)
        } else {
            return String(format: "%d", value)
        }
    }
    
    init(multiplier: Int, sides: Int, sign: JoiningSign = .none) throws {
        guard multiplier > 0 else { throw DieError.invalidMultiplier }
        var dice: [Die] = []
        var value = 0
        for _ in 0..<multiplier {
            let die = try Die(sides: sides)
            dice.append(die)
            value += die.value
        }
        self.dice = dice
        self.value = value
        self.sign = sign
        self.averageValue = Int(Double(multiplier) * Double(sides + 1) / 2.0)
    }
    
    init(value: Int, sign: JoiningSign = .none) {
        self.dice = []
        self.value = value
        self.sign = sign
        self.averageValue = value
    }
    
    /// Re-rolls the dice, returning a Dice object containing the new value.
    func reroll() -> Dice {
        if dice.count > 0 {
            return try! Dice(multiplier: dice.count, sides: dice[0].sides, sign: sign)
        } else {
            return Dice(value: value, sign: sign)
        }
    }
    
}

func ==(lhs: Dice, rhs: Dice) -> Bool {
    guard lhs.dice.count == rhs.dice.count else { return false }
    guard lhs.value == rhs.value else { return false }
    for (ldice, rdice) in zip(lhs.dice, rhs.dice) {
        if ldice != rdice {
            return false
        }
    }
    return true
}


/// Combination of dice and modifiers used for attacks.
///
/// Example descriptions:
///
/// - 4d8
/// - 2d4 - 1
/// - 2d6 + 4 + 3d8
///
/// Descriptions are turned into an array of Dice.
struct DiceCombo : Equatable, CustomStringConvertible {
    
    /// Dice objects representing groups of rolled dice, or constant modifiers.
    let dice: [Dice]
    
    /// Total value of all dice and modifiers.
    let value: Int
    
    /// Average value of the sets of dice, added to the modifiers.
    let averageValue: Int
    
    var description: String {
        var parts: [String] = []
        for dice in self.dice {
            switch dice.sign {
            case .none:
                break
            case .plus:
                parts.append(" + ")
            case .minus:
                parts.append(" - ")
            }
            parts.append(dice.description)
        }
        
        return parts.joined(separator: "")
    }

    init(multiplier: Int = 1, sides: Int, modifier: Int? = nil) throws {
        let dice = try Dice(multiplier: multiplier, sides: sides)
        
        if let modifier = modifier {
            let modifierDice = Dice(value: abs(modifier), sign: modifier >= 0 ? .plus : .minus)
            self.dice = [dice, modifierDice]
            self.value = dice.value + modifier
            self.averageValue = dice.averageValue
        } else {
            self.dice = [dice]
            self.value = dice.value
            self.averageValue = dice.averageValue
        }
    }
    
    init(description: String) throws {
        var dice: [Dice] = []
        var value = 0
        var averageValue = 0
        
        var numeric = ""
        var multiplier = 0
        var sign = JoiningSign.none

        func addValue() throws {
            guard dice.count == 0 || sign != .none else { throw DieError.invalidString }
            guard dice.count > 0 || sign == .none else { throw DieError.invalidString }

            guard let intValue = Int(numeric) else { throw DieError.invalidString }

            let newDice: Dice
            if multiplier > 0 {
                newDice = try Dice(multiplier: multiplier, sides: intValue, sign: sign)
            } else  {
                newDice = Dice(value: intValue, sign: sign)
            }

            dice.append(newDice)
            
            switch sign {
            case .none:
                value = newDice.value
                averageValue = newDice.averageValue
            case .plus:
                value += newDice.value
                averageValue += newDice.averageValue
            case .minus:
                value -= newDice.value
                averageValue -= newDice.averageValue
            }
            
            numeric = ""
            multiplier = 0
            sign = .none
        }
        
        var spaceOkayHere = false
        var lastWasSpace = false
        
        for c in description.characters {
            switch c {
            case "0"..."9":
                guard !lastWasSpace || numeric == "" else { throw DieError.invalidString }
                numeric.append(c)
                spaceOkayHere = true
                lastWasSpace = false
            case "d":
                guard !lastWasSpace else { throw DieError.invalidString }
                guard multiplier == 0 else { throw DieError.invalidString }
                guard let intValue = Int(numeric) else { throw DieError.invalidString }
                if intValue == 0 { throw DieError.invalidMultiplier }
                multiplier = intValue
                numeric = ""
                spaceOkayHere = false
                lastWasSpace = false
            case "+":
                try addValue()
                sign = .plus
                spaceOkayHere = true
                lastWasSpace = false
            case "-":
                try addValue()
                sign = .minus
                spaceOkayHere = true
                lastWasSpace = false
            case " ":
                guard spaceOkayHere else { throw DieError.invalidString }
                lastWasSpace = true
            default:
                throw DieError.invalidString
            }
        }
        
        guard !lastWasSpace else { throw DieError.invalidString }
        try addValue()

        self.dice = dice
        self.value = value
        self.averageValue = averageValue
    }
    
    /// Re-rolls the dice, returning a DiceCombo object containing the new value.
    func reroll() -> DiceCombo {
        return try! DiceCombo(description: self.description)
    }
    
}

func ==(lhs: DiceCombo, rhs: DiceCombo) -> Bool {
    guard lhs.dice.count == rhs.dice.count else { return false }
    for (ldice, rdice) in zip(lhs.dice, rhs.dice) {
        if ldice != rdice {
            return false
        }
    }
    return true
}
