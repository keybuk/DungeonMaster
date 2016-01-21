//
//  AdventureViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 1/13/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import UIKit

class AdventureViewController: UIViewController, UITextViewDelegate, AdjustableImageViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var adventure: Adventure!

    @IBOutlet var editBarButtonItem: UIBarButtonItem!
    @IBOutlet var doneBarButtonItem: UIBarButtonItem!
    @IBOutlet var deleteBarButtonItem: UIBarButtonItem!
    @IBOutlet var nameTextView: UITextView!
    @IBOutlet var adjustableImageView: AdjustableImageView!
    
    @IBOutlet var playersView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Interface Builder won't let us put one of these in...
        if let index = navigationItem.rightBarButtonItems?.indexOf(editBarButtonItem) {
            let fixedSpace = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: nil, action: nil)
            fixedSpace.width = 40.0

            navigationItem.rightBarButtonItems?.insert(fixedSpace, atIndex: index + 1)
        }

        // Save the adventure so we come back to it next time.
        NSUserDefaults.standardUserDefaults().setObject(adventure.name, forKey: "Adventure")
        
        // Update the view.
        navigationItem.title = adventure.name
        
        nameTextView.text = adventure.name
        adjustableImageView.setImage(adventure.image.image, fraction: adventure.image.fraction, origin: adventure.image.origin)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: Navigation
    
    var playersViewController: AdventurePlayersViewController!
    var gamesViewController: AdventureGamesViewController!

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PlayersEmbedSegue" {
            playersViewController = segue.destinationViewController as! AdventurePlayersViewController
            playersViewController.adventure = adventure
        } else if segue.identifier == "GamesEmbedSegue" {
            gamesViewController = segue.destinationViewController as! AdventureGamesViewController
            gamesViewController.adventure = adventure
        } else if segue.identifier == "CompendiumMonstersSegue" {
            let viewController = segue.destinationViewController as! CompendiumViewController
            viewController.books = adventure.books.allObjects as! [Book]
            viewController.showMonsters()
        } else if segue.identifier == "CompendiumSpellsSegue" {
            let viewController = segue.destinationViewController as! CompendiumViewController
            viewController.books = adventure.books.allObjects as! [Book]
            viewController.showSpells()
        } else if segue.identifier == "CompendiumMagicItemsSegue" {
            let viewController = segue.destinationViewController as! CompendiumViewController
            viewController.books = adventure.books.allObjects as! [Book]
            viewController.showMagicItems()
        }
    }
    
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
        
        nameTextView.editable = true

        adjustableImageView.editing = true
        
        playersViewController.setEditing(true, animated: true)
        gamesViewController.setEditing(true, animated: true)
    }
    
    func finishEditing() {
        if let index = navigationItem.rightBarButtonItems?.indexOf(doneBarButtonItem) {
            navigationItem.rightBarButtonItems?.removeAtIndex(index)
            navigationItem.rightBarButtonItems?.insert(editBarButtonItem, atIndex: index)
        }
        navigationItem.leftBarButtonItem = nil
        navigationItem.leftItemsSupplementBackButton = oldLeftItemsSupplementBackButton
        oldLeftItemsSupplementBackButton = nil
        
        nameTextView.editable = false
        nameTextView.resignFirstResponder()
        
        adjustableImageView.editing = false
        
        playersViewController.setEditing(false, animated: true)
        gamesViewController.setEditing(false, animated: true)
        
        adventure.lastModified = NSDate()
        try! managedObjectContext.save()
        
        navigationItem.title = adventure.name
    }
    
    @IBAction func doneButtonTapped(sender: UIBarButtonItem) {
        finishEditing()
    }

    @IBAction func deleteButtonTapped(sender: UIBarButtonItem) {
        let controller = UIAlertController(title: "Delete “\(adventure.name)”?", message: "This will delete all information associated with the adventure, including player records, and cannot be undone.", preferredStyle: .Alert)

        controller.addAction(UIAlertAction(title: "Delete", style: .Destructive, handler: { action in
            managedObjectContext.deleteObject(self.adventure)
            try! managedObjectContext.save()
            
            self.navigationController?.popViewControllerAnimated(true)
        }))
        
        // .Default, not .Cancel, because the other action is destructive and we want the Cancel button to be the "default" and right-most button.
        controller.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))

        presentViewController(controller, animated: true, completion: nil)
    }
    
    // MARK: UITextViewDelegate
    
    func textViewDidChange(textView: UITextView) {
        adventure.name = textView.text
        do {
            try adventure.validateForUpdate()
            doneBarButtonItem.enabled = true
        } catch {
            doneBarButtonItem.enabled = false
        }
    }

    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            if let _ = try? adventure.validateForUpdate() {
                finishEditing()
            }

            return false
        }
        
        return true
    }
    
    // MARK: AdjustableImageViewDelegate
    
    func adjustableImageViewShouldChangeImage(adjustableImageView: AdjustableImageView) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .PhotoLibrary
        imagePicker.modalPresentationStyle = .Popover
        imagePicker.delegate = self
        
        if let presentation = imagePicker.popoverPresentationController {
            presentation.sourceView = adjustableImageView
            presentation.sourceRect = adjustableImageView.bounds
        }
        
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func adjustableImageViewDidChangeArea(adjustableImageView: AdjustableImageView) {
        adventure.image.fraction = adjustableImageView.fraction
        adventure.image.origin = adjustableImageView.origin
    }
    
    // MARK: UIImagePickerControllerDelegate
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            adjustableImageView.image = image
            
            // Setting the image provides a new fraction and origin, make sure we save those too.
            adventure.image.image = adjustableImageView.image
            adventure.image.fraction = adjustableImageView.fraction
            adventure.image.origin = adjustableImageView.origin
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }

}
