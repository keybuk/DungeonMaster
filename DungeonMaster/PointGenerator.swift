//
//  PointGenerator.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/16/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation
import UIKit

/// Box represents an arbitrary box of values denoted by two ranges for those values.
private struct Box<T: BidirectionalIndexType> {
    var width: Range<T>
    var height: Range<T>
}

/// Point represents a co-ordinate in an arbitrary typed space.
struct Point<T> {
    var x: T
    var y: T
}

/// PointGenerator generates a distributed set of point values in a square box of a given range.
struct PointGenerator<T: BidirectionalIndexType>: GeneratorType {
    
    typealias Element = Point<T>

    private var boxes = [Box<T>]()
    private var points = [Point<T>]()
    private var pointIndex = 0

    init(range: Range<T>) {
        boxes.append(Box<T>(width: range, height: range))
        
        points = pointsForBox(boxes[0])
        pointIndex = points.startIndex
    }
    
    private func pointsForBox(box: Box<T>, rotate: Int = 0) -> [Point<T>] {
        let centerX = box.width.startIndex.advancedBy(box.width.count / 2)
        let centerY = box.height.startIndex.advancedBy(box.height.count / 2)
        
        var points = [Point<T>]()
        points.append(Point<T>(x: box.width.startIndex, y: centerY))
        points.append(Point<T>(x: centerX, y: box.height.startIndex))
        points.append(Point<T>(x: box.width.endIndex.predecessor(), y: centerY))
        points.append(Point<T>(x: centerX, y: box.height.endIndex.predecessor()))
        
        for _ in 0..<rotate {
            points.append(points.removeFirst())
        }
        
        points.insert(Point<T>(x: centerX, y: centerY), atIndex: 0)
        
        return points
    }
    
    private func boxesForBox(box: Box<T>, rotate: Int = 0) -> [Box<T>] {
        let centerX = box.width.startIndex.advancedBy(box.width.count / 2)
        let centerY = box.height.startIndex.advancedBy(box.height.count / 2)
        
        var boxes = [Box<T>]()
        boxes.append(Box<T>(width: box.width.startIndex...centerX, height: box.height.startIndex...centerY))
        boxes.append(Box<T>(width: centerX...box.width.endIndex.predecessor(), height: box.height.startIndex...centerY))
        boxes.append(Box<T>(width: centerX...box.width.endIndex.predecessor(), height: centerY...box.height.endIndex.predecessor()))
        boxes.append(Box<T>(width: box.width.startIndex...centerX, height: centerY...box.height.endIndex.predecessor()))
        
        for _ in 0..<rotate {
            boxes.append(boxes.removeFirst())
        }
        
        return boxes
    }
    
    private mutating func splitBoxes() {
        // Split the current set of boxes, rotating each resulting set, and collate back into a single set.
        var allBoxes = [[Box<T>]]()
        for (index, box) in boxes.enumerate() {
            allBoxes.append(boxesForBox(box, rotate: index % 4))
        }
        
        boxes.removeAll()
        while allBoxes[0].count > 0 {
            var newBoxes = [[Box<T>]]()
            for var thisBoxes in allBoxes {
                boxes.append(thisBoxes.removeFirst())
                newBoxes.append(thisBoxes)
            }
            allBoxes = newBoxes
        }
        
        // Iterate the resulting new set of boxes, creating points, rotating each resulting set, and collating back into a single set of points.
        var allPoints = [[Point<T>]]()
        for (index, box) in boxes.enumerate() {
            allPoints.append(pointsForBox(box, rotate: (index / 4 + index) % 4))
        }
    
        points.removeAll()
        while allPoints[0].count > 0 {
            var newPoints = [[Point<T>]]()
            for var thisPoints in allPoints {
                points.append(thisPoints.removeFirst())
                newPoints.append(thisPoints)
            }
            allPoints = newPoints
        }
        
        // Reset the starting index, and use the points array until it's consumed again.
        pointIndex = points.startIndex
    }
    
    mutating func next() -> Point<T>? {
        if pointIndex == points.endIndex {
            splitBoxes()
        }

        let index = pointIndex
        pointIndex = pointIndex.advancedBy(1)
        return points[index]
    }
    
}