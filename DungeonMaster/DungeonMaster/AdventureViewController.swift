//
//  AdventureViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 1/13/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import UIKit

class AdventureViewController : UIViewController, ManagedObjectObserverDelegate, UITextViewDelegate, AdjustableImageViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var adventure: Adventure!

    @IBOutlet var deleteButtonItem: UIBarButtonItem!
    @IBOutlet var nameTextView: UITextView!
    @IBOutlet var adjustableImageView: AdjustableImageView!
    
    @IBOutlet var playersView: UIView!
    
    var observer: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Put the edit button in, with space between it and the compendium buttons.
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        fixedSpace.width = 40.0

        navigationItem.rightBarButtonItems?.insert(fixedSpace, at: 0)
        navigationItem.rightBarButtonItems?.insert(editButtonItem, at: 0)
        
        // Save the adventure so we come back to it next time.
        UserDefaults.standard.set(adventure.name, forKey: "Adventure")
        
        configureView()
        
        observer = ManagedObjectObserver(object: adventure, delegate: self)
    }

    func configureView() {
        navigationItem.title = adventure.name
        
        nameTextView.text = adventure.name
        
        adjustableImageView.setImage(adventure.image.image, fraction: adventure.image.fraction, origin: adventure.image.origin)
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        let oldEditing = self.isEditing
        super.setEditing(editing, animated: animated)
        
        navigationItem.hidesBackButton = editing
        navigationItem.leftBarButtonItem = editing ? deleteButtonItem : nil

        nameTextView.isEditable = editing
        
        adjustableImageView.editing = editing
        
        playersViewController.setEditing(editing, animated: animated)
        gamesViewController.setEditing(editing, animated: animated)
        encountersViewController.setEditing(editing, animated: animated)

        if oldEditing && !editing {
            nameTextView.resignFirstResponder()
            
            adventure.lastModified = Date()
            try! managedObjectContext.save()
        }
    }

    // MARK: Navigation
    
    var playersViewController: AdventurePlayersViewController!
    var gamesViewController: AdventureGamesViewController!
    var encountersViewController: AdventureEncountersViewController!

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PlayersEmbedSegue" {
            playersViewController = segue.destination as! AdventurePlayersViewController
            playersViewController.adventure = adventure
        } else if segue.identifier == "GamesEmbedSegue" {
            gamesViewController = segue.destination as! AdventureGamesViewController
            gamesViewController.adventure = adventure
        } else if segue.identifier == "EncountersEmbedSegue" {
            encountersViewController = segue.destination as! AdventureEncountersViewController
            encountersViewController.adventure = adventure
        } else if segue.identifier == "CompendiumMonstersSegue" {
            let viewController = segue.destination as! CompendiumViewController
            viewController.books = adventure.books.allObjects as! [Book]
            viewController.showMonsters()
        } else if segue.identifier == "CompendiumSpellsSegue" {
            let viewController = segue.destination as! CompendiumViewController
            viewController.books = adventure.books.allObjects as! [Book]
            viewController.showSpells()
        } else if segue.identifier == "CompendiumMagicItemsSegue" {
            let viewController = segue.destination as! CompendiumViewController
            viewController.books = adventure.books.allObjects as! [Book]
            viewController.showMagicItems()
        }
    }
    
    // MARK: Actions
    
    @IBAction func deleteButtonTapped(_ sender: UIBarButtonItem) {
        let controller = UIAlertController(title: "Delete “\(adventure.name)”?", message: "This will delete all information associated with the adventure, including player records, and cannot be undone.", preferredStyle: .alert)

        controller.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { action in
            managedObjectContext.delete(self.adventure)
            try! managedObjectContext.save()
            
            self.navigationController?.popViewController(animated: true)
        }))
        
        // .Default, not .Cancel, because the other action is destructive and we want the Cancel button to be the "default" and right-most button.
        controller.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))

        present(controller, animated: true, completion: nil)
    }
    
    // MARK: ManagedObjectObserverDelegate
    
    func managedObject(_ object: Adventure, changedForType type: ManagedObjectChangeType) {
        guard !isEditing else { return }
        
        configureView()
    }
    
    // MARK: UITextViewDelegate
    
    func textViewDidChange(_ textView: UITextView) {
        adventure.name = textView.text
        do {
            try adventure.validateForUpdate()
            navigationItem.rightBarButtonItems?[0].isEnabled = true
        } catch {
            navigationItem.rightBarButtonItems?[0].isEnabled = false
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            if let _ = try? adventure.validateForUpdate() {
                setEditing(false, animated: true)
            }

            return false
        }
        
        return true
    }
    
    // MARK: AdjustableImageViewDelegate
    
    func adjustableImageViewShouldChangeImage(_ adjustableImageView: AdjustableImageView) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.modalPresentationStyle = .popover
        imagePicker.delegate = self
        
        if let presentation = imagePicker.popoverPresentationController {
            presentation.sourceView = adjustableImageView
            presentation.sourceRect = adjustableImageView.bounds
        }
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func adjustableImageViewDidChangeArea(_ adjustableImageView: AdjustableImageView) {
        adventure.image.fraction = adjustableImageView.fraction
        adventure.image.origin = adjustableImageView.origin
    }
    
    // MARK: UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            adjustableImageView.image = image
            
            // Setting the image provides a new fraction and origin, make sure we save those too.
            adventure.image.image = adjustableImageView.image
            adventure.image.fraction = adjustableImageView.fraction
            adventure.image.origin = adjustableImageView.origin
        }
        
        dismiss(animated: true, completion: nil)
    }

}
