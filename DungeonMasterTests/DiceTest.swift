//
//  DiceTest.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/2/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import XCTest
@testable import DungeonMaster

class DiceTest: XCTestCase {

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
        XCTAssertEqual(combo.values.count, 1)

        XCTAssertTrue(combo.values[0] is Dice, "Expected dice")

        let dice = combo.values[0] as! Dice
        XCTAssertEqual(dice.sign, JoiningSign.None)
        XCTAssertEqual(dice.values.count, 1)
        XCTAssertEqual(dice.values[0].sides, 4)
        
        XCTAssertEqual(dice.value, dice.values[0].value)
        XCTAssertEqual(combo.value, dice.value)
        
        XCTAssertEqual(dice.averageValue, 2)
        XCTAssertEqual(combo.averageValue, dice.averageValue)
    }

    func testLargeMultiplierCombo() {
        let combo = try! DiceCombo(description: "10d6")
        XCTAssertEqual(combo.values.count, 1)

        XCTAssertTrue(combo.values[0] is Dice, "Expected dice")

        let dice = combo.values[0] as! Dice
        XCTAssertEqual(dice.sign, JoiningSign.None)
        XCTAssertEqual(dice.values.count, 10)

        var expectedValue = 0
        for i in 0..<10 {
            XCTAssertEqual(dice.values[i].sides, 6)
            expectedValue += dice.values[i].value
        }
        
        XCTAssertEqual(dice.value, expectedValue)
        XCTAssertEqual(combo.value, dice.value)
        
        XCTAssertEqual(dice.averageValue, 35)
        XCTAssertEqual(combo.averageValue, dice.averageValue)
    }

    func testLargeDiceCombo() {
        let combo = try! DiceCombo(description: "2d100")
        XCTAssertEqual(combo.values.count, 1)
        
        XCTAssertTrue(combo.values[0] is Dice, "Expected dice")
        
        let dice = combo.values[0] as! Dice
        XCTAssertEqual(dice.sign, JoiningSign.None)
        XCTAssertEqual(dice.values.count, 2)
        
        var expectedValue = 0
        for i in 0..<2 {
            XCTAssertEqual(dice.values[i].sides, 100)
            expectedValue += dice.values[i].value
        }
        
        XCTAssertEqual(dice.value, expectedValue)
        XCTAssertEqual(combo.value, dice.value)
        
        XCTAssertEqual(dice.averageValue, 101)
        XCTAssertEqual(combo.averageValue, dice.averageValue)
    }

    func testLargeMultiplierAndDiceCombo() {
        let combo = try! DiceCombo(description: "20d100")
        XCTAssertEqual(combo.values.count, 1)
        
        XCTAssertTrue(combo.values[0] is Dice, "Expected dice")
        
        let dice = combo.values[0] as! Dice
        XCTAssertEqual(dice.sign, JoiningSign.None)
        XCTAssertEqual(dice.values.count, 20)
        
        var expectedValue = 0
        for i in 0..<20 {
            XCTAssertEqual(dice.values[i].sides, 100)
            expectedValue += dice.values[i].value
        }
        
        XCTAssertEqual(dice.value, expectedValue)
        XCTAssertEqual(combo.value, dice.value)
        
        XCTAssertEqual(dice.averageValue, 1010)
        XCTAssertEqual(combo.averageValue, dice.averageValue)
    }

    func testComboWithModifier() {
        let combo = try! DiceCombo(description: "1d4 + 4")
        XCTAssertEqual(combo.values.count, 2)
        
        let dice = combo.values[0]
        XCTAssertEqual(dice.sign, JoiningSign.None)
        XCTAssertEqual(dice.values.count, 1)
        XCTAssertEqual(dice.values[0].sides, 4)
        
        XCTAssertEqual(dice.value, dice.values[0].value)
        XCTAssertEqual(dice.averageValue, 2)

        let modifier = combo.values[1]
        XCTAssertEqual(modifier.values.count, 0)
        XCTAssertEqual(modifier.value, 4)
        XCTAssertEqual(modifier.sign, JoiningSign.Plus)
        XCTAssertEqual(modifier.averageValue, 4)

        XCTAssertEqual(combo.value, dice.value + modifier.value)
        XCTAssertEqual(combo.averageValue, dice.averageValue + modifier.averageValue)
    }

    func testComboWithModifierWithoutSpaces() {
        let combo = try! DiceCombo(description: "1d4+4")
        XCTAssertEqual(combo.values.count, 2)
        
        let dice = combo.values[0]
        XCTAssertEqual(dice.sign, JoiningSign.None)
        XCTAssertEqual(dice.values.count, 1)
        XCTAssertEqual(dice.values[0].sides, 4)
        
        XCTAssertEqual(dice.value, dice.values[0].value)
        XCTAssertEqual(dice.averageValue, 2)

        let modifier = combo.values[1]
        XCTAssertEqual(modifier.values.count, 0)
        XCTAssertEqual(modifier.value, 4)
        XCTAssertEqual(modifier.sign, JoiningSign.Plus)
        XCTAssertEqual(modifier.averageValue, 4)

        XCTAssertEqual(combo.value, dice.value + modifier.value)
        XCTAssertEqual(combo.averageValue, dice.averageValue + modifier.averageValue)
    }

    func testComboWithNegativeModifier() {
        let combo = try! DiceCombo(description: "1d4 - 4")
        XCTAssertEqual(combo.values.count, 2)
        
        let dice = combo.values[0]
        XCTAssertEqual(dice.sign, JoiningSign.None)
        XCTAssertEqual(dice.values.count, 1)
        XCTAssertEqual(dice.values[0].sides, 4)
        
        XCTAssertEqual(dice.value, dice.values[0].value)
        XCTAssertEqual(dice.averageValue, 2)

        let modifier = combo.values[1]
        XCTAssertEqual(modifier.values.count, 0)
        XCTAssertEqual(modifier.value, 4)
        XCTAssertEqual(modifier.sign, JoiningSign.Minus)
        XCTAssertEqual(modifier.averageValue, 4)

        XCTAssertEqual(combo.value, dice.value - modifier.value)
        XCTAssertEqual(combo.averageValue, dice.averageValue - modifier.averageValue)
    }

    func testComboWithTwoDiceSets() {
        let combo = try! DiceCombo(description: "1d4 + 2d6")
        XCTAssertEqual(combo.values.count, 2)
        
        let dice1 = combo.values[0]
        XCTAssertEqual(dice1.sign, JoiningSign.None)
        XCTAssertEqual(dice1.values.count, 1)
        XCTAssertEqual(dice1.values[0].sides, 4)
        
        XCTAssertEqual(dice1.value, dice1.values[0].value)
        XCTAssertEqual(dice1.averageValue, 2)

        let dice2 = combo.values[1]
        XCTAssertEqual(dice2.sign, JoiningSign.Plus)
        XCTAssertEqual(dice2.values.count, 2)
        XCTAssertEqual(dice2.values[0].sides, 6)
        XCTAssertEqual(dice2.values[1].sides, 6)

        XCTAssertEqual(dice2.value, dice2.values[0].value + dice2.values[1].value)
        XCTAssertEqual(dice2.averageValue, 7)

        XCTAssertEqual(combo.value, dice1.value + dice2.value)
        XCTAssertEqual(combo.averageValue, dice1.averageValue + dice2.averageValue)
    }

    func testComboWithTwoDiceSetsAroundModifier() {
        let combo = try! DiceCombo(description: "1d4 + 1 + 2d6")
        XCTAssertEqual(combo.values.count, 3)
        
        let dice1 = combo.values[0]
        XCTAssertEqual(dice1.sign, JoiningSign.None)
        XCTAssertEqual(dice1.values.count, 1)
        XCTAssertEqual(dice1.values[0].sides, 4)
        
        XCTAssertEqual(dice1.value, dice1.values[0].value)
        XCTAssertEqual(dice1.averageValue, 2)

        let modifier = combo.values[1]
        XCTAssertEqual(modifier.values.count, 0)
        XCTAssertEqual(modifier.value, 1)
        XCTAssertEqual(modifier.sign, JoiningSign.Plus)
        XCTAssertEqual(modifier.averageValue, 1)

        XCTAssertTrue(combo.values[2] is Dice, "Expected dice")
        
        let dice2 = combo.values[2]
        XCTAssertEqual(dice2.sign, JoiningSign.Plus)
        XCTAssertEqual(dice2.values.count, 2)
        XCTAssertEqual(dice2.values[0].sides, 6)
        XCTAssertEqual(dice2.values[1].sides, 6)
        
        XCTAssertEqual(dice2.value, dice2.values[0].value + dice2.values[1].value)
        XCTAssertEqual(dice2.averageValue, 7)

        XCTAssertEqual(combo.value, dice1.value + modifier.value + dice2.value)
        XCTAssertEqual(combo.averageValue, dice1.averageValue + modifier.averageValue + dice2.averageValue)
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
            let _ = try DiceCombo(description: "+ 2d4")
        } catch DieError.InvalidString {
            return
        } catch {
            XCTFail("Expected DieError.InvalidString to be thrown")
        }
        XCTFail("Expected exception to be thrown")
    }

    func testInvalidComboWithTrailingSign() {
        do {
            let _ = try DiceCombo(description: "2d4 +")
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

    func testInvalidComboWithMissingSignBetweenDice() {
        do {
            let _ = try DiceCombo(description: "2d4 3d4")
        } catch DieError.InvalidString {
            return
        } catch {
            XCTFail("Expected DieError.InvalidString to be thrown")
        }
        XCTFail("Expected exception to be thrown")
    }
    
    func testInvalidComboWithMissingSignBetweenMultipliers() {
        do {
            let _ = try DiceCombo(description: "5 10")
        } catch DieError.InvalidString {
            return
        } catch {
            XCTFail("Expected DieError.InvalidString to be thrown")
        }
        XCTFail("Expected exception to be thrown")
    }

    func testInvalidComboWithMultipleSigns() {
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
    
    func testInvalidSpaceString() {
        do {
            let _ = try DiceCombo(description: " ")
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
