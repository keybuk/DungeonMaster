//
//  PointGeneratorTest.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/16/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import XCTest
@testable import DungeonMaster

class PointGeneratorTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testFirstBoxCenter() {
        // First point belongs in the center.
        var pg = PointGenerator<Int>(range: -4...4)
        let point = pg.next()
        
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 0)
        XCTAssertEqual(point!.y, 0)
    }

    func testFirstBoxSides() {
        // The next four points after the first should be the four sides of the first box.
        var pg = PointGenerator<Int>(range: -4...4)
        var point = pg.next()
        
        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -4)
        XCTAssertEqual(point!.y, 0)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 0)
        XCTAssertEqual(point!.y, -4)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 4)
        XCTAssertEqual(point!.y, 0)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 0)
        XCTAssertEqual(point!.y, 4)
    }
    
    func testSplitBoxCenters() {
        // The next four points after the first box should be the centers of the four boxes split from it.
        var pg = PointGenerator<Int>(range: -4...4)
        var point: Point<Int>?
        for _ in 0..<5 {
            point = pg.next()
        }
        
        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -2)
        XCTAssertEqual(point!.y, -2)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 2)
        XCTAssertEqual(point!.y, -2)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 2)
        XCTAssertEqual(point!.y, 2)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -2)
        XCTAssertEqual(point!.y, 2)
    }
    
    func testSplitBoxSides() {
        // With the centers of the split boxes out of the way, the edges of those boxes should be enumerated.
        var pg = PointGenerator<Int>(range: -4...4)
        var point: Point<Int>?
        for _ in 0..<9 {
            point = pg.next()
        }

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -4)
        XCTAssertEqual(point!.y, -2)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 2)
        XCTAssertEqual(point!.y, -4)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 4)
        XCTAssertEqual(point!.y, 2)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -2)
        XCTAssertEqual(point!.y, 4)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -2)
        XCTAssertEqual(point!.y, -4)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 4)
        XCTAssertEqual(point!.y, -2)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 2)
        XCTAssertEqual(point!.y, 4)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -4)
        XCTAssertEqual(point!.y, 2)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 0)
        XCTAssertEqual(point!.y, -2)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 2)
        XCTAssertEqual(point!.y, 0)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 0)
        XCTAssertEqual(point!.y, 2)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -2)
        XCTAssertEqual(point!.y, 0)

        // Last set of points is duplicated
        
        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -2)
        XCTAssertEqual(point!.y, -0)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 0)
        XCTAssertEqual(point!.y, -2)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 2)
        XCTAssertEqual(point!.y, 0)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 0)
        XCTAssertEqual(point!.y, 2)
    }
    
    func testSecondSplitBoxCenters() {
        // After the second round of splits, there should be sixteen boxes, and thus sixteen centers.
        var pg = PointGenerator<Int>(range: -4...4)
        var point: Point<Int>?
        for _ in 0..<25 {
            point = pg.next()
        }
        
        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -3)
        XCTAssertEqual(point!.y, -3)
        
        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 3)
        XCTAssertEqual(point!.y, -3)
        
        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 3)
        XCTAssertEqual(point!.y, 3)
        
        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -3)
        XCTAssertEqual(point!.y, 3)
        
        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -1)
        XCTAssertEqual(point!.y, -3)
        
        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 3)
        XCTAssertEqual(point!.y, -1)
        
        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 1)
        XCTAssertEqual(point!.y, 3)
        
        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -3)
        XCTAssertEqual(point!.y, 1)
        
        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -1)
        XCTAssertEqual(point!.y, -1)
        
        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 1)
        XCTAssertEqual(point!.y, -1)
        
        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 1)
        XCTAssertEqual(point!.y, 1)
        
        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -1)
        XCTAssertEqual(point!.y, 1)
        
        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -3)
        XCTAssertEqual(point!.y, -1)
        
        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 1)
        XCTAssertEqual(point!.y, -3)
        
        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 3)
        XCTAssertEqual(point!.y, 1)
        
        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -1)
        XCTAssertEqual(point!.y, 3)
    }

    func testSecondSplitBoxSides() {
        // Now the exhaustive list of sides for after the second round of splits, with each box, and side, rotated around.
        var pg = PointGenerator<Int>(range: -4...4)
        var point: Point<Int>?
        for _ in 0..<41 {
            point = pg.next()
        }

        // point 1 for each box
        
        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -4)
        XCTAssertEqual(point!.y, -3)
        
        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 3)
        XCTAssertEqual(point!.y, -4)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 4)
        XCTAssertEqual(point!.y, 3)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -3)
        XCTAssertEqual(point!.y, 4)
        
        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -1)
        XCTAssertEqual(point!.y, -4)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 4)
        XCTAssertEqual(point!.y, -1)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 1)
        XCTAssertEqual(point!.y, 4)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -4)
        XCTAssertEqual(point!.y, 1)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 0)
        XCTAssertEqual(point!.y, -1)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 1)
        XCTAssertEqual(point!.y, 0)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 0)
        XCTAssertEqual(point!.y, 1)
        
        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -1)
        XCTAssertEqual(point!.y, 0)
        
        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -3)
        XCTAssertEqual(point!.y, 0)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 0)
        XCTAssertEqual(point!.y, -3)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 3)
        XCTAssertEqual(point!.y, 0)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 0)
        XCTAssertEqual(point!.y, 3)

        // point 2 for each box
        
        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -3)
        XCTAssertEqual(point!.y, -4)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 4)
        XCTAssertEqual(point!.y, -3)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 3)
        XCTAssertEqual(point!.y, 4)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -4)
        XCTAssertEqual(point!.y, 3)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 0)
        XCTAssertEqual(point!.y, -3)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 3)
        XCTAssertEqual(point!.y, 0)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 0)
        XCTAssertEqual(point!.y, 3)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -3)
        XCTAssertEqual(point!.y, 0)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -1)
        XCTAssertEqual(point!.y, 0)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 0)
        XCTAssertEqual(point!.y, -1)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 1)
        XCTAssertEqual(point!.y, 0)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 0)
        XCTAssertEqual(point!.y, 1)
        
        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -4)
        XCTAssertEqual(point!.y, -1)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 1)
        XCTAssertEqual(point!.y, -4)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 4)
        XCTAssertEqual(point!.y, 1)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -1)
        XCTAssertEqual(point!.y, 4)

        // point 3 for each box
        
        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -2)
        XCTAssertEqual(point!.y, -3)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 3)
        XCTAssertEqual(point!.y, -2)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 2)
        XCTAssertEqual(point!.y, 3)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -3)
        XCTAssertEqual(point!.y, 2)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -1)
        XCTAssertEqual(point!.y, -2)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 2)
        XCTAssertEqual(point!.y, -1)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 1)
        XCTAssertEqual(point!.y, 2)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -2)
        XCTAssertEqual(point!.y, 1)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -2)
        XCTAssertEqual(point!.y, -1)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 1)
        XCTAssertEqual(point!.y, -2)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 2)
        XCTAssertEqual(point!.y, 1)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -1)
        XCTAssertEqual(point!.y, 2)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -3)
        XCTAssertEqual(point!.y, -2)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 2)
        XCTAssertEqual(point!.y, -3)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, 3)
        XCTAssertEqual(point!.y, 2)

        point = pg.next()
        XCTAssertNotNil(point)
        XCTAssertEqual(point!.x, -2)
        XCTAssertEqual(point!.y, 3)

        // point 4 for each box are all duplicates...
    }
}
