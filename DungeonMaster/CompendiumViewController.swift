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

        // Install navigation buttons into view controllers' navigation items, and also copy over the list of books we should use.
        for viewController in viewControllers! {
            let closeButtonItem = UIBarButtonItem(title: "Close", style: .Plain, target: self, action: "closeButtonTapped:")
            
            if let splitViewController = viewController as? UISplitViewController, masterViewController = (splitViewController.viewControllers.first as? UINavigationController)?.topViewController, detailViewController = (splitViewController.viewControllers.last as? UINavigationController)?.topViewController {
                masterViewController.navigationItem.leftBarButtonItem = closeButtonItem
                
                detailViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
                detailViewController.navigationItem.leftItemsSupplementBackButton = true
                
                if let monstersViewController = masterViewController as? MonstersViewController {
                    monstersViewController.books = books
                }
            } else if let topViewController = (viewController as? UINavigationController)?.topViewController {
                topViewController.navigationItem.leftBarButtonItem = closeButtonItem
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: Actions
    
    @IBAction func closeButtonTapped(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }

}
