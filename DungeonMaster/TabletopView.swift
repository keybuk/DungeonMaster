//
//  TabletopView.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/9/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

let π = M_PI

class TabletopView: UIView {
    
    var point = CGPoint(x: 100.0, y: 150.0)
    let radius = CGFloat(22.0)

    override init(frame: CGRect) {
        super.init(frame: frame)
        clearsContextBeforeDrawing = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        clearsContextBeforeDrawing = false
    }
    
    // MARK: Drawing
    
    override func drawRect(rect: CGRect) {
        // Drawing code
        let context = UIGraphicsGetCurrentContext()
        print("drawRect(\(rect))")
        
        let clip = CGContextGetClipBoundingBox(context)
        print(" - clip is \(clip)")
        
        CGContextSetFillColorWithColor(context, backgroundColor!.CGColor)
        CGContextFillRect(context, clip)
        
        CGContextSetStrokeColorWithColor(context, UIColor.blackColor().CGColor)
        CGContextSetLineWidth(context, 2.0)
    
        CGContextAddArc(context, point.x, point.y, radius, 0.0, CGFloat(2.0 * π), 0)
        CGContextStrokePath(context)
    }
    
    // MARK: Touch handling
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            let location = touch.locationInView(self)
        
            print("touch! \(location)")
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            let previousLocation = touch.previousLocationInView(self)
            let location = touch.locationInView(self)

            print("touch moved! \(previousLocation) -> \(location)")
            
            let fudge = CGFloat(8.0)
            
            // Distance between the touch and the point.
            let squareDistance = (previousLocation.x - point.x) * (previousLocation.x - point.x) + (previousLocation.y - point.y) * (previousLocation.y - point.y)
            let squareRadius = (radius + fudge + touch.majorRadius + touch.majorRadiusTolerance) * (radius + fudge + touch.majorRadius + touch.majorRadiusTolerance)
            
            guard squareDistance <= squareRadius else { return }
            
            let oldPoint = point
            
            point.x += location.x - previousLocation.x
            point.y += location.y - previousLocation.y

            // Now invalidate some of the area.
            let oldRect = CGRectInset(CGRect(origin: oldPoint, size: CGSizeZero), -(radius + fudge), -(radius + fudge))
            let newRect = CGRectOffset(oldRect, location.x - previousLocation.x, location.y - previousLocation.y)
            
            setNeedsDisplayInRect(CGRectUnion(oldRect, newRect))
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            let location = touch.locationInView(self)
            
            print("end touch! \(location)")

        }
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        guard touches != nil else { return }
        for touch in touches! {
            print("no more touch!")
        }
    }

}
