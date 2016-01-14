//
//  AdventureViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 1/13/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class AdventureViewController: UIViewController, UITextViewDelegate, AdjustableImageViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var adventure: Adventure!

    @IBOutlet var editBarButtonItem: UIBarButtonItem!
    @IBOutlet var doneBarButtonItem: UIBarButtonItem!
    @IBOutlet var deleteBarButtonItem: UIBarButtonItem!
    @IBOutlet var nameTextView: UITextView!
    @IBOutlet var adjustableImageView: AdjustableImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

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

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "CompendiumSegue" {
            let viewController = segue.destinationViewController as! CompendiumViewController
            
            // FIXME the set of Books used by the Compendium should match those used by the Adventure. Since that will be adventure.books can remove the CoreData import after.
            let fetchRequest = NSFetchRequest(entity: Model.Book)
            viewController.books = try! managedObjectContext.executeFetchRequest(fetchRequest) as! [Book]
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
        nameTextView.becomeFirstResponder()

        adjustableImageView.editing = true
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
        
        adventure.lastModified = NSDate()
        try! managedObjectContext.save()
        
        navigationItem.title = adventure.name
    }
    
    @IBAction func doneButtonTapped(sender: UIBarButtonItem) {
        finishEditing()
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
    
    @IBAction func unwindFromCompendium(segue: UIStoryboardSegue) {
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
