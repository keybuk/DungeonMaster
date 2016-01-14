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

    @IBOutlet var editBarButtonItem: UIBarButtonItem!
    @IBOutlet var doneBarButtonItem: UIBarButtonItem!
    @IBOutlet var deleteBarButtonItem: UIBarButtonItem!
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
    
    // MARK: Actions
    
    var oldLeftItemsSupplementBackButton: Bool!
    
    @IBAction func editButtonTapped(sender: UIBarButtonItem) {
        if let index = navigationItem.rightBarButtonItems?.indexOf(editBarButtonItem) {
            navigationItem.rightBarButtonItems?.removeAtIndex(index)
            navigationItem.rightBarButtonItems?.insert(doneBarButtonItem, atIndex: index)
        }
        oldLeftItemsSupplementBackButton = navigationItem.leftItemsSupplementBackButton
        navigationItem.leftBarButtonItem = deleteBarButtonItem
        navigationItem.leftItemsSupplementBackButton = false
    }
    
    @IBAction func doneButtonTapped(sender: UIBarButtonItem) {
        if let index = navigationItem.rightBarButtonItems?.indexOf(doneBarButtonItem) {
            navigationItem.rightBarButtonItems?.removeAtIndex(index)
            navigationItem.rightBarButtonItems?.insert(editBarButtonItem, atIndex: index)
        }
        navigationItem.leftBarButtonItem = nil
        navigationItem.leftItemsSupplementBackButton = oldLeftItemsSupplementBackButton
        oldLeftItemsSupplementBackButton = nil
        
        try! managedObjectContext.save()
    }

    @IBAction func deleteButtonTapped(sender: UIBarButtonItem) {
        let controller = UIAlertController(title: "Delete “\(adventure.name)”", message: "Are you sure? This will delete all information associated with the adventure, and cannot be undone.", preferredStyle: .Alert)

        controller.addAction(UIAlertAction(title: "Delete", style: .Destructive, handler: { action in
            managedObjectContext.deleteObject(self.adventure)
            try! managedObjectContext.save()
            
            self.navigationController?.popViewControllerAnimated(true)
        }))

        controller.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        presentViewController(controller, animated: true, completion: nil)
    }
}
