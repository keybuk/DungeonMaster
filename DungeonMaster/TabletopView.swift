//
//  TabletopView.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/9/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

let π = M_PI

typealias TabletopLocation = CGPoint

@objc protocol TabletopViewDataSource {
    
    /// Returns the number of items to display on the table top.
    func numberOfItemsInTabletopView(tabletopView: TabletopView) -> Int
    
    /// Returns the location on the table top of the item with the given index.
    func tabletopView(tabletopView: TabletopView, locationForItem index: Int) -> TabletopLocation
    
    /// Returns the name of the item with the given index on the table top.
    func tabletopView(tabletopView: TabletopView, nameForItem index: Int) -> String
    
    /// Returns the health of the item with the given index on the table stop. Health should be in the range 0.0–1.0.
    func tabletopView(tabletopView: TabletopView, healthForItem index: Int) -> Float
    
}

@objc protocol TabletopViewDelegate {
    
    /// Informs the delegate that an item was moved on the table top to a new location.
    func tabletopView(tabletopView: TabletopView, moveItem index: Int, to location: TabletopLocation)
    
    /// Informs the delegate that an item was selected on the table top.
    func tabletopView(tabletopView: TabletopView, didSelectItem index: Int)

}

/// TabletopView implements a tabletop on which pieces are displayed, labelled with a name and health, and can be readily moved around by the user to match the general positions on the physical table top in front of them.
@IBDesignable class TabletopView: UIView {
    
    /// The data source provides the tabletop information about the items to be displayed.
    @IBOutlet weak var dataSource: TabletopViewDataSource?
    
    /// The delegate receives information about activity on the tabletop.
    @IBOutlet weak var delegate: TabletopViewDelegate?
    
    /// Color used for line around items on the table top.
    @IBInspectable var itemStrokeColor: UIColor = UIColor.blackColor()
    
    /// Color used to fill items on the table top.
    @IBInspectable var itemFillColor: UIColor = UIColor.whiteColor()
    
    /// Color used for line around the selected item on the table top.
    @IBInspectable var selectedItemStrokeColor: UIColor = UIColor.blackColor()
    
    /// Color used to fill the selected item on the table top.
    @IBInspectable var selectedItemFillColor: UIColor = UIColor(white: 0.8, alpha: 1.0)
    
    /// Color used for grid lines.
    @IBInspectable var gridColor: UIColor = UIColor(white: 0.0, alpha: 0.1)
    
    /// Stroke width for items on the table top.
    @IBInspectable var itemStrokeWidth: CGFloat = 2.0

    /// Radius of items shown on the table top.
    @IBInspectable var itemRadius: CGFloat = 22.0
    
    // MARK: Internal variables
    
    /// The table top is represented as a square box, centered in the middle of the view.
    var boxWidth: CGFloat = 0.0
    
    /// Center locations of each item on the table top in the range -1.0...1.0.
    var locations = [TabletopLocation]()
    
    /// Associated stats view of each item on the table top.
    var statsViews = [TabletopStatsView]()

    /// Index of item currently involved in user touch.
    var touchingIndex: Int?
    
    /// The original starting location of the item being moved by the user.
    var startingLocation: TabletopLocation?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        clearsContextBeforeDrawing = false
        contentMode = .Redraw
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        clearsContextBeforeDrawing = false
        contentMode = .Redraw
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if let window = window {
            boxWidth = max(window.screen.bounds.width, window.screen.bounds.height) / 2.0
        }
        if locations.count == 0 {
            reloadData()
        }
    }
    
    override func layoutSubviews() {
        for (index, location) in locations.enumerate() {
            let view = statsViews[index]
            let point = locationToPoint(location)
            
            view.center = CGPoint(x: point.x, y: point.y - itemRadius - 4.0 - view.frame.size.height / 2.0)
        }
        
        setNeedsDisplay()
    }

    // MARK: Data API
    
    /// Reloads the data in the view, invalidating all existing information.
    func reloadData() {
        for statsView in statsViews {
            statsView.removeFromSuperview()
        }
        
        locations.removeAll()
        statsViews.removeAll()

        touchingIndex = nil
        startingLocation = nil

        if let count = dataSource?.numberOfItemsInTabletopView(self) {
            for index in 0..<count {
                let location = dataSource!.tabletopView(self, locationForItem: index)
                let statsView = statsViewForItem(index)

                locations.append(location)
                statsViews.append(statsView)
            }
        }

        setNeedsDisplay()
        setNeedsLayout()
    }
    
    /// Inserts a new item, with the given index, onto the table top.
    func insertItemAtIndex(index: Int) {
        let location = dataSource!.tabletopView(self, locationForItem: index)
        let statsView = statsViewForItem(index)
    
        locations.insert(location, atIndex: index)
        statsViews.insert(statsView, atIndex: index)

        let count = dataSource!.numberOfItemsInTabletopView(self)
        assert(count == locations.count, "Number of items on table top didn't match that expected after insertion.")
        
        if let touchingIndex = touchingIndex {
            if touchingIndex >= index {
                self.touchingIndex = touchingIndex + 1
            }
        }
        
        setNeedsDisplayForLocation(location)
        setNeedsLayout()
    }
    
    /// Deletes an item, with the given index, and removes it from the table top.
    func deleteItemAtIndex(index: Int) {
        if let touchingIndex = touchingIndex {
            if touchingIndex > index {
                self.touchingIndex = touchingIndex - 1
            } else if touchingIndex == index {
                self.touchingIndex = nil
                startingLocation = nil
            }
        }

        let location = locations.removeAtIndex(index)
        let statsView = statsViews.removeAtIndex(index)
        
        if let count = dataSource?.numberOfItemsInTabletopView(self) {
            assert(count == locations.count, "Number of items on table top didn't match that expected after insertion.")
        }
        
        setNeedsDisplayForLocation(location)
        statsView.removeFromSuperview()
    }
    
    // MARK: Point locations.
    
    /// Returns a location on the tabletop that a new item could be placed in.
    func emptyLocationForNewItem() -> TabletopLocation? {
        var pointGenerator = PointGenerator(range: -1.0...1.0)
        while let location = pointGenerator.next() {
            // Make sure the point is within the visible bounds of the UI right now.
            let point = locationToPoint(location)
            if point.x < itemRadius || point.y < itemRadius || point.x > frame.size.width - itemRadius || point.y > frame.size.height - itemRadius {
                continue
            }
            
            // Find the closest existing item.
            var minimumDistance: CGFloat? = nil
            for otherLocation in locations {
                let otherPoint = locationToPoint(otherLocation)
                
                let squareDistance = (otherPoint.x - point.x) * (otherPoint.x - point.x) + (otherPoint.y - point.y) * (otherPoint.y - point.y)
                if minimumDistance == nil || squareDistance < minimumDistance! {
                    minimumDistance = squareDistance
                }
            }
            
            // If an item is too close, skip this point.
            let squareRadius = itemRadius * 1.5 * itemRadius * 1.5
            if minimumDistance != nil && minimumDistance! < squareRadius {
                continue
            }
            
            // This is a good point for an item.
            return location
        }
        return nil
    }

    func locationToPoint(location: TabletopLocation) -> CGPoint {
        return CGPoint(x: (frame.size.width / 2.0) + location.x * boxWidth, y: (frame.size.height / 2.0) + location.y * boxWidth)
    }
    
    func pointToLocation(point: CGPoint) -> TabletopLocation {
        return TabletopLocation(x: (point.x - frame.size.width / 2.0) / boxWidth, y: (point.y - frame.size.height / 2.0) / boxWidth)
    }
    
    func indexOfItemNearTouch(touch: UITouch) -> Int? {
        let touchLocation = touch.locationInView(self)
        for (index, location) in locations.enumerate() {
            let point = locationToPoint(location)
            let squareDistance = (touchLocation.x - point.x) * (touchLocation.x - point.x) + (touchLocation.y - point.y) * (touchLocation.y - point.y)
            let squareRadius = (itemRadius + itemStrokeWidth + touch.majorRadius + touch.majorRadiusTolerance) * (itemRadius + itemStrokeWidth + touch.majorRadius + touch.majorRadiusTolerance)
            
            if squareDistance <= squareRadius {
                return index
            }
        }
        
        return nil
    }

    // MARK: Drawing
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        CGContextSetFillColorWithColor(context, backgroundColor!.CGColor)
        CGContextFillRect(context, rect)
        
        CGContextSetStrokeColorWithColor(context, gridColor.CGColor)
        CGContextSetLineWidth(context, 1.0 / contentScaleFactor)

        let center = CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0)
        var gridLine: CGFloat = itemRadius
        while gridLine <= frame.size.width {
            CGContextMoveToPoint(context, 0.0, center.y - gridLine)
            CGContextAddLineToPoint(context, frame.size.width, center.y - gridLine)
            CGContextStrokePath(context)
            
            CGContextMoveToPoint(context, 0.0, center.y + gridLine)
            CGContextAddLineToPoint(context, frame.size.width, center.y + gridLine)
            CGContextStrokePath(context)

            CGContextMoveToPoint(context, center.x - gridLine, 0.0)
            CGContextAddLineToPoint(context, center.x - gridLine, frame.size.height)
            CGContextStrokePath(context)
            
            CGContextMoveToPoint(context, center.x + gridLine, 0.0)
            CGContextAddLineToPoint(context, center.x + gridLine, frame.size.height)
            CGContextStrokePath(context)

            gridLine += itemRadius * 2
        }
        
        
        CGContextSetLineWidth(context, itemStrokeWidth)

        for (index, location) in locations.enumerate() {
            if touchingIndex == index {
                CGContextSetStrokeColorWithColor(context, selectedItemStrokeColor.CGColor)
                CGContextSetFillColorWithColor(context, selectedItemFillColor.CGColor)
            } else {
                CGContextSetStrokeColorWithColor(context, itemStrokeColor.CGColor)
                CGContextSetFillColorWithColor(context, itemFillColor.CGColor)
            }
            
            let point = locationToPoint(location)
            CGContextAddArc(context, point.x, point.y, itemRadius, 0.0, CGFloat(2.0 * π), 0)
            CGContextFillPath(context)
            CGContextAddArc(context, point.x, point.y, itemRadius, 0.0, CGFloat(2.0 * π), 0)
            CGContextStrokePath(context)
        }
    }
    
    func setNeedsDisplayForLocation(location: TabletopLocation) {
        let point = locationToPoint(location)
        let rect = CGRectInset(CGRect(origin: point, size: CGSizeZero), -(itemRadius + itemStrokeWidth), -(itemRadius + itemStrokeWidth))
        setNeedsDisplayInRect(rect)
    }

    // MARK: Touch handling
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else { return }
        guard let index = indexOfItemNearTouch(touch) else { return }
        
        let location = locations[index]
        
        touchingIndex = index
        startingLocation = location

        setNeedsDisplayForLocation(location)
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else { return }
        guard let index = touchingIndex else { return }

        statsViews[index].hidden = true
        
        let previousTouchLocation = touch.previousLocationInView(self)
        let touchLocation = touch.locationInView(self)

        let location = locations[index]
        let point = locationToPoint(location)
        let newPoint = CGPoint(x: point.x + touchLocation.x - previousTouchLocation.x, y: point.y + touchLocation.y - previousTouchLocation.y)
        let newLocation = pointToLocation(newPoint)
    
        locations[index] = newLocation
        
        setNeedsDisplayForLocation(location)
        setNeedsDisplayForLocation(newLocation)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else { return }
        guard let index = touchingIndex else { return }
        
        touchingIndex = nil
        startingLocation = nil
        
        statsViews[index].hidden = false

        let location = locations[index]
        
        setNeedsDisplayForLocation(location)
        setNeedsLayout()

        delegate?.tabletopView(self, moveItem: index, to: location)
        
        if touch.tapCount > 0 {
            delegate?.tabletopView(self, didSelectItem: index)
        }
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        guard let index = touchingIndex else { return }
        
        let movedLocation = locations[index]
        let location = startingLocation!
        
        locations[index] = location
        
        statsViews[index].hidden = false

        touchingIndex = nil
        startingLocation = nil

        setNeedsDisplayForLocation(movedLocation)
        setNeedsDisplayForLocation(location)
        setNeedsLayout()
    }
    
    // MARK: Stats popup.
    
    func statsViewForItem(index: Int) -> TabletopStatsView {
        let name = dataSource!.tabletopView(self, nameForItem: index)
        let health = dataSource!.tabletopView(self, healthForItem: index)
        
        let view = TabletopStatsView()    
        view.label.text = name
        view.progress.progress = health
        
        view.tapHandler = {
            self.delegate?.tabletopView(self, didSelectItem: index)
        }

        self.addSubview(view)

        return view
    }
    
}
