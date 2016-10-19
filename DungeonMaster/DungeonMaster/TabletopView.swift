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
    func numberOfItemsInTabletopView(_ tabletopView: TabletopView) -> Int
    
    /// Returns the location on the table top of the item with the given index.
    func tabletopView(_ tabletopView: TabletopView, locationForItem index: Int) -> TabletopLocation
    
    /// Returns whether an item on the table top can be controlled by the DM.
    func tabletopView(_ tabletopView: TabletopView, isItemPlayerControlled index: Int) -> Bool
    
    /// Returns the name of the item with the given index on the table top.
    func tabletopView(_ tabletopView: TabletopView, nameForItem index: Int) -> String
    
    /// Returns the health of the item with the given index on the table top. Health should be in the range 0.0–1.0.
    func tabletopView(_ tabletopView: TabletopView, healthForItem index: Int) -> Float
    
}

@objc protocol TabletopViewDelegate {
    
    /// Informs the delegate that an item was moved on the table top to a new location.
    func tabletopView(_ tabletopView: TabletopView, moveItem index: Int, to location: TabletopLocation)
    
    /// Informs the delegate that an item was selected on the table top.
    func tabletopView(_ tabletopView: TabletopView, didSelectItem index: Int)

}

/// TabletopView implements a tabletop on which pieces are displayed, labelled with a name and health, and can be readily moved around by the user to match the general positions on the physical table top in front of them.
@IBDesignable class TabletopView: UIView {
    
    /// The data source provides the tabletop information about the items to be displayed.
    @IBOutlet weak var dataSource: TabletopViewDataSource?
    
    /// The delegate receives information about activity on the tabletop.
    @IBOutlet weak var delegate: TabletopViewDelegate?
    
    /// Color used for line around items on the table top.
    @IBInspectable var itemStrokeColor: UIColor = UIColor.black
    
    /// Color used to fill items on the table top.
    @IBInspectable var itemFillColor: UIColor = UIColor.white
    
    /// Color used for line around the selected item on the table top.
    @IBInspectable var selectedItemStrokeColor: UIColor = UIColor.black
    
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
    var locations: [TabletopLocation] = []
    
    /// For each item, whether or not it is played controlled.
    var playerControlled: [Bool] = []
    
    /// Associated stats view of each item on the table top.
    var statsViews: [TabletopStatsView] = []

    /// Index of item currently involved in user touch.
    var touchingIndex: Int?
    
    /// The original starting location of the item being moved by the user.
    var startingLocation: TabletopLocation?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        clearsContextBeforeDrawing = false
        contentMode = .redraw
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        clearsContextBeforeDrawing = false
        contentMode = .redraw
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
        for (index, location) in locations.enumerated() {
            let view = statsViews[index]
            let point = locationToPoint(location)
            
            view.center = CGPoint(x: point.x, y: point.y - itemRadius - 4.0 - view.bounds.size.height / 2.0)
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
        playerControlled.removeAll()

        touchingIndex = nil
        startingLocation = nil

        batchInserts = nil
        batchUpdates = nil
        batchDeletes = nil

        if let count = dataSource?.numberOfItemsInTabletopView(self) {
            for index in 0..<count {
                let playerControl = dataSource!.tabletopView(self, isItemPlayerControlled: index)
                playerControlled.append(playerControl)

                let location = dataSource!.tabletopView(self, locationForItem: index)
                locations.append(location)

                let statsView = statsViewForItem(index)
                statsViews.append(statsView)
            }
        }

        setNeedsDisplay()
        setNeedsLayout()
    }
    
    var batchInserts: NSMutableIndexSet?
    var batchDeletes: NSMutableIndexSet?
    var batchUpdates: NSMutableIndexSet?
    
    /// Begin a batch update set that processes data in the same way as a table view would.
    func beginUpdates() {
        batchInserts = NSMutableIndexSet()
        batchDeletes = NSMutableIndexSet()
        batchUpdates = NSMutableIndexSet()
    }
    
    /// Inserts a new item, with the given index, onto the table top.
    func insertItemAtIndex(_ index: Int) {
        if let batchInserts = batchInserts {
            batchInserts.add(index)
        } else {
            doInsertItemAtIndex(index)

            let count = dataSource!.numberOfItemsInTabletopView(self)
            assert(count == locations.count, "Number of items on table top didn't match that expected after insertion.")
        }
    }
    
    /// Updates an item, with the given index, refreshing its location and display.
    func updateItemAtIndex(_ index: Int) {
        if let batchUpdates = batchUpdates {
            batchUpdates.add(index)
        } else {
            doUpdateItemAtIndex(index)
            
            let count = dataSource!.numberOfItemsInTabletopView(self)
            assert(count == locations.count, "Number of items on table top didn't match that expected after update.")
        }
    }
    
    /// Deletes an item, with the given index, and removes it from the table top.
    func deleteItemAtIndex(_ index: Int) {
        if let batchDeletes = batchDeletes {
            batchDeletes.add(index)
        } else {
            doDeleteItemAtIndex(index)
            
            let count = dataSource!.numberOfItemsInTabletopView(self)
            assert(count == locations.count, "Number of items on table top didn't match that expected after deletion.")
        }
    }
    
    /// End a batch update set.
    func endUpdates() {
        for index in batchDeletes!.reversed() {
            doDeleteItemAtIndex(index)
        }
        for index in batchInserts! {
            doInsertItemAtIndex(index)
        }
        for index in batchUpdates! {
            doUpdateItemAtIndex(index)
        }
        
        let count = dataSource!.numberOfItemsInTabletopView(self)
        assert(count == locations.count, "Number of items on table top didn't match that expected after update.")

        batchInserts = nil
        batchUpdates = nil
        batchDeletes = nil
    }
    
    func doInsertItemAtIndex(_ index: Int) {
        let playerControl = dataSource!.tabletopView(self, isItemPlayerControlled: index)
        playerControlled.insert(playerControl, at: index)

        let location = dataSource!.tabletopView(self, locationForItem: index)
        let statsView = statsViewForItem(index)
    
        locations.insert(location, at: index)
        statsViews.insert(statsView, at: index)

        if let touchingIndex = touchingIndex {
            if touchingIndex >= index {
                self.touchingIndex = touchingIndex + 1
            }
        }
        
        setNeedsDisplayForLocation(location)
        setNeedsLayout()
    }
    
    func doUpdateItemAtIndex(_ index: Int) {
        let playerControl = dataSource!.tabletopView(self, isItemPlayerControlled: index)
        playerControlled[index] = playerControl

        let oldLocation = locations[index]
        let location = dataSource!.tabletopView(self, locationForItem: index)
        locations[index] = location
        
        if let touchingIndex = touchingIndex, touchingIndex == index {
            self.touchingIndex = nil
            startingLocation = nil
        }

        updateStatsForItem(index)
        
        setNeedsDisplayForLocation(oldLocation)
        setNeedsDisplayForLocation(location)
        setNeedsLayout()
    }
    
    /// Deletes an item, with the given index, and removes it from the table top.
    func doDeleteItemAtIndex(_ index: Int) {
        if let touchingIndex = touchingIndex {
            if touchingIndex > index {
                self.touchingIndex = touchingIndex - 1
            } else if touchingIndex == index {
                self.touchingIndex = nil
                startingLocation = nil
            }
        }

        let location = locations.remove(at: index)
        let statsView = statsViews.remove(at: index)
        playerControlled.remove(at: index)

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
            if let minimumDistance = minimumDistance, minimumDistance < squareRadius {
                continue
            }
            
            // This is a good point for an item.
            return location
        }
        return nil
    }

    func locationToPoint(_ location: TabletopLocation) -> CGPoint {
        return CGPoint(x: (frame.size.width / 2.0) + location.x * boxWidth, y: (frame.size.height / 2.0) + location.y * boxWidth)
    }
    
    func pointToLocation(_ point: CGPoint) -> TabletopLocation {
        return TabletopLocation(x: (point.x - frame.size.width / 2.0) / boxWidth, y: (point.y - frame.size.height / 2.0) / boxWidth)
    }
    
    func indexOfItemNearTouch(_ touch: UITouch) -> Int? {
        let touchLocation = touch.location(in: self)
        for (index, location) in locations.enumerated() {
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
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        context?.setFillColor(backgroundColor!.cgColor)
        context?.fill(rect)
        
        context?.setStrokeColor(gridColor.cgColor)
        context?.setLineWidth(1.0 / contentScaleFactor)

        let center = CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0)
        var gridLine: CGFloat = itemRadius
        while gridLine <= frame.size.width {
            context?.move(to: CGPoint(x: 0.0, y: center.y - gridLine))
            context?.addLine(to: CGPoint(x: frame.size.width, y: center.y - gridLine))
            context?.strokePath()
            
            context?.move(to: CGPoint(x: 0.0, y: center.y + gridLine))
            context?.addLine(to: CGPoint(x: frame.size.width, y: center.y + gridLine))
            context?.strokePath()

            context?.move(to: CGPoint(x: center.x - gridLine, y: 0.0))
            context?.addLine(to: CGPoint(x: center.x - gridLine, y: frame.size.height))
            context?.strokePath()
            
            context?.move(to: CGPoint(x: center.x + gridLine, y: 0.0))
            context?.addLine(to: CGPoint(x: center.x + gridLine, y: frame.size.height))
            context?.strokePath()

            gridLine += itemRadius * 2
        }
        
        
        context?.setLineWidth(itemStrokeWidth)

        for (index, location) in locations.enumerated() {
            if touchingIndex == index {
                context?.setStrokeColor(selectedItemStrokeColor.cgColor)
                context?.setFillColor(selectedItemFillColor.cgColor)
            } else {
                context?.setStrokeColor(itemStrokeColor.cgColor)
                context?.setFillColor(itemFillColor.cgColor)
            }
            
            if playerControlled[index] {
                let angle = CGFloat(π / 3.0)
                
                let point = locationToPoint(location)
                context?.move(to: CGPoint(x: point.x - itemRadius, y: point.y))
                
                context?.addLine(to: CGPoint(x: point.x - cos(angle) * itemRadius, y: point.y + sin(angle) * itemRadius))
                context?.addLine(to: CGPoint(x: point.x + cos(angle) * itemRadius, y: point.y + sin(angle) * itemRadius))
                context?.addLine(to: CGPoint(x: point.x + itemRadius, y: point.y))
                context?.addLine(to: CGPoint(x: point.x + cos(angle) * itemRadius, y: point.y - sin(angle) * itemRadius))
                context?.addLine(to: CGPoint(x: point.x - cos(angle) * itemRadius, y: point.y - sin(angle) * itemRadius))
                context?.closePath()
            } else {
                let point = locationToPoint(location)
                CGContextAddArc(context, point.x, point.y, itemRadius, 0.0, CGFloat(2.0 * π), 0)
            }

            context?.drawPath(using: .fillStroke)
        }
    }
    
    func setNeedsDisplayForLocation(_ location: TabletopLocation) {
        let point = locationToPoint(location)
        let rect = CGRect(origin: point, size: CGSize.zero).insetBy(dx: -(itemRadius + itemStrokeWidth), dy: -(itemRadius + itemStrokeWidth))
        setNeedsDisplay(rect)
    }

    // MARK: Touch handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        guard let index = indexOfItemNearTouch(touch) else { return }
        
        let location = locations[index]
        
        touchingIndex = index
        startingLocation = location

        setNeedsDisplayForLocation(location)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        guard let index = touchingIndex else { return }

        statsViews[index].isHidden = true
        
        let previousTouchLocation = touch.previousLocation(in: self)
        let touchLocation = touch.location(in: self)

        let location = locations[index]
        let point = locationToPoint(location)
        let newPoint = CGPoint(x: point.x + touchLocation.x - previousTouchLocation.x, y: point.y + touchLocation.y - previousTouchLocation.y)
        let newLocation = pointToLocation(newPoint)
    
        locations[index] = newLocation
        
        setNeedsDisplayForLocation(location)
        setNeedsDisplayForLocation(newLocation)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        guard let index = touchingIndex else { return }
        
        touchingIndex = nil
        startingLocation = nil
        
        statsViews[index].isHidden = false

        let location = locations[index]
        
        setNeedsDisplayForLocation(location)
        setNeedsLayout()

        delegate?.tabletopView(self, moveItem: index, to: location)
        
        if touch.tapCount > 0 {
            delegate?.tabletopView(self, didSelectItem: index)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let index = touchingIndex else { return }
        
        let movedLocation = locations[index]
        let location = startingLocation!
        
        locations[index] = location
        
        statsViews[index].isHidden = false

        touchingIndex = nil
        startingLocation = nil

        setNeedsDisplayForLocation(movedLocation)
        setNeedsDisplayForLocation(location)
        setNeedsLayout()
    }
    
    // MARK: Stats popup.
    
    func statsViewForItem(_ index: Int) -> TabletopStatsView {
        let view = TabletopStatsView()
        updateStatsView(view, index: index)
        
        view.tapHandler = {
            self.delegate?.tabletopView(self, didSelectItem: index)
        }

        self.addSubview(view)

        return view
    }
    
    func updateStatsForItem(_ index: Int) {
        let view = statsViews[index]
        updateStatsView(view, index: index)
    }
    
    func updateStatsView(_ view: TabletopStatsView, index: Int) {
        view.name = dataSource!.tabletopView(self, nameForItem: index)
        
        if !playerControlled[index] {
            view.health = dataSource!.tabletopView(self, healthForItem: index)
        } else {
            view.health = nil
        }
    }

}
