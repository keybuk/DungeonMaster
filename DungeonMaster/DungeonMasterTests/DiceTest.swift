//
//  DiceTest.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/2/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import XCTest
@testable import DungeonMaster

class DiceTest : XCTestCase {

    func testFourSidedDie() {
        for _ in 0..<100 {
            let die = try! Die(sides: 4)
            XCTAssertGreaterThanOrEqual(die.value, 1)
            XCTAssertLessThanOrEqual(die.value, 4)
        }
    }
    
    func testSixSidedDie() {
        for _ in 0..<100 {
            let die = try! Die(sides: 6)
            XCTAssertGreaterThanOrEqual(die.value, 1)
            XCTAssertLessThanOrEqual(die.value, 6)
        }
    }

    func testEightSidedDie() {
        for _ in 0..<100 {
            let die = try! Die(sides: 8)
            XCTAssertGreaterThanOrEqual(die.value, 1)
            XCTAssertLessThanOrEqual(die.value, 8)
        }
    }

    func testTenSidedDie() {
        for _ in 0..<100 {
            let die = try! Die(sides: 10)
            XCTAssertGreaterThanOrEqual(die.value, 1)
            XCTAssertLessThanOrEqual(die.value, 10)
        }
    }
    
    func testTwelveSidedDie() {
        for _ in 0..<100 {
            let die = try! Die(sides: 12)
            XCTAssertGreaterThanOrEqual(die.value, 1)
            XCTAssertLessThanOrEqual(die.value, 12)
        }
    }

    func testTwentySidedDie() {
        for _ in 0..<100 {
            let die = try! Die(sides: 20)
            XCTAssertGreaterThanOrEqual(die.value, 1)
            XCTAssertLessThanOrEqual(die.value, 20)
        }
    }

    func testHundredSidedDie() {
        for _ in 0..<100 {
            let die = try! Die(sides: 100)
            XCTAssertGreaterThanOrEqual(die.value, 1)
            XCTAssertLessThanOrEqual(die.value, 100)
        }
    }

    func testInvalidDieSides() {
        do {
            let _ = try Die(sides: 3)
        } catch DieError.InvalidSides {
            return
        } catch {
            XCTFail("Expected DieError.InvalidSides to be thrown")
        }
        XCTFail("Expected exception to be thrown")
    }
    
    func testSimpleCombo() {
        let combo = try! DiceCombo(description: "1d4")
        XCTAssertEqual(combo.dice.count, 1)

        let dice = combo.dice[0]
        XCTAssertEqual(dice.sign, JoiningSign.None)
        XCTAssertEqual(dice.dice.count, 1)
        XCTAssertEqual(dice.dice[0].sides, 4)
        XCTAssertEqual(dice.description, "1d4")

        XCTAssertEqual(dice.value, dice.dice[0].value)
        XCTAssertEqual(combo.value, dice.value)
        
        XCTAssertEqual(dice.averageValue, 2)
        XCTAssertEqual(combo.averageValue, dice.averageValue)
        
        XCTAssertEqual(combo.description, "1d4")
    }

    func testLargeMultiplierCombo() {
        let combo = try! DiceCombo(description: "10d6")
        XCTAssertEqual(combo.dice.count, 1)

        let dice = combo.dice[0]
        XCTAssertEqual(dice.sign, JoiningSign.None)
        XCTAssertEqual(dice.dice.count, 10)

        var expectedValue = 0
        for i in 0..<10 {
            XCTAssertEqual(dice.dice[i].sides, 6)
            expectedValue += dice.dice[i].value
        }
        
        XCTAssertEqual(dice.description, "10d6")

        XCTAssertEqual(dice.value, expectedValue)
        XCTAssertEqual(combo.value, dice.value)
        
        XCTAssertEqual(dice.averageValue, 35)
        XCTAssertEqual(combo.averageValue, dice.averageValue)
        
        XCTAssertEqual(combo.description, "10d6")
    }

    func testLargeDiceCombo() {
        let combo = try! DiceCombo(description: "2d100")
        XCTAssertEqual(combo.dice.count, 1)

        let dice = combo.dice[0]
        XCTAssertEqual(dice.sign, JoiningSign.None)
        XCTAssertEqual(dice.dice.count, 2)
        
        var expectedValue = 0
        for i in 0..<2 {
            XCTAssertEqual(dice.dice[i].sides, 100)
            expectedValue += dice.dice[i].value
        }
        
        XCTAssertEqual(dice.description, "2d100")
        
        XCTAssertEqual(dice.value, expectedValue)
        XCTAssertEqual(combo.value, dice.value)
        
        XCTAssertEqual(dice.averageValue, 101)
        XCTAssertEqual(combo.averageValue, dice.averageValue)
        
        XCTAssertEqual(combo.description, "2d100")
    }

    func testLargeMultiplierAndDiceCombo() {
        let combo = try! DiceCombo(description: "20d100")
        XCTAssertEqual(combo.dice.count, 1)
        
        let dice = combo.dice[0]
        XCTAssertEqual(dice.sign, JoiningSign.None)
        XCTAssertEqual(dice.dice.count, 20)
        
        var expectedValue = 0
        for i in 0..<20 {
            XCTAssertEqual(dice.dice[i].sides, 100)
            expectedValue += dice.dice[i].value
        }
        
        XCTAssertEqual(dice.description, "20d100")
        
        XCTAssertEqual(dice.value, expectedValue)
        XCTAssertEqual(combo.value, dice.value)
        
        XCTAssertEqual(dice.averageValue, 1010)
        XCTAssertEqual(combo.averageValue, dice.averageValue)
        
        XCTAssertEqual(combo.description, "20d100")
    }

    func testComboWithModifier() {
        let combo = try! DiceCombo(description: "1d4+4")
        XCTAssertEqual(combo.dice.count, 2)
        
        let dice = combo.dice[0]
        XCTAssertEqual(dice.sign, JoiningSign.None)
        XCTAssertEqual(dice.dice.count, 1)
        XCTAssertEqual(dice.dice[0].sides, 4)
        XCTAssertEqual(dice.description, "1d4")

        XCTAssertEqual(dice.value, dice.dice[0].value)
        XCTAssertEqual(dice.averageValue, 2)

        let modifier = combo.dice[1]
        XCTAssertEqual(modifier.dice.count, 0)
        XCTAssertEqual(modifier.value, 4)
        XCTAssertEqual(modifier.sign, JoiningSign.Plus)
        XCTAssertEqual(modifier.averageValue, 4)
        XCTAssertEqual(modifier.description, "4")

        XCTAssertEqual(combo.value, dice.value + modifier.value)
        XCTAssertEqual(combo.averageValue, dice.averageValue + modifier.averageValue)
        
        XCTAssertEqual(combo.description, "1d4 + 4")
    }

    func testComboWithModifierAndSpaces() {
        let combo = try! DiceCombo(description: "1d4 + 4")
        XCTAssertEqual(combo.dice.count, 2)
        
        let dice = combo.dice[0]
        XCTAssertEqual(dice.sign, JoiningSign.None)
        XCTAssertEqual(dice.dice.count, 1)
        XCTAssertEqual(dice.dice[0].sides, 4)
        XCTAssertEqual(dice.description, "1d4")
        
        XCTAssertEqual(dice.value, dice.dice[0].value)
        XCTAssertEqual(dice.averageValue, 2)
        
        let modifier = combo.dice[1]
        XCTAssertEqual(modifier.dice.count, 0)
        XCTAssertEqual(modifier.value, 4)
        XCTAssertEqual(modifier.sign, JoiningSign.Plus)
        XCTAssertEqual(modifier.averageValue, 4)
        XCTAssertEqual(modifier.description, "4")
        
        XCTAssertEqual(combo.value, dice.value + modifier.value)
        XCTAssertEqual(combo.averageValue, dice.averageValue + modifier.averageValue)
        
        XCTAssertEqual(combo.description, "1d4 + 4")
    }

    func testComboWithNegativeModifier() {
        let combo = try! DiceCombo(description: "1d4-4")
        XCTAssertEqual(combo.dice.count, 2)
        
        let dice = combo.dice[0]
        XCTAssertEqual(dice.sign, JoiningSign.None)
        XCTAssertEqual(dice.dice.count, 1)
        XCTAssertEqual(dice.dice[0].sides, 4)
        XCTAssertEqual(dice.description, "1d4")

        XCTAssertEqual(dice.value, dice.dice[0].value)
        XCTAssertEqual(dice.averageValue, 2)

        let modifier = combo.dice[1]
        XCTAssertEqual(modifier.dice.count, 0)
        XCTAssertEqual(modifier.value, 4)
        XCTAssertEqual(modifier.sign, JoiningSign.Minus)
        XCTAssertEqual(modifier.averageValue, 4)
        XCTAssertEqual(modifier.description, "4")

        XCTAssertEqual(combo.value, dice.value - modifier.value)
        XCTAssertEqual(combo.averageValue, dice.averageValue - modifier.averageValue)
        
        XCTAssertEqual(combo.description, "1d4 - 4")
    }

    func testComboWithNegativeModifierAndSpaces() {
        let combo = try! DiceCombo(description: "1d4 - 4")
        XCTAssertEqual(combo.dice.count, 2)
        
        let dice = combo.dice[0]
        XCTAssertEqual(dice.sign, JoiningSign.None)
        XCTAssertEqual(dice.dice.count, 1)
        XCTAssertEqual(dice.dice[0].sides, 4)
        XCTAssertEqual(dice.description, "1d4")
        
        XCTAssertEqual(dice.value, dice.dice[0].value)
        XCTAssertEqual(dice.averageValue, 2)
        
        let modifier = combo.dice[1]
        XCTAssertEqual(modifier.dice.count, 0)
        XCTAssertEqual(modifier.value, 4)
        XCTAssertEqual(modifier.sign, JoiningSign.Minus)
        XCTAssertEqual(modifier.averageValue, 4)
        XCTAssertEqual(modifier.description, "4")
        
        XCTAssertEqual(combo.value, dice.value - modifier.value)
        XCTAssertEqual(combo.averageValue, dice.averageValue - modifier.averageValue)
        
        XCTAssertEqual(combo.description, "1d4 - 4")
    }

    func testComboWithZeroModifier() {
        let combo = try! DiceCombo(description: "1d20 + 0")
        XCTAssertEqual(combo.dice.count, 2)
        
        let dice = combo.dice[0]
        XCTAssertEqual(dice.sign, JoiningSign.None)
        XCTAssertEqual(dice.dice.count, 1)
        XCTAssertEqual(dice.dice[0].sides, 20)
        XCTAssertEqual(dice.description, "1d20")
        
        XCTAssertEqual(dice.value, dice.dice[0].value)
        XCTAssertEqual(dice.averageValue, 10)
        
        let modifier = combo.dice[1]
        XCTAssertEqual(modifier.dice.count, 0)
        XCTAssertEqual(modifier.value, 0)
        XCTAssertEqual(modifier.sign, JoiningSign.Plus)
        XCTAssertEqual(modifier.averageValue, 0)
        XCTAssertEqual(modifier.description, "0")
        
        XCTAssertEqual(combo.value, dice.value + modifier.value)
        XCTAssertEqual(combo.averageValue, dice.averageValue + modifier.averageValue)
        
        XCTAssertEqual(combo.description, "1d20 + 0")
    }

    func testComboWithTwoDiceSets() {
        let combo = try! DiceCombo(description: "1d4+2d6")
        XCTAssertEqual(combo.dice.count, 2)
        
        let dice1 = combo.dice[0]
        XCTAssertEqual(dice1.sign, JoiningSign.None)
        XCTAssertEqual(dice1.dice.count, 1)
        XCTAssertEqual(dice1.dice[0].sides, 4)
        XCTAssertEqual(dice1.description, "1d4")

        XCTAssertEqual(dice1.value, dice1.dice[0].value)
        XCTAssertEqual(dice1.averageValue, 2)

        let dice2 = combo.dice[1]
        XCTAssertEqual(dice2.sign, JoiningSign.Plus)
        XCTAssertEqual(dice2.dice.count, 2)
        XCTAssertEqual(dice2.dice[0].sides, 6)
        XCTAssertEqual(dice2.dice[1].sides, 6)
        XCTAssertEqual(dice2.description, "2d6")

        XCTAssertEqual(dice2.value, dice2.dice[0].value + dice2.dice[1].value)
        XCTAssertEqual(dice2.averageValue, 7)

        XCTAssertEqual(combo.value, dice1.value + dice2.value)
        XCTAssertEqual(combo.averageValue, dice1.averageValue + dice2.averageValue)
        
        XCTAssertEqual(combo.description, "1d4 + 2d6")
    }

    func testComboWithTwoDiceSetsAndSpaces() {
        let combo = try! DiceCombo(description: "1d4 + 2d6")
        XCTAssertEqual(combo.dice.count, 2)
        
        let dice1 = combo.dice[0]
        XCTAssertEqual(dice1.sign, JoiningSign.None)
        XCTAssertEqual(dice1.dice.count, 1)
        XCTAssertEqual(dice1.dice[0].sides, 4)
        XCTAssertEqual(dice1.description, "1d4")
        
        XCTAssertEqual(dice1.value, dice1.dice[0].value)
        XCTAssertEqual(dice1.averageValue, 2)
        
        let dice2 = combo.dice[1]
        XCTAssertEqual(dice2.sign, JoiningSign.Plus)
        XCTAssertEqual(dice2.dice.count, 2)
        XCTAssertEqual(dice2.dice[0].sides, 6)
        XCTAssertEqual(dice2.dice[1].sides, 6)
        XCTAssertEqual(dice2.description, "2d6")
        
        XCTAssertEqual(dice2.value, dice2.dice[0].value + dice2.dice[1].value)
        XCTAssertEqual(dice2.averageValue, 7)
        
        XCTAssertEqual(combo.value, dice1.value + dice2.value)
        XCTAssertEqual(combo.averageValue, dice1.averageValue + dice2.averageValue)
        
        XCTAssertEqual(combo.description, "1d4 + 2d6")
    }

    func testComboWithTwoDiceSetsAroundModifier() {
        let combo = try! DiceCombo(description: "1d4+1+2d6")
        XCTAssertEqual(combo.dice.count, 3)
        
        let dice1 = combo.dice[0]
        XCTAssertEqual(dice1.sign, JoiningSign.None)
        XCTAssertEqual(dice1.dice.count, 1)
        XCTAssertEqual(dice1.dice[0].sides, 4)
        XCTAssertEqual(dice1.description, "1d4")

        XCTAssertEqual(dice1.value, dice1.dice[0].value)
        XCTAssertEqual(dice1.averageValue, 2)

        let modifier = combo.dice[1]
        XCTAssertEqual(modifier.dice.count, 0)
        XCTAssertEqual(modifier.value, 1)
        XCTAssertEqual(modifier.sign, JoiningSign.Plus)
        XCTAssertEqual(modifier.averageValue, 1)
        XCTAssertEqual(modifier.description, "1")

        let dice2 = combo.dice[2]
        XCTAssertEqual(dice2.sign, JoiningSign.Plus)
        XCTAssertEqual(dice2.dice.count, 2)
        XCTAssertEqual(dice2.dice[0].sides, 6)
        XCTAssertEqual(dice2.dice[1].sides, 6)
        XCTAssertEqual(dice2.description, "2d6")

        XCTAssertEqual(dice2.value, dice2.dice[0].value + dice2.dice[1].value)
        XCTAssertEqual(dice2.averageValue, 7)

        XCTAssertEqual(combo.value, dice1.value + modifier.value + dice2.value)
        XCTAssertEqual(combo.averageValue, dice1.averageValue + modifier.averageValue + dice2.averageValue)
        
        XCTAssertEqual(combo.description, "1d4 + 1 + 2d6")
    }

    func testComboWithTwoDiceSetsAroundModifierAndSpaces() {
        let combo = try! DiceCombo(description: "1d4 + 1 + 2d6")
        XCTAssertEqual(combo.dice.count, 3)
        
        let dice1 = combo.dice[0]
        XCTAssertEqual(dice1.sign, JoiningSign.None)
        XCTAssertEqual(dice1.dice.count, 1)
        XCTAssertEqual(dice1.dice[0].sides, 4)
        XCTAssertEqual(dice1.description, "1d4")
        
        XCTAssertEqual(dice1.value, dice1.dice[0].value)
        XCTAssertEqual(dice1.averageValue, 2)
        
        let modifier = combo.dice[1]
        XCTAssertEqual(modifier.dice.count, 0)
        XCTAssertEqual(modifier.value, 1)
        XCTAssertEqual(modifier.sign, JoiningSign.Plus)
        XCTAssertEqual(modifier.averageValue, 1)
        XCTAssertEqual(modifier.description, "1")
        
        let dice2 = combo.dice[2]
        XCTAssertEqual(dice2.sign, JoiningSign.Plus)
        XCTAssertEqual(dice2.dice.count, 2)
        XCTAssertEqual(dice2.dice[0].sides, 6)
        XCTAssertEqual(dice2.dice[1].sides, 6)
        XCTAssertEqual(dice2.description, "2d6")
        
        XCTAssertEqual(dice2.value, dice2.dice[0].value + dice2.dice[1].value)
        XCTAssertEqual(dice2.averageValue, 7)
        
        XCTAssertEqual(combo.value, dice1.value + modifier.value + dice2.value)
        XCTAssertEqual(combo.averageValue, dice1.averageValue + modifier.averageValue + dice2.averageValue)
        
        XCTAssertEqual(combo.description, "1d4 + 1 + 2d6")
    }

    func testCreateJustDice() {
        let combo = try! DiceCombo(sides: 20)
        XCTAssertEqual(combo.description, "1d20")
    }
    
    func testCreateDiceAndMultiplier() {
        let combo = try! DiceCombo(multiplier: 4, sides: 6)
        XCTAssertEqual(combo.description, "4d6")
    }
    
    func testCreateDiceAndPositiveModifier() {
        let combo = try! DiceCombo(sides: 20, modifier: 3)
        XCTAssertEqual(combo.description, "1d20 + 3")
    }

    func testCreateDiceAndNegativeModifier() {
        let combo = try! DiceCombo(sides: 20, modifier: -2)
        XCTAssertEqual(combo.description, "1d20 - 2")
    }

    func testCreateDiceAndZeroModifier() {
        let combo = try! DiceCombo(sides: 20, modifier: 0)
        XCTAssertEqual(combo.description, "1d20 + 0")
    }
    
    func testCreateDiceWithAllFields() {
        let combo = try! DiceCombo(multiplier: 2, sides: 8, modifier: 5)
        XCTAssertEqual(combo.description, "2d8 + 5")
    }

    func testInvalidComboWithInvalidDice() {
        do {
            let _ = try DiceCombo(description: "1d5")
        } catch DieError.InvalidSides {
            return
        } catch {
            XCTFail("Expected DieError.InvalidSides to be thrown")
        }
        XCTFail("Expected exception to be thrown")
    }

    func testInvalidComboWithoutMultiplier() {
        do {
            let _ = try DiceCombo(description: "d4")
        } catch DieError.InvalidString {
            return
        } catch {
            XCTFail("Expected DieError.InvalidString to be thrown")
        }
        XCTFail("Expected exception to be thrown")
    }

    func testInvalidComboWithLeadingSign() {
        do {
            let _ = try DiceCombo(description: "+2d4")
        } catch DieError.InvalidString {
            return
        } catch {
            XCTFail("Expected DieError.InvalidString to be thrown")
        }
        XCTFail("Expected exception to be thrown")
    }

    func testInvalidComboWithTrailingSign() {
        do {
            let _ = try DiceCombo(description: "2d4+")
        } catch DieError.InvalidString {
            return
        } catch {
            XCTFail("Expected DieError.InvalidString to be thrown")
        }
        XCTFail("Expected exception to be thrown")
    }

    func testInvalidComboWithSillyCharacters() {
        do {
            let _ = try DiceCombo(description: "2m4")
        } catch DieError.InvalidString {
            return
        } catch {
            XCTFail("Expected DieError.InvalidString to be thrown")
        }
        XCTFail("Expected exception to be thrown")
    }

    func testInvalidComboWithMissingSign() {
        do {
            let _ = try DiceCombo(description: "2d3d4")
        } catch DieError.InvalidString {
            return
        } catch {
            XCTFail("Expected DieError.InvalidString to be thrown")
        }
        XCTFail("Expected exception to be thrown")
    }
    
    func testInvalidComboWithMultipleSigns() {
        do {
            let _ = try DiceCombo(description: "2d4+-4")
        } catch DieError.InvalidString {
            return
        } catch {
            XCTFail("Expected DieError.InvalidString to be thrown")
        }
        XCTFail("Expected exception to be thrown")
    }
    
    func testInvalidComboWithMultipleSignsAndSpaces() {
        do {
            let _ = try DiceCombo(description: "2d4 + - 4")
        } catch DieError.InvalidString {
            return
        } catch {
            XCTFail("Expected DieError.InvalidString to be thrown")
        }
        XCTFail("Expected exception to be thrown")
    }

    func testInvalidEmptyString() {
        do {
            let _ = try DiceCombo(description: "")
        } catch DieError.InvalidString {
            return
        } catch {
            XCTFail("Expected DieError.InvalidString to be thrown")
        }
        XCTFail("Expected exception to be thrown")
    }
    
    func testInvalidSpaceWithinMultiplier() {
        do {
            let _ = try DiceCombo(description: "1 2d4")
        } catch DieError.InvalidString {
            return
        } catch {
            XCTFail("Expected DieError.InvalidString to be thrown")
        }
        XCTFail("Expected exception to be thrown")
    }

    func testInvalidSpaceAfterMultiplier() {
        do {
            let _ = try DiceCombo(description: "2 d4")
        } catch DieError.InvalidString {
            return
        } catch {
            XCTFail("Expected DieError.InvalidString to be thrown")
        }
        XCTFail("Expected exception to be thrown")
    }

    func testInvalidSpaceWithinSides() {
        do {
            let _ = try DiceCombo(description: "2d1 2")
        } catch DieError.InvalidString {
            return
        } catch {
            XCTFail("Expected DieError.InvalidString to be thrown")
        }
        XCTFail("Expected exception to be thrown")
    }

    func testInvalidSpaceBeforeSides() {
        do {
            let _ = try DiceCombo(description: "2d 4")
        } catch DieError.InvalidString {
            return
        } catch {
            XCTFail("Expected DieError.InvalidString to be thrown")
        }
        XCTFail("Expected exception to be thrown")
    }

    func testInvalidSpacePrefixString() {
        do {
            let _ = try DiceCombo(description: " 2d4 + 1")
        } catch DieError.InvalidString {
            return
        } catch {
            XCTFail("Expected DieError.InvalidString to be thrown")
        }
        XCTFail("Expected exception to be thrown")
    }
    
    func testInvalidSpacePostfixString() {
        do {
            let _ = try DiceCombo(description: "2d4 + 1 ")
        } catch DieError.InvalidString {
            return
        } catch {
            XCTFail("Expected DieError.InvalidString to be thrown")
        }
        XCTFail("Expected exception to be thrown")
    }

    func testInvalidSignString() {
        do {
            let _ = try DiceCombo(description: "+")
        } catch DieError.InvalidString {
            return
        } catch {
            XCTFail("Expected DieError.InvalidString to be thrown")
        }
        XCTFail("Expected exception to be thrown")
    }

}
