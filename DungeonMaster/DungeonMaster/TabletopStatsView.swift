//
//  TabletopStatsView.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/10/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

/// TabletopStatsView holds a label and health bar in a fixed size frame, rendered against a partially-transparent background.
///
/// Taps are handled by the view, set the tapHandler block to set an action.
class TabletopStatsView: UIView {
    
    /// Label to render name of item in.
    var label: UILabel!
    
    /// Progress bar may be used to render the health of the item.
    var progress: UIProgressView!

    var name: String {
        get {
            return label.text!
        }
        set(name) {
            label.text = name
        }
    }
    
    var health: Float? {
        get {
            return progress.hidden ? nil : progress.progress
        }
        set(health) {
            if let health = health {
                progress.hidden = false
                progress.progress = health
                frame.size.height = 36.0
            } else {
                progress.hidden = true
                frame.size.height = 32.0
            }
        }
    }
    
    /// Action handler for taps on the view.
    var tapHandler: (() -> Void)?
    
    init() {
        let frame = CGRect(x: 0.0, y: 0.0, width: 104.0, height: 36.0)
        super.init(frame: frame)
        
        configureView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        configureView()
    }
    
    func configureView() {
        backgroundColor = UIColor(white: 1.0, alpha: 0.8)
        layer.cornerRadius = 8.0
        opaque = false

        label = UILabel(frame: CGRect(x: 2.0, y: 2.0, width: 100.0, height: 30.0))
        label.font = UIFont.systemFontOfSize(14.0)
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 0
        label.textAlignment = .Center
        addSubview(label)
        
        progress = UIProgressView(frame: CGRect(x: 8.0, y: 32.0, width: 88.0, height: 2.0))
        progress.progressTintColor = UIColor.greenColor()
        progress.trackTintColor = UIColor.redColor()
        addSubview(progress)
    }
    
    // MARK: Touch handling.
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        backgroundColor = UIColor(white: 0.8, alpha: 0.8)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        backgroundColor = UIColor(white: 1.0, alpha: 0.8)
        if let tapHandler = tapHandler {
            tapHandler()
        }
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        backgroundColor = UIColor(white: 1.0, alpha: 0.8)
    }

}
