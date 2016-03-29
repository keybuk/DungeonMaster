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
    var width: ClosedInterval<CGFloat>
    var height: ClosedInterval<CGFloat>
    
    var center: CGPoint {
        return CGPoint(x: width.start + (width.end - width.start) / 2.0, y: height.start + (height.end - height.start) / 2.0)
    }
}

/// PointGenerator generates a distributed set of point values in a square box of a given range.
struct PointGenerator : GeneratorType {
    
    typealias Element = CGPoint

    private var boxes: [Box] = []
    private var points:[CGPoint] = []
    private var pointIndex = 0

    init(range: ClosedInterval<CGFloat>) {
        boxes.append(Box(width: range, height: range))
        
        points = pointsForBox(boxes[0])
        pointIndex = points.startIndex
    }
    
    init(start: CGFloat, end: CGFloat) {
        self.init(range: ClosedInterval<CGFloat>(start, end))
    }
    
    private func pointsForBox(box: Box, rotate: Int = 0) -> [CGPoint] {
        var points: [CGPoint] = []
        points.append(CGPoint(x: box.width.start, y: box.center.y))
        points.append(CGPoint(x: box.center.x, y: box.height.start))
        points.append(CGPoint(x: box.width.end, y: box.center.y))
        points.append(CGPoint(x: box.center.x, y: box.height.end))
        
        for _ in 0..<rotate {
            points.append(points.removeFirst())
        }
        
        points.insert(box.center, atIndex: 0)
        
        return points
    }
    
    private func boxesForBox(box: Box, rotate: Int = 0) -> [Box] {
        var boxes: [Box] = []
        boxes.append(Box(width: box.width.start...box.center.x, height: box.height.start...box.center.y))
        boxes.append(Box(width: box.center.x...box.width.end, height: box.height.start...box.center.y))
        boxes.append(Box(width: box.center.x...box.width.end, height: box.center.y...box.height.end))
        boxes.append(Box(width: box.width.start...box.center.x, height: box.center.y...box.height.end))
        
        for _ in 0..<rotate {
            boxes.append(boxes.removeFirst())
        }
        
        return boxes
    }
    
    private mutating func splitBoxes() {
        // Split the current set of boxes, rotating each resulting set, and collate back into a single set.
        var allBoxes: [[Box]] = []
        for (index, box) in boxes.enumerate() {
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
        for (index, box) in boxes.enumerate() {
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
        pointIndex = pointIndex.advancedBy(1)
        return points[index]
    }
    
}
