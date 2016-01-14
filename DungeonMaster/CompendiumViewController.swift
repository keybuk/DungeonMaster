//
//  CompendiumViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 1/14/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import UIKit

class CompendiumViewController: UITabBarController {
    
    var books: [Book]!

    @IBOutlet var closeButtonItem: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let viewController = segue.destinationViewController
        viewController.navigationItem.leftBarButtonItems?.insert(closeButtonItem, atIndex: 0)
    }

}
