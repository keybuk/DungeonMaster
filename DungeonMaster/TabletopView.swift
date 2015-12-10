//
//  TabletopView.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/9/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

let π = M_PI

@objc protocol TabletopViewDataSource {
    
    /// Returns the number of items to display on the table top.
    func numberOfItemsInTabletopView(tabletopView: TabletopView) -> Int
    
    /// Returns the location on the table top of the item with the given index.
    func tabletopView(tabletopView: TabletopView, pointForItem index: Int) -> CGPoint
    
}

@objc protocol TabletopViewDelegate {
    
    /// Informs the delegate that an item was moved on the table top to a new location.
    func tabletopView(tabletopView: TabletopView, moveItem index: Int, to point: CGPoint)

    /// Informs the delegate that an item was selected on the table top.
    func tabletopView(tabletopView: TabletopView, didSelectItem index: Int)

}

@IBDesignable class TabletopView: UIView {
    
    @IBOutlet weak var dataSource: TabletopViewDataSource?
    @IBOutlet weak var delegate: TabletopViewDelegate?
    
    let radius = CGFloat(22.0)
    let fudge = CGFloat(8.0)
    
    var points = [CGPoint?]()

    var touching: Int?
    var startingPoint: CGPoint?
    var delayedTap: dispatch_block_t?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        clearsContextBeforeDrawing = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        clearsContextBeforeDrawing = false
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if points.count == 0 {
            reloadData()
        }
    }

    // MARK: Data API
    
    /// Reloads the data in the view, invalidating all existing information.
    func reloadData() {
        // TODO there might be in-progress touches
        
        if let count = dataSource?.numberOfItemsInTabletopView(self) {
            points = [CGPoint?](count: count, repeatedValue: nil)
        } else {
            points.removeAll()
        }
        
        touching = nil
        startingPoint = nil

        setNeedsDisplay()
    }
    
    /// Inserts a new item, with the given index, onto the table top.
    func insertItemAtIndex(index: Int) {
        points.insert(nil, atIndex: index)

        if let count = dataSource?.numberOfItemsInTabletopView(self) {
            assert(count == points.count, "Number of items on table top didn't match that expected after insertion.")
        }
        
        if let touchIndex = touching {
            if touchIndex >= index {
                touching = touchIndex + 1
            }
        }
    }
    
    /// Deletes an item, with the given index, and removes it from the table top.
    func deleteItemAtIndex(index: Int) {
        if let touchIndex = touching {
            if touchIndex > index {
                touching = touchIndex - 1
            } else if touchIndex == index {
                guard let point = points[index] else { abort() }
                setNeedsDisplayForPoint(point)
                
                touching = nil
                startingPoint = nil
            }
        }

        points.removeAtIndex(index)
        
        if let count = dataSource?.numberOfItemsInTabletopView(self) {
            assert(count == points.count, "Number of items on table top didn't match that expected after insertion.")
        }
    }
    
    // MARK: Housekeeping
    
    func updatePoint(index: Int) -> CGPoint? {
        let point = dataSource?.tabletopView(self, pointForItem: index)
        points[index] = point
        return point
    }
    
    func indexOfPointNearLocation(location: CGPoint, radius touchRadius: CGFloat) -> Int? {
        for (index, point) in points.enumerate() {
            guard let point = point ?? updatePoint(index) else { continue }
            
            let squareDistance = (location.x - point.x) * (location.x - point.x) + (location.y - point.y) * (location.y - point.y)
            let squareRadius = (radius + fudge + touchRadius) * (radius + fudge + touchRadius)
            
            if squareDistance <= squareRadius {
                return index
            }
        }
        
        return nil
    }

    // MARK: Drawing
    
    override func drawRect(rect: CGRect) {
        // Drawing code
        let context = UIGraphicsGetCurrentContext()
        
        CGContextSetFillColorWithColor(context, backgroundColor!.CGColor)
        CGContextFillRect(context, rect)
        
        CGContextSetStrokeColorWithColor(context, UIColor.blackColor().CGColor)
        CGContextSetLineWidth(context, 2.0)
        
        for (index, point) in points.enumerate() {
            guard let point = point ?? updatePoint(index) else { continue }

            CGContextAddArc(context, point.x, point.y, radius, 0.0, CGFloat(2.0 * π), 0)
            CGContextStrokePath(context)
        }
    }
    
    func setNeedsDisplayForPoint(point: CGPoint) {
        let rect = CGRectInset(CGRect(origin: point, size: CGSizeZero), -(radius + fudge), -(radius + fudge))
        setNeedsDisplayInRect(rect)
    }

    // MARK: Touch handling
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else { return }
        guard let index = indexOfPointNearLocation(touch.locationInView(self), radius: touch.majorRadius + touch.majorRadiusTolerance) else { return }
        guard let point = points[index] else { abort() }
        
        touching = index
        startingPoint = point
        
        if let block = delayedTap {
            dispatch_block_cancel(block)
            delayedTap = nil
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else { return }
        guard let index = touching else { return }
        guard let point = points[index] else { abort() }

        let previousLocation = touch.previousLocationInView(self)
        let location = touch.locationInView(self)

        points[index] = CGPoint(x: point.x + location.x - previousLocation.x, y: point.y + location.y - previousLocation.y)

        setNeedsDisplayForPoint(point)
        setNeedsDisplayForPoint(points[index]!)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else { return }
        guard let index = touching else { return }
        guard let point = points[index] else { abort() }

        if touch.tapCount == 1 {
            delayedTap = dispatch_block_create(DISPATCH_BLOCK_ASSIGN_CURRENT) {
                print("Tapped \(index)")
                self.delayedTap = nil
            }
                
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 300_000_000), dispatch_get_main_queue(), delayedTap!)
        } else if touch.tapCount == 2 {
            delegate?.tabletopView(self, didSelectItem: index)
        }

        touching = nil
        startingPoint = nil
            
        delegate?.tabletopView(self, moveItem: index, to: point)
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        guard let index = touching else { return }
        guard let point = points[index] else { abort() }
            
        points[index] = startingPoint!

        touching = nil
        startingPoint = nil

        setNeedsDisplayForPoint(point)
        setNeedsDisplayForPoint(points[index]!)
    }

}
