//
//  TabletopStatsPopupView.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/10/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

class TabletopStatsPopupView: UIView {
    
    var point: CGPoint

    var label: UILabel!
    var progress: UIProgressView!
    
    var tapHandler: (() -> Void)?
    
    init(point: CGPoint) {
        self.point = point

        let frame = CGRect(x: point.x - 52.0, y: point.y - 62.0, width: 104.0, height: 38.0)
        super.init(frame: frame)
        
        configureView()
    }

    required init?(coder aDecoder: NSCoder) {
        self.point = aDecoder.decodeCGPointForKey("point")
        super.init(coder: aDecoder)
        
        configureView()
    }
    
    func configureView() {
        backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.8)
        layer.cornerRadius = 8.0
        opaque = false

        label = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: 100.0, height: 30.0))
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = .Center
        addSubview(label)
        
        progress = UIProgressView(frame: CGRect(x: 6.0, y: 30.0, width: 88.0, height: 2.0))
        progress.tintColor = UIColor.greenColor()
        addSubview(progress)
    }
    
    // MARK: Touch handling.
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        backgroundColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 0.8)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.8)
        if let tapHandler = tapHandler {
            tapHandler()
        }
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.8)
    }

}
