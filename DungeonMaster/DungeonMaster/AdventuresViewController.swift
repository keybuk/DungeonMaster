//
//  AdventuresViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 1/3/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class AdventuresViewController : UICollectionViewController, NSFetchedResultsControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet var addButtonItem: UIBarButtonItem!
    @IBOutlet var doneButtonItem: UIBarButtonItem!
    @IBOutlet var cancelButtonItem: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Remove the saved adventure, so next time we come back to the adventures view again.
        NSUserDefaults.standardUserDefaults().removeObjectForKey("Adventure")
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "AdventureSegue" {
            if let indexPaths = collectionView?.indexPathsForSelectedItems() {
                let adventure = fetchedResultsController.objectAtIndexPath(indexPaths[0]) as! Adventure
                
                let viewController = segue.destinationViewController as! AdventureViewController
                viewController.adventure = adventure
            }
        }
    }
    
    // MARK: Actions
    
    var oldLeftItemsSupplementBackButton: Bool!
    
    @IBAction func addButtonTapped(sender: UIBarButtonItem) {
        if let index = navigationItem.rightBarButtonItems?.indexOf(addButtonItem) {
            navigationItem.rightBarButtonItems?.removeAtIndex(index)
            navigationItem.rightBarButtonItems?.insert(doneButtonItem, atIndex: index)
        }
        oldLeftItemsSupplementBackButton = navigationItem.leftItemsSupplementBackButton
        navigationItem.leftBarButtonItem = cancelButtonItem
        navigationItem.leftItemsSupplementBackButton = false
        
        collectionView?.allowsSelection = false
        collectionView?.scrollEnabled = false
        
        doneButtonItem.enabled = false
        
        let _ = Adventure(inManagedObjectContext: managedObjectContext)
        
        // We can reasonably assume that the cell is going to be going in at the top, so scroll there.
        if collectionView?.numberOfItemsInSection(0) > 0 {
            collectionView?.scrollToItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0), atScrollPosition: .Top, animated: true)
        }
    }
    
    func finishAdding(cancel cancel: Bool) {
        if let index = navigationItem.rightBarButtonItems?.indexOf(doneButtonItem) {
            navigationItem.rightBarButtonItems?.removeAtIndex(index)
            navigationItem.rightBarButtonItems?.insert(addButtonItem, atIndex: index)
        }
        navigationItem.leftBarButtonItem = nil
        navigationItem.leftItemsSupplementBackButton = oldLeftItemsSupplementBackButton
        oldLeftItemsSupplementBackButton = nil
        
        collectionView?.allowsSelection = true
        collectionView?.scrollEnabled = true
        
        guard let insertedAdventures = fetchedResultsController.fetchedObjects?.map({ $0 as! Adventure }).filter({ $0.inserted }) else { return }
        for adventure in insertedAdventures {
            if let indexPath = fetchedResultsController.indexPathForObject(adventure),
                cell = collectionView?.cellForItemAtIndexPath(indexPath) as? AdventureCell {
                cell.editing = false
            }
            
            if cancel {
                managedObjectContext.deleteObject(adventure)
            }
        }
        
        try! managedObjectContext.save()
    }

    @IBAction func doneButtonTapped(sender: UIBarButtonItem) {
        finishAdding(cancel: false)
    }
    
    @IBAction func cancelButtonTapped(sender: UIBarButtonItem) {
        finishAdding(cancel: true)
    }
    
    /// Returns true if all newly inserted adventures are valid.
    func validateAdventures() -> Bool {
        guard let insertedAdventures = fetchedResultsController.fetchedObjects?.map({ $0 as! Adventure }).filter({ $0.inserted }) else { return true }
        for adventure in insertedAdventures {
            do {
                try adventure.validateForInsert()
            } catch {
                return false
            }
        }
        
        return true
    }
    
    /// Called when the text or image in a cell changes.
    ///
    /// Part of the informal protocol between the table and the cell; this updates the status of the Done button based on the validity of the inserted adventures.
    func adventureCellDidChange() {
        doneButtonItem.enabled = validateAdventures()
    }
    
    /// Called when Return is pressed during cell text editing.
    ///
    /// Part of the informal protocol between the table and the cell; this has the same effect as the Done button if the inserted adventures are valid.
    func adventureCellDidSubmit() {
        if validateAdventures() {
            finishAdding(cancel: false)
        }
    }

    // MARK: Fetched results controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = { [unowned self] in
        let fetchRequest = NSFetchRequest(entity: Model.Adventure)
        
        let sortDescriptor = NSSortDescriptor(key: "lastModified", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        try! fetchedResultsController.performFetch()
        
        return fetchedResultsController
    }()

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    var noAdventuresLabel: UILabel!

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        
        if sectionInfo.numberOfObjects == 0 {
            noAdventuresLabel = UILabel()
            noAdventuresLabel.text = "Tap ‘+’ to create an Adventure."
            noAdventuresLabel.textColor = UIColor.lightGrayColor()
            noAdventuresLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
            noAdventuresLabel.translatesAutoresizingMaskIntoConstraints = false
            noAdventuresLabel.sizeToFit()
            
            collectionView.addSubview(noAdventuresLabel)
            
            noAdventuresLabel.centerXAnchor.constraintEqualToAnchor(collectionView.centerXAnchor).active = true
            noAdventuresLabel.centerYAnchor.constraintEqualToAnchor(collectionView.centerYAnchor).active = true
        } else if let label = noAdventuresLabel {
            label.removeFromSuperview()
            noAdventuresLabel = nil
        }
        
        return sectionInfo.numberOfObjects
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("AdventureCell", forIndexPath: indexPath) as! AdventureCell
        let adventure = fetchedResultsController.objectAtIndexPath(indexPath) as! Adventure
        cell.adventure = adventure

        if adventure.inserted {
            cell.editing = true
            cell.didChange = self.adventureCellDidChange
            cell.didSubmit = self.adventureCellDidSubmit
            cell.showImagePicker = self.showImagePicker
        } else {
            // Explicitly set this to work-around an IB bug where making the text view non-editable/selectable by default breaks it.
            cell.editing = false
        }

        return cell
    }

    // MARK: NSFetchedResultsControllerDelegate

    var changeBlocks: [() -> Void]!
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        changeBlocks = []
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            changeBlocks.append {
                self.collectionView?.insertSections(NSIndexSet(index: sectionIndex))
            }
        case .Delete:
            changeBlocks.append {
                self.collectionView?.deleteSections(NSIndexSet(index: sectionIndex))
            }
        default:
            break
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            changeBlocks.append {
                self.collectionView?.insertItemsAtIndexPaths([ newIndexPath! ])
            }
        case .Delete:
            changeBlocks.append {
                self.collectionView?.deleteItemsAtIndexPaths([ indexPath! ])
            }
        case .Update:
            if let cell = collectionView?.cellForItemAtIndexPath(indexPath!) as? AdventureCell where !cell.editing {
                let adventure = anObject as! Adventure
                cell.adventure = adventure
            }
        case .Move:
            // .Move implies .Update; update the cell at the old index, and then move it.
            if let cell = collectionView?.cellForItemAtIndexPath(indexPath!) as? AdventureCell where !cell.editing {
                let adventure = anObject as! Adventure
                cell.adventure = adventure
            }

            changeBlocks.append {
                self.collectionView?.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
            }
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        collectionView?.performBatchUpdates({
            for changeBlock in self.changeBlocks {
                changeBlock()
            }
            }, completion: { finished in
                self.changeBlocks = nil
        })
    }

    // MARK: UIImagePickerControllerDelegate
    
    var setImage: ((UIImage) -> Void)!

    /// Called when the image view in the cell is tapped.
    ///
    /// Part of the informal protocol between the table and the cell; this displays an image picker and calls the provided closure when a new image is selected.
    func showImagePicker(sourceView: UIView, setImage: (UIImage) -> Void) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .PhotoLibrary
        imagePicker.modalPresentationStyle = .Popover
        imagePicker.delegate = self
        
        if let presentation = imagePicker.popoverPresentationController {
            presentation.sourceView = sourceView
            presentation.sourceRect = sourceView.bounds
        }
        
        self.setImage = setImage
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            setImage(image)
        }
        
        setImage = nil
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}

// MARK: -

class AdventureCell : UICollectionViewCell, UITextViewDelegate, AdjustableImageViewDelegate {
    
    @IBOutlet var adjustableImageView: AdjustableImageView!
    @IBOutlet var textView: UITextView!
    
    var placeholderLabel: UILabel?
    
    var adventure: Adventure! {
        didSet {
            textView.text = adventure.name
            
            adjustableImageView.setImage(adventure.image.image, fraction: adventure.image.fraction, origin: adventure.image.origin)
        }
    }
    
    var editing = false {
        didSet {
            adjustableImageView.editing = editing

            textView.editable = editing
            textView.selectable = editing
            
            if editing {
                if textView.text == "" {
                    addPlaceholder()
                }
                // Give the cell a chance to be added to the view in case it's a reused cell.
                dispatch_async(dispatch_get_main_queue()) {
                    self.textView.becomeFirstResponder()
                }
            } else {
                textView.resignFirstResponder()
                removePlaceholder()
            }
        }
    }
    
    var didChange: (() -> Void)?
    var didSubmit: (() -> Void)?
    
    func addPlaceholder() {
        guard placeholderLabel == nil else { return }

        placeholderLabel = UILabel()
        placeholderLabel!.text = "Adventure"
        placeholderLabel!.textColor = UIColor.lightGrayColor()
        placeholderLabel!.textAlignment = .Center
        placeholderLabel!.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        placeholderLabel!.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel!.sizeToFit()
        
        textView.addSubview(placeholderLabel!)
        textView.sendSubviewToBack(placeholderLabel!)
        
        // No idea why this -5.5 fudge constant is necessary.
        placeholderLabel!.centerXAnchor.constraintEqualToAnchor(textView.centerXAnchor).active = true
        placeholderLabel!.centerYAnchor.constraintEqualToAnchor(textView.centerYAnchor, constant: -5.5).active = true
    }
    
    func removePlaceholder() {
        guard let label = placeholderLabel else { return }
        
        label.removeFromSuperview()
        placeholderLabel = nil
    }
    
    // MARK: UITextViewDelegate
    
    func textViewDidChange(textView: UITextView) {
        adventure.name = textView.text
        if textView.text == "" {
            addPlaceholder()
        } else {
            removePlaceholder()
        }
        didChange?()
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        guard text == "\n" else { return true }
        
        didSubmit?()
        return false
    }
    
    // MARK: AdjustableImageViewDelegate
    
    var showImagePicker: ((UIView, (UIImage) -> Void) -> Void)!
    
    func adjustableImageViewShouldChangeImage(adjustableImageView: AdjustableImageView) {
        showImagePicker(adjustableImageView) { image in
            self.adjustableImageView.image = image

            // Setting the image provides a new fraction and origin, make sure we save those too.
            self.adventure.image.image = self.adjustableImageView.image
            self.adventure.image.fraction = self.adjustableImageView.fraction
            self.adventure.image.origin = self.adjustableImageView.origin

            self.didChange?()
        }
    }
    
    func adjustableImageViewDidChangeArea(adjustableImageView: AdjustableImageView) {
        adventure.image.fraction = adjustableImageView.fraction
        adventure.image.origin = adjustableImageView.origin
        didChange?()
    }
    
}
