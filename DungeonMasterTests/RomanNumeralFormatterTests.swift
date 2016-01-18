//
//  RomanNumeralFormatterTests.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 1/18/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import XCTest
@testable import DungeonMaster

class RomanNumeralFormatterTests: XCTestCase {
    
    func testUppercaseRepresentations() {
        let representations = [
            (1, "I"), (2, "II"), (3, "III"), (4, "IV"), (5, "V"), (6, "VI"), (7, "VII"), (8, "VIII"), (9, "IX"), (10, "X"), (14, "XIV"), (15, "XV"), (19, "XIX"), (40, "XL"), (45, "XLV"), (50, "L"), (90, "XC"), (95, "XCV"), (100, "C"), (546, "DXLVI"), (1998, "MCMXCVIII")
        ]
        
        let formatter = RomanNumeralFormatter()
        for (number, numeral) in representations {
            let string = formatter.stringFromNumber(number)

            XCTAssertNotNil(string)
            XCTAssertEqual(string!, numeral)
        }
    }
    
    func testLowercaseRepresentations() {
        let representations = [
            (1, "i"), (2, "ii"), (3, "iii"), (4, "iv"), (5, "v"), (6, "vi"), (7, "vii"), (8, "viii"), (9, "ix"), (10, "x"), (14, "xiv"), (15, "xv"), (19, "xix")
        ]
        
        let formatter = RomanNumeralFormatter()
        formatter.style = .Lowercase
        for (number, numeral) in representations {
            let string = formatter.stringFromNumber(number)
            
            XCTAssertNotNil(string)
            XCTAssertEqual(string!, numeral)
        }
    }

    func testZero() {
        let formatter = RomanNumeralFormatter()
        let string = formatter.stringFromNumber(0)

        XCTAssertNil(string)
    }

}
