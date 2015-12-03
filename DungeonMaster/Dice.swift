//
//  Dice.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/2/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation

enum DieError: ErrorType {
    case InvalidSides
    case InvalidString
    case InvalidMultiplier
}

/// 🎲 Single die with rolled value.
struct Die: Equatable {

    /// Number of sides to the die.
    let sides: Int
    
    /// Value rolled.
    let value: Int

    init(sides: Int) throws {
        switch sides {
        case 4, 6, 8, 10, 12, 20, 100:
            self.sides = sides
        default:
            throw DieError.InvalidSides
        }
        
        value = Int(arc4random_uniform(UInt32(sides)) + 1)
    }
        
}

func ==(lhs: Die, rhs: Die) -> Bool {
    return lhs.sides == rhs.sides && lhs.value == rhs.value
}


/// Sign joining multiple components of a dice roll.
enum JoiningSign {
    case None
    case Plus
    case Minus
}

/// Multiple dice with rolled values.
struct Dice: Equatable {
    
    /// Set of individual die rolled, empty for a constant modifier.
    let values: [Die]
    
    /// Total value of all dice.
    let value: Int
    
    /// Sign preceeding this.
    let sign: JoiningSign
    
    /// Average value of the set of dice.
    let averageValue: Int
    
    init(multiplier: Int, sides: Int, sign: JoiningSign = .None) throws {
        guard multiplier > 0 else { throw DieError.InvalidMultiplier }
        var values = [Die]()
        var value = 0
        for _ in 0..<multiplier {
            let die = try Die(sides: sides)
            values.append(die)
            value += die.value
        }
        self.values = values
        self.value = value
        self.sign = sign
        self.averageValue = Int(Double(multiplier) * Double(sides + 1) / 2.0)
    }
    
    init(value: Int, sign: JoiningSign = .None) {
        self.values = []
        self.value = value
        self.sign = sign
        self.averageValue = value
    }


}

func ==(lhs: Dice, rhs: Dice) -> Bool {
    guard lhs.values.count == rhs.values.count else { return false }
    guard lhs.value == rhs.value else { return false }
    for (ldice, rdice) in zip(lhs.values, rhs.values) {
        if ldice.value != rdice.value {
            return false
        }
    }
    return true
}


/**
    Combination of dice and modifiers used for attacks.

    Example descriptions:

    - 4d8
    - 2d4 - 1
    - 2d6 + 4 + 3d8
*/
struct DiceCombo: Equatable {
    
    /// Dice objects representing groups of rolled dice, or constant modifiers.
    let values: [Dice]
    
    /// Total value of all dice and modifiers.
    let value: Int
    
    /// Average value of the sets of dice, added to the modifiers.
    let averageValue: Int

    init(description: String) throws {
        var values = [Dice]()
        var value = 0
        var averageValue = 0
        
        var numeric = ""
        var multiplier = 0
        var sign = JoiningSign.None

        func addValue() throws {
            guard values.count == 0 || sign != .None else { throw DieError.InvalidString }
            guard values.count > 0 || sign == .None else { throw DieError.InvalidString }

            guard let intValue = Int(numeric) else { throw DieError.InvalidString }

            let dice: Dice
            if multiplier > 0 {
                dice = try Dice(multiplier: multiplier, sides: intValue, sign: sign)
            } else  {
                dice = Dice(value: intValue, sign: sign)
            }

            values.append(dice)
            
            switch sign {
            case .None:
                value = dice.value
                averageValue = dice.averageValue
            case .Plus:
                value += dice.value
                averageValue += dice.averageValue
            case .Minus:
                value -= dice.value
                averageValue -= dice.averageValue
            }
            
            numeric = ""
            multiplier = 0
            sign = .None
        }
        
        for c in description.characters {
            switch c {
            case "0"..."9":
                numeric.append(c)
            case "d":
                guard multiplier == 0 else { throw DieError.InvalidString }
                guard let intValue = Int(numeric) else { throw DieError.InvalidString }
                if intValue == 0 { throw DieError.InvalidMultiplier }
                multiplier = intValue
                numeric = ""
            case "+":
                try addValue()
                sign = .Plus
            case "-":
                try addValue()
                sign = .Minus
            default:
                throw DieError.InvalidString
            }
        }
        
        try addValue()

        self.values = values
        self.value = value
        self.averageValue = averageValue
    }
    
}

func ==(lhs: DiceCombo, rhs: DiceCombo) -> Bool {
    guard lhs.values.count == rhs.values.count else { return false }
    for (ldice, rdice) in zip(lhs.values, rhs.values) {
        if ldice.value != rdice.value {
            return false
        }
    }
    return true
}
