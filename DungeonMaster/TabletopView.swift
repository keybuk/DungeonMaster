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
    
    /// Returns the name of the item with the given index on the table top.
    func tabletopView(tabletopView: TabletopView, nameForItem index: Int) -> String
    
    /// Returns the health of the item with the given index on the table stop. Health should be in the range 0.0–1.0.
    func tabletopView(tabletopView: TabletopView, healthForItem index: Int) -> Float
    
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
    
    var points = [CGPoint]()
    var statsViews = [TabletopStatsPopupView]()

    var touching: Int?
    var startingPoint: CGPoint?
    
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
        for statsView in statsViews {
            statsView.removeFromSuperview()
        }
        
        points.removeAll()
        statsViews.removeAll()

        touching = nil
        startingPoint = nil

        if let count = dataSource?.numberOfItemsInTabletopView(self) {
            for index in 0..<count {
                let point = dataSource!.tabletopView(self, pointForItem: index)
                let statsView = statsViewForItem(index)

                points.append(point)
                statsViews.append(statsView)
                
                showStatsViewForItem(index, at: point)
            }
        }

        setNeedsDisplay()
    }
    
    /// Inserts a new item, with the given index, onto the table top.
    func insertItemAtIndex(index: Int) {
        let point = dataSource!.tabletopView(self, pointForItem: index)
        let statsView = statsViewForItem(index)
    
        points.insert(point, atIndex: index)
        statsViews.insert(statsView, atIndex: index)

        let count = dataSource!.numberOfItemsInTabletopView(self)
        assert(count == points.count, "Number of items on table top didn't match that expected after insertion.")
        
        if let touchIndex = touching {
            if touchIndex >= index {
                touching = touchIndex + 1
            }
        }
        
        setNeedsDisplayForPoint(point)
        showStatsViewForItem(index, at: point)
    }
    
    /// Deletes an item, with the given index, and removes it from the table top.
    func deleteItemAtIndex(index: Int) {
        if let touchIndex = touching {
            if touchIndex > index {
                touching = touchIndex - 1
            } else if touchIndex == index {
                touching = nil
                startingPoint = nil
            }
        }

        let point = points.removeAtIndex(index)
        let statsView = statsViews.removeAtIndex(index)
        
        if let count = dataSource?.numberOfItemsInTabletopView(self) {
            assert(count == points.count, "Number of items on table top didn't match that expected after insertion.")
        }
        
        setNeedsDisplayForPoint(point)
        statsView.removeFromSuperview()
    }
    
    // MARK: Housekeeping
    
    func indexOfPointNearLocation(location: CGPoint, radius touchRadius: CGFloat) -> Int? {
        for (index, point) in points.enumerate() {
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
            if touching == index {
                CGContextSetFillColorWithColor(context, UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0).CGColor)
            } else {
                CGContextSetFillColorWithColor(context, backgroundColor!.CGColor)
            }
            
            CGContextAddArc(context, point.x, point.y, radius, 0.0, CGFloat(2.0 * π), 0)
            CGContextFillPath(context)
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
        
        let point = points[index]
        
        touching = index
        startingPoint = point

        setNeedsDisplayForPoint(point)
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else { return }
        guard let index = touching else { return }

        statsViews[index].removeFromSuperview()
        
        let previousLocation = touch.previousLocationInView(self)
        let location = touch.locationInView(self)

        let point = points[index]
        points[index] = CGPoint(x: point.x + location.x - previousLocation.x, y: point.y + location.y - previousLocation.y)

        setNeedsDisplayForPoint(point)
        setNeedsDisplayForPoint(points[index])
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else { return }
        guard let index = touching else { return }
        
        touching = nil
        startingPoint = nil
        
        let point = points[index]
        
        showStatsViewForItem(index, at: point)
        setNeedsDisplayForPoint(point)
        
        delegate?.tabletopView(self, moveItem: index, to: point)
        
        if touch.tapCount > 0 {
            delegate?.tabletopView(self, didSelectItem: index)
        }
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        guard let index = touching else { return }
        
        let movedPoint = points[index]
        let point = startingPoint!
        
        points[index] = point
        
        touching = nil
        startingPoint = nil

        setNeedsDisplayForPoint(movedPoint)
        setNeedsDisplayForPoint(point)

        showStatsViewForItem(index, at: point)
    }
    
    // MARK: Stats popup.
    
    func statsViewForItem(index: Int) -> TabletopStatsPopupView {
        let name = dataSource!.tabletopView(self, nameForItem: index)
        let health = dataSource!.tabletopView(self, healthForItem: index)
        
        let view = TabletopStatsPopupView()
        view.label.text = name
        view.progress.progress = health
        
        view.tapHandler = {
            self.delegate?.tabletopView(self, didSelectItem: index)
        }

        return view
    }
    
    func showStatsViewForItem(index: Int, at point: CGPoint) {
        let view = statsViews[index]
        
        view.center = CGPoint(x: point.x, y: point.y - radius - 2.0 - view.frame.size.height / 2.0)
            
        self.addSubview(view)
    }
    
}
