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
class AppDelegate : UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var networkController: NetworkController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        importIfNeeded()

        // If the top view controller is the Adventures view, but there is a saved adventure, push it onto the stack. The most common use case is always going to be starting from the same adventure you were previously on.
        if let navigationController = window?.rootViewController as? UINavigationController,
            let adventuresViewController = navigationController.topViewController as? AdventuresViewController,
            let adventureName = UserDefaults.standard.object(forKey: "Adventure") as? String {
                let fetchRequest = NSFetchRequest<Adventure>(entity: Model.Adventure)
                fetchRequest.predicate = NSPredicate(format: "name == %@", adventureName)
                
                let adventures = try! managedObjectContext.fetch(fetchRequest)
                if adventures.count > 0 {
                    let adventureViewController = adventuresViewController.storyboard?.instantiateViewController(withIdentifier: "AdventureViewController") as! AdventureViewController
                    adventureViewController.adventure = adventures[0]
                    
                    navigationController.pushViewController(adventureViewController, animated: false)
                }
        }
        
        networkController = NetworkController()

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        networkController?.suspend()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        networkController?.resume()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        if managedObjectContext.hasChanges {
            try! managedObjectContext.save()
        }
    }

}
