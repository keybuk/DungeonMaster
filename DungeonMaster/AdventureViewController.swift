//
//  AdventureViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 1/13/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import UIKit

class AdventureViewController: UIViewController {
    
    var adventure: Adventure!

    @IBOutlet var adjustableImageView: AdjustableImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Save the adventure so we come back to it next time.
        NSUserDefaults.standardUserDefaults().setObject(adventure.name, forKey: "Adventure")
        
        // Update the view.
        navigationItem.title = adventure.name
        
        adjustableImageView.setImage(adventure.image.image, fraction: adventure.image.fraction, origin: adventure.image.origin)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
