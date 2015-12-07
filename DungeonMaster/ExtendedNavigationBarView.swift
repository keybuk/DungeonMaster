//
//  ExtendedNavigationBarView.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/6/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

class ExtendedNavigationBarView: UIView {

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
    
}
