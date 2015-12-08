//
//  ExtendedNavigationBarView.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/6/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

/// UIView which renders with a hairline shadow along the bottom edge.
///
/// Taken from Apple sample code, should be used immediately below a Navigation Bar to create the appearance of an extended navigation bar.
@IBDesignable
class ExtendedNavigationBarView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(red: 247.0/255.0, green: 247.0/255.0, blue: 247.0/255.0, alpha: 1.0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor(red: 247.0/255.0, green: 247.0/255.0, blue: 247.0/255.0, alpha: 1.0)
    }

    override func willMoveToWindow(newWindow: UIWindow?) {
        // Use the layer shadow to draw a one pixel hairline under this view.
        layer.shadowOffset = CGSize(width: 0.0, height: 1.0/UIScreen.mainScreen().scale)
        layer.shadowRadius = 0.0
        
        // UINavigationBar's hairline is adaptive, its properties change with
        // the contents it overlies.  You may need to experiment with these
        // values to best match your content.
        layer.shadowColor = UIColor.blackColor().CGColor
        layer.shadowOpacity = 0.25
    }
    
    /// Removes the built-in background and shadow from a navigation bar, so that its appearance matches this view and appears to flow into it.
    func removeShadowFromNavigationBar(navigationBar: UINavigationBar?) {
        let rect = CGRectMake(0.0, 0.0, 1.0, 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        let color = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, rect)
        
        navigationBar?.shadowImage = UIGraphicsGetImageFromCurrentImageContext()
        
        CGContextSetFillColorWithColor(context, backgroundColor!.CGColor)
        CGContextFillRect(context, rect)
        
        navigationBar?.setBackgroundImage(UIGraphicsGetImageFromCurrentImageContext(), forBarMetrics: .Default)
        
        UIGraphicsEndImageContext()
    }
    
    /// Restores the built-in background and shadow to a navigation bar.
    func restoreShadowToNavigationBar(navigationBar: UINavigationBar?) {
        navigationBar?.shadowImage = nil
        navigationBar?.setBackgroundImage(nil, forBarMetrics: .Default)
    }
    
}
