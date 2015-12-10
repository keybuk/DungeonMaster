//
//  TabletopViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/8/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

class TabletopViewController: UIViewController {

    var tabletopView: TabletopView!
    
    var points = [CGPoint(x: 250.0, y: 250.0),
        CGPoint(x: 150.0, y: 100.0),
        CGPoint(x: 350.0, y: 150.0),
        CGPoint(x: 275.0, y: 400.0),
        CGPoint(x: 400.0, y: 450.0),
    ]
    
    var names = ["Goblin", "Goblin", "Wolf", "Bugbear Captain", "Half-Red Dragon Veteran"]
    var healths: [Float] = [0.8, 0.2, 1.0, 0.7, 0.5]
    
    override func awakeFromNib() {
        super.awakeFromNib()
        tabletopView = view as! TabletopView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: TabletopViewDataSource
extension TabletopViewController: TabletopViewDataSource {
    
    func numberOfItemsInTabletopView(tabletopView: TabletopView) -> Int {
        return points.count
    }
    
    func tabletopView(tabletopView: TabletopView, pointForItem index: Int) -> CGPoint {
        return points[index]
    }
    
    func tabletopView(tabletopView: TabletopView, nameForItem index: Int) -> String {
        return names[index]
    }
    
    func tabletopView(tabletopView: TabletopView, healthForItem index: Int) -> Float {
        return healths[index]
    }

}

extension TabletopViewController: TabletopViewDelegate {
    
    func tabletopView(tabletopView: TabletopView, moveItem index: Int, to point: CGPoint) {
        points[index] = point
    }
    
    func tabletopView(tabletopView: TabletopView, willShowStatsForItem index: Int) {
        print("Tapped \(index)")
    }
    
    func tabletopView(tabletopView: TabletopView, didSelectItem index: Int) {
        print("Selected \(index)")
    }

}