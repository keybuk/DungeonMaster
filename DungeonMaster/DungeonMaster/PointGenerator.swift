//
//  PointGenerator.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/16/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation
import CoreGraphics

/// Box represents an arbitrary box of values denoted by two intervals for those values.
private struct Box {
    var width: ClosedRange<CGFloat>
    var height: ClosedRange<CGFloat>
    
    var center: CGPoint {
        return CGPoint(x: width.lowerBound + (width.upperBound - width.lowerBound) / 2.0, y: height.lowerBound + (height.upperBound - height.lowerBound) / 2.0)
    }
}

/// PointGenerator generates a distributed set of point values in a square box of a given range.
struct PointGenerator : IteratorProtocol {
    
    typealias Element = CGPoint

    fileprivate var boxes: [Box] = []
    fileprivate var points:[CGPoint] = []
    fileprivate var pointIndex = 0

    init(range: ClosedRange<CGFloat>) {
        boxes.append(Box(width: range, height: range))
        
        points = pointsForBox(boxes[0])
        pointIndex = points.startIndex
    }
    
    init(start: CGFloat, end: CGFloat) {
        self.init(range: (start ... end))
    }
    
    fileprivate func pointsForBox(_ box: Box, rotate: Int = 0) -> [CGPoint] {
        var points: [CGPoint] = []
        points.append(CGPoint(x: box.width.lowerBound, y: box.center.y))
        points.append(CGPoint(x: box.center.x, y: box.height.lowerBound))
        points.append(CGPoint(x: box.width.upperBound, y: box.center.y))
        points.append(CGPoint(x: box.center.x, y: box.height.upperBound))
        
        for _ in 0..<rotate {
            points.append(points.removeFirst())
        }
        
        points.insert(box.center, at: 0)
        
        return points
    }
    
    fileprivate func boxesForBox(_ box: Box, rotate: Int = 0) -> [Box] {
        var boxes: [Box] = []
        boxes.append(Box(width: box.width.lowerBound...box.center.x, height: box.height.lowerBound...box.center.y))
        boxes.append(Box(width: box.center.x...box.width.upperBound, height: box.height.lowerBound...box.center.y))
        boxes.append(Box(width: box.center.x...box.width.upperBound, height: box.center.y...box.height.upperBound))
        boxes.append(Box(width: box.width.lowerBound...box.center.x, height: box.center.y...box.height.upperBound))
        
        for _ in 0..<rotate {
            boxes.append(boxes.removeFirst())
        }
        
        return boxes
    }
    
    fileprivate mutating func splitBoxes() {
        // Split the current set of boxes, rotating each resulting set, and collate back into a single set.
        var allBoxes: [[Box]] = []
        for (index, box) in boxes.enumerated() {
            allBoxes.append(boxesForBox(box, rotate: index % 4))
        }
        
        boxes.removeAll()
        while allBoxes[0].count > 0 {
            var newBoxes: [[Box]] = []
            for var thisBoxes in allBoxes {
                boxes.append(thisBoxes.removeFirst())
                newBoxes.append(thisBoxes)
            }
            allBoxes = newBoxes
        }
        
        // Iterate the resulting new set of boxes, creating points, rotating each resulting set, and collating back into a single set of points.
        var allPoints: [[CGPoint]] = []
        for (index, box) in boxes.enumerated() {
            allPoints.append(pointsForBox(box, rotate: (index / 4 + index) % 4))
        }
    
        points.removeAll()
        while allPoints[0].count > 0 {
            var newPoints: [[CGPoint]] = []
            for var thisPoints in allPoints {
                points.append(thisPoints.removeFirst())
                newPoints.append(thisPoints)
            }
            allPoints = newPoints
        }
        
        // Reset the starting index, and use the points array until it's consumed again.
        pointIndex = points.startIndex
    }
    
    mutating func next() -> CGPoint? {
        if pointIndex == points.endIndex {
            splitBoxes()
        }

        let index = pointIndex
        pointIndex = pointIndex.advanced(by: 1)
        return points[index]
    }
    
}
