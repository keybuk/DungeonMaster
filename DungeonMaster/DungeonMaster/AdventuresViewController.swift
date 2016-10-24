//
//  AdventuresViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 1/3/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class AdventuresViewController : UICollectionViewController, NSFetchedResultsControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet var addButtonItem: UIBarButtonItem!
    @IBOutlet var doneButtonItem: UIBarButtonItem!
    @IBOutlet var cancelButtonItem: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Remove the saved adventure, so next time we come back to the adventures view again.
        UserDefaults.standard.removeObject(forKey: "Adventure")
    }

    // MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AdventureSegue" {
            if let indexPaths = collectionView?.indexPathsForSelectedItems {
                let adventure = fetchedResultsController.object(at: indexPaths[0])
                
                let viewController = segue.destination as! AdventureViewController
                viewController.adventure = adventure
            }
        }
    }
    
    // MARK: Actions
    
    var oldLeftItemsSupplementBackButton: Bool!
    
    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        if let index = navigationItem.rightBarButtonItems?.index(of: addButtonItem) {
            navigationItem.rightBarButtonItems?.remove(at: index)
            navigationItem.rightBarButtonItems?.insert(doneButtonItem, at: index)
        }
        oldLeftItemsSupplementBackButton = navigationItem.leftItemsSupplementBackButton
        navigationItem.leftBarButtonItem = cancelButtonItem
        navigationItem.leftItemsSupplementBackButton = false
        
        collectionView?.allowsSelection = false
        collectionView?.isScrollEnabled = false
        
        doneButtonItem.isEnabled = false
        
        let _ = Adventure(insertInto: managedObjectContext)
        
        // We can reasonably assume that the cell is going to be going in at the top, so scroll there.
        if collectionView?.numberOfItems(inSection: 0) > 0 {
            collectionView?.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
        }
    }
    
    func finishAdding(cancel: Bool) {
        if let index = navigationItem.rightBarButtonItems?.index(of: doneButtonItem) {
            navigationItem.rightBarButtonItems?.remove(at: index)
            navigationItem.rightBarButtonItems?.insert(addButtonItem, at: index)
        }
        navigationItem.leftBarButtonItem = nil
        navigationItem.leftItemsSupplementBackButton = oldLeftItemsSupplementBackButton
        oldLeftItemsSupplementBackButton = nil
        
        collectionView?.allowsSelection = true
        collectionView?.isScrollEnabled = true
        
        guard let insertedAdventures = fetchedResultsController.fetchedObjects?.filter({ $0.isInserted }) else { return }
        for adventure in insertedAdventures {
            if let indexPath = fetchedResultsController.indexPath(forObject: adventure),
                let cell = collectionView?.cellForItem(at: indexPath) as? AdventureCell {
                cell.editing = false
            }
            
            if cancel {
                managedObjectContext.delete(adventure)
            }
        }
        
        try! managedObjectContext.save()
    }

    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
        finishAdding(cancel: false)
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        finishAdding(cancel: true)
    }
    
    /// Returns true if all newly inserted adventures are valid.
    func validateAdventures() -> Bool {
        guard let insertedAdventures = fetchedResultsController.fetchedObjects?.filter({ $0.isInserted }) else { return true }
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
        doneButtonItem.isEnabled = validateAdventures()
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
    
    lazy var fetchedResultsController: NSFetchedResultsController<Adventure> = { [unowned self] in
        let fetchRequest = NSFetchRequest<Adventure>(entity: Model.Adventure)
        
        let sortDescriptor = NSSortDescriptor(key: "lastModified", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        try! fetchedResultsController.performFetch()
        
        return fetchedResultsController
    }()

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    var noAdventuresLabel: UILabel!

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        
        if sectionInfo.numberOfObjects == 0 {
            noAdventuresLabel = UILabel()
            noAdventuresLabel.text = "Tap ‘+’ to create an Adventure."
            noAdventuresLabel.textColor = UIColor.lightGray
            noAdventuresLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
            noAdventuresLabel.translatesAutoresizingMaskIntoConstraints = false
            noAdventuresLabel.sizeToFit()
            
            collectionView.addSubview(noAdventuresLabel)
            
            noAdventuresLabel.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor).isActive = true
            noAdventuresLabel.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor).isActive = true
        } else if let label = noAdventuresLabel {
            label.removeFromSuperview()
            noAdventuresLabel = nil
        }
        
        return sectionInfo.numberOfObjects
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AdventureCell", for: indexPath) as! AdventureCell
        let adventure = fetchedResultsController.object(at: indexPath)
        cell.adventure = adventure

        if adventure.isInserted {
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
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        changeBlocks = []
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            changeBlocks.append {
                self.collectionView?.insertSections(IndexSet(integer: sectionIndex))
            }
        case .delete:
            changeBlocks.append {
                self.collectionView?.deleteSections(IndexSet(integer: sectionIndex))
            }
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            changeBlocks.append {
                self.collectionView?.insertItems(at: [ newIndexPath! ])
            }
        case .delete:
            changeBlocks.append {
                self.collectionView?.deleteItems(at: [ indexPath! ])
            }
        case .update:
            if let cell = collectionView?.cellForItem(at: indexPath!) as? AdventureCell, !cell.editing {
                let adventure = anObject as! Adventure
                cell.adventure = adventure
            }
        case .move:
            // .Move implies .Update; update the cell at the old index, and then move it.
            if let cell = collectionView?.cellForItem(at: indexPath!) as? AdventureCell, !cell.editing {
                let adventure = anObject as! Adventure
                cell.adventure = adventure
            }

            changeBlocks.append {
                self.collectionView?.moveItem(at: indexPath!, to: newIndexPath!)
            }
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
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
    func showImagePicker(_ sourceView: UIView, setImage: @escaping (UIImage) -> Void) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.modalPresentationStyle = .popover
        imagePicker.delegate = self
        
        if let presentation = imagePicker.popoverPresentationController {
            presentation.sourceView = sourceView
            presentation.sourceRect = sourceView.bounds
        }
        
        self.setImage = setImage
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            setImage(image)
        }
        
        setImage = nil
        dismiss(animated: true, completion: nil)
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

            textView.isEditable = editing
            textView.isSelectable = editing
            
            if editing {
                if textView.text == "" {
                    addPlaceholder()
                }
                // Give the cell a chance to be added to the view in case it's a reused cell.
                DispatchQueue.main.async {
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
        placeholderLabel!.textColor = UIColor.lightGray
        placeholderLabel!.textAlignment = .center
        placeholderLabel!.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
        placeholderLabel!.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel!.sizeToFit()
        
        textView.addSubview(placeholderLabel!)
        textView.sendSubview(toBack: placeholderLabel!)
        
        // No idea why this -5.5 fudge constant is necessary.
        placeholderLabel!.centerXAnchor.constraint(equalTo: textView.centerXAnchor).isActive = true
        placeholderLabel!.centerYAnchor.constraint(equalTo: textView.centerYAnchor, constant: -5.5).isActive = true
    }
    
    func removePlaceholder() {
        guard let label = placeholderLabel else { return }
        
        label.removeFromSuperview()
        placeholderLabel = nil
    }
    
    // MARK: UITextViewDelegate
    
    func textViewDidChange(_ textView: UITextView) {
        adventure.name = textView.text
        if textView.text == "" {
            addPlaceholder()
        } else {
            removePlaceholder()
        }
        didChange?()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard text == "\n" else { return true }
        
        didSubmit?()
        return false
    }
    
    // MARK: AdjustableImageViewDelegate
    
    var showImagePicker: ((UIView, (UIImage) -> Void) -> Void)!
    
    func adjustableImageViewShouldChangeImage(_ adjustableImageView: AdjustableImageView) {
        showImagePicker(adjustableImageView) { image in
            self.adjustableImageView.image = image

            // Setting the image provides a new fraction and origin, make sure we save those too.
            self.adventure.image.image = self.adjustableImageView.image
            self.adventure.image.fraction = self.adjustableImageView.fraction
            self.adventure.image.origin = self.adjustableImageView.origin

            self.didChange?()
        }
    }
    
    func adjustableImageViewDidChangeArea(_ adjustableImageView: AdjustableImageView) {
        adventure.image.fraction = adjustableImageView.fraction
        adventure.image.origin = adjustableImageView.origin
        didChange?()
    }
    
}
