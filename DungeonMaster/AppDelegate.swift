//
//  AppDelegate.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 11/20/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        importIfNeeded()

        // If the top view controller is the Adventures view, but there is a saved adventure, push it onto the stack. The most common use case is always going to be starting from the same adventure you were previously on.
        if let navigationController = window?.rootViewController as? UINavigationController,
            adventuresViewController = navigationController.topViewController as? AdventuresViewController,
            adventureName = NSUserDefaults.standardUserDefaults().objectForKey("Adventure") as? String {
                let fetchRequest = NSFetchRequest(entity: Model.Adventure)
                fetchRequest.predicate = NSPredicate(format: "name == %@", adventureName)
                
                let adventures = try! managedObjectContext.executeFetchRequest(fetchRequest) as! [Adventure]
                if adventures.count > 0 {
                    let adventureViewController = adventuresViewController.storyboard?.instantiateViewControllerWithIdentifier("AdventureViewController") as! AdventureViewController
                    adventureViewController.adventure = adventures[0]
                    
                    navigationController.pushViewController(adventureViewController, animated: false)
                }
        }
        
        // Set up the split view controller, and place the display button in the top-left for certain devices.
        if let splitViewController = self.window!.rootViewController as? UISplitViewController {
            let navigationController = splitViewController.viewControllers.last as! UINavigationController
            splitViewController.delegate = self
            
            navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        saveContext()
    }

}

// MARK: UISplitViewControllerDelegate
extension AppDelegate: UISplitViewControllerDelegate {
 
    // 6S+ start primary only
    // uncollapse for detail when we tap a monster
    // Add and Back should collapse back to just primary (especially when zoomed)
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController, ontoPrimaryViewController primaryViewController:UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? DetailViewController else { return false }
        if topAsDetailController.monster == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        }
        return false
    }
    
}
