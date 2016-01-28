//
//  AdventureViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 1/13/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import UIKit

class AdventureViewController: UIViewController, ManagedObjectObserverDelegate, UITextViewDelegate, AdjustableImageViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var adventure: Adventure!

    @IBOutlet var deleteButtonItem: UIBarButtonItem!
    @IBOutlet var nameTextView: UITextView!
    @IBOutlet var adjustableImageView: AdjustableImageView!
    
    @IBOutlet var playersView: UIView!
    
    var observer: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Put the edit button in, with space between it and the compendium buttons.
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: nil, action: nil)
        fixedSpace.width = 40.0

        navigationItem.rightBarButtonItems?.insert(fixedSpace, atIndex: 0)
        navigationItem.rightBarButtonItems?.insert(editButtonItem(), atIndex: 0)
        
        // Save the adventure so we come back to it next time.
        NSUserDefaults.standardUserDefaults().setObject(adventure.name, forKey: "Adventure")
        
        configureView()
        
        observer = ManagedObjectObserver(object: adventure, delegate: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureView() {
        navigationItem.title = adventure.name
        
        nameTextView.text = adventure.name
        
        adjustableImageView.setImage(adventure.image.image, fraction: adventure.image.fraction, origin: adventure.image.origin)
    }

    override func setEditing(editing: Bool, animated: Bool) {
        let oldEditing = self.editing
        super.setEditing(editing, animated: animated)
        
        navigationItem.hidesBackButton = editing
        navigationItem.leftBarButtonItem = editing ? deleteButtonItem : nil

        nameTextView.editable = editing
        
        adjustableImageView.editing = editing
        
        playersViewController.setEditing(editing, animated: animated)
        gamesViewController.setEditing(editing, animated: animated)
        encountersViewController.setEditing(editing, animated: animated)

        if oldEditing && !editing {
            nameTextView.resignFirstResponder()
            
            adventure.lastModified = NSDate()
            try! managedObjectContext.save()
        }
    }

    // MARK: Navigation
    
    var playersViewController: AdventurePlayersViewController!
    var gamesViewController: AdventureGamesViewController!
    var encountersViewController: AdventureEncountersViewController!

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PlayersEmbedSegue" {
            playersViewController = segue.destinationViewController as! AdventurePlayersViewController
            playersViewController.adventure = adventure
        } else if segue.identifier == "GamesEmbedSegue" {
            gamesViewController = segue.destinationViewController as! AdventureGamesViewController
            gamesViewController.adventure = adventure
        } else if segue.identifier == "EncountersEmbedSegue" {
            encountersViewController = segue.destinationViewController as! AdventureEncountersViewController
            encountersViewController.adventure = adventure
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
    
    // MARK: ManagedObjectObserverDelegate
    
    func managedObject(object: Adventure, changedForType type: ManagedObjectChangeType) {
        guard !editing else { return }
        
        configureView()
    }
    
    // MARK: UITextViewDelegate
    
    func textViewDidChange(textView: UITextView) {
        adventure.name = textView.text
        do {
            try adventure.validateForUpdate()
            navigationItem.rightBarButtonItems?[0].enabled = true
        } catch {
            navigationItem.rightBarButtonItems?[0].enabled = false
        }
    }

    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            if let _ = try? adventure.validateForUpdate() {
                setEditing(false, animated: true)
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
