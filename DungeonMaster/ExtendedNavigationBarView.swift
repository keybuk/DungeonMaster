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

    /// Navigation bar that this extension should be attached to.
    var navigationBar: UINavigationBar?
    
    /// Scroll view which should have its insets adjusted.
    var scrollView: UIScrollView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(white: 247.0/255.0, alpha: 1.0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor(white: 247.0/255.0, alpha: 1.0)
    }

    override func willMoveToWindow(newWindow: UIWindow?) {
        super.willMoveToWindow(newWindow)
        
        configureLayer()
        
        if let _ = newWindow {
            removeShadowFromNavigationBar()
        } else {
            restoreShadowToNavigationBar()
        }
    }
    
    func configureLayer() {
        // Use the layer shadow to draw a one pixel hairline under this view.
        layer.shadowOffset = CGSize(width: 0.0, height: 1.0/UIScreen.mainScreen().scale)
        layer.shadowRadius = 0.0
        
        // UINavigationBar's hairline is adaptive, its properties change with
        // the contents it overlies.  You may need to experiment with these
        // values to best match your content.
        layer.shadowColor = UIColor.blackColor().CGColor
        layer.shadowOpacity = 0.25
    }
    
    func removeShadowFromNavigationBar() {
        guard let navigationBar = navigationBar else { return }

        navigationBar.translucent = false

        // Create a transparent image and assign it to the navigation bar's shadow image.
        let rect = CGRectMake(0.0, 0.0, 1.0, 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        let color = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, rect)
        
        navigationBar.shadowImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // Re-fill it with the background color and assign it to the navigation bar's background image.
        CGContextSetFillColorWithColor(context, backgroundColor!.CGColor)
        CGContextFillRect(context, rect)
        
        navigationBar.setBackgroundImage(UIGraphicsGetImageFromCurrentImageContext(), forBarMetrics: .Default)
        
        UIGraphicsEndImageContext()
    }
    
    func restoreShadowToNavigationBar() {
        guard let navigationBar = navigationBar else { return }

        navigationBar.translucent = true
        navigationBar.shadowImage = nil
        navigationBar.setBackgroundImage(nil, forBarMetrics: .Default)
    }

    var contentInsetAdjusted = false

    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Adjust the insets of the related scroll view to include the height of the extension.
        guard let scrollView = scrollView else { return }
        let oldContentOffset = scrollView.contentOffset
        if hidden {
            if contentInsetAdjusted {
                scrollView.contentInset.top -= bounds.size.height
                if oldContentOffset == scrollView.contentOffset {
                    scrollView.contentOffset.y += bounds.size.height
                }
                contentInsetAdjusted = false
            }
        } else {
            if !contentInsetAdjusted {
                scrollView.contentInset.top += bounds.size.height
                if oldContentOffset == scrollView.contentOffset {
                    scrollView.contentOffset.y -= bounds.size.height
                }
                contentInsetAdjusted = true
            }
        }
    }
    
    override var hidden: Bool {
        get {
            return super.hidden
        }
        set(newHidden) {
            let oldHidden = super.hidden
            super.hidden = newHidden

            setNeedsLayout()
            if newHidden && !oldHidden {
                restoreShadowToNavigationBar()
            } else if !newHidden && oldHidden {
                removeShadowFromNavigationBar()
            }
        }
    }
    
}
