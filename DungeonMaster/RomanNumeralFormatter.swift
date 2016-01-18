//
//  RomanNumeralFormatter.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 1/16/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import Foundation

/// RomanNumeralFormatterStyle indicates the style of roman numerals the formatter produces
/// - **Uppercase** produces upper-case numerals such as MCMXCVIII
/// - **Lowercase** prodcues lower-case numerals such as iv
enum RomanNumeralFormatterStyle {
    case Uppercase
    case Lowercase
}

/// RomanNumeralFormatter converts integer numbers into a string containing the roman numeral equivalent.
class RomanNumeralFormatter {
    
    /// Resulting roman numeral style.
    var style = RomanNumeralFormatterStyle.Uppercase
    
    /// Returns a formatted roman numeral string from the number given, or nil if the number cannot be represented.
    func stringFromNumber(number: Int) -> String? {
        guard number > 0 else { return nil }

        let numerals = [ ("M", 1000), ("CM", 900), ("D", 500), ("CD", 400), ("C", 100), ("XC", 90), ("L", 50), ("XL", 40), ("X", 10), ("IX", 9), ("V", 5), ("IV", 4), ("I", 1) ]

        var number = number
        var string = ""
        for (numeral, value) in numerals {
            while number >= value {
                string += numeral
                number -= value
            }
        }
        
        return style == .Uppercase ? string : string.lowercaseString
    }

}