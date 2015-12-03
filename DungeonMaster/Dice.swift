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

/// Protocol for representing a set of dice, or a modifier, in a dice roll.
protocol DiceOrModifier {
    
    var value: Int { get }
    var sign: JoiningSign { get }
    
}

/// Multiple dice with rolled values.
struct Dice: DiceOrModifier, Equatable {
    
    /// Set of individual die rolled.
    let values: [Die]
    
    /// Total value of all dice.
    let value: Int
    
    /// Sign preceeding this.
    let sign: JoiningSign
    
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
    }

}

func ==(lhs: Dice, rhs: Dice) -> Bool {
    guard lhs.values.count == rhs.values.count else { return false }
    for (ldice, rdice) in zip(lhs.values, rhs.values) {
        if ldice.value != rdice.value {
            return false
        }
    }
    return true
}


/// Constant modifier value in dice combo.
struct Modifier: DiceOrModifier, Equatable {
    
    /// Constant modifier value.
    let value: Int
    
    /// Sign preceeding this.
    let sign: JoiningSign
    
    init(value: Int, sign: JoiningSign = .None) {
        self.value = value
        self.sign = sign
    }

}

func ==(lhs: Modifier, rhs: Modifier) -> Bool {
    return lhs.value == rhs.value
}


/**
    Combination of dice and modifiers used for attacks.

    Example descriptions:

    - 4d8
    - 2d4 - 1
    - 2d6 + 4 + 3d8
*/
struct DiceCombo: Equatable {
    
    /// Individual sets of dice or modifiers, as parsed.
    let values: [DiceOrModifier]
    
    /// Total value of all dice and modifiers.
    let value: Int
    
    init(description: String) throws {
        var values = [DiceOrModifier]()
        var value = 0
        
        var numeric = ""
        var multiplier = 0
        var sign = JoiningSign.None

        func addValue() throws {
            guard numeric != "" else { return }
            guard values.count == 0 || sign != .None else { throw DieError.InvalidString }
            guard values.count > 0 || sign == .None else { throw DieError.InvalidString }

            guard let intValue = Int(numeric) else { throw DieError.InvalidString }

            let newValue: DiceOrModifier
            if multiplier > 0 {
                newValue = try Dice(multiplier: multiplier, sides: intValue, sign: sign)
            } else  {
                newValue = Modifier(value: intValue, sign: sign)
            }

            values.append(newValue)
            value += sign == .Minus ? -newValue.value : newValue.value

            numeric = ""
            multiplier = 0
            sign = .None
        }
        
        for c in description.characters {
            switch c {
            case "0"..."9":
                numeric.append(c)
            case "d":
                guard let intValue = Int(numeric) else { throw DieError.InvalidString }
                if intValue == 0 { throw DieError.InvalidMultiplier }
                multiplier = intValue
                numeric = ""
            case "+":
                guard sign == .None else { throw DieError.InvalidString }
                try addValue()
                sign = .Plus
            case "-":
                guard sign == .None else { throw DieError.InvalidString }
                try addValue()
                sign = .Minus
            case " ":
                try addValue()
            default:
                throw DieError.InvalidString
            }
        }
        
        try addValue()
        guard sign == .None else { throw DieError.InvalidString }
        guard values.count > 0 else { throw DieError.InvalidString }

        self.values = values
        self.value = value
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
