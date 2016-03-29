//
//  AdventureImage.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 1/6/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

/// AdventureImage holds an image, usually artwork, associated with an adventure.
///
/// In addition to the image itself, which is stored and managed outside of Core Data and on the filesystem, the object also holds the information about a square portion of the image that is to actually be used.
final class AdventureImage : NSManagedObject {
    
    /// Adventure to which this image is associated.
    @NSManaged var adventure: Adventure
    
    /// Image associated with the adventure.
    var image: UIImage? {
        get {
            if let pathComponent = rawImagePathComponent {
                let documentsDirectoryURLs = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
                let imagesDirectoryURL = documentsDirectoryURLs.last!.URLByAppendingPathComponent("AdventureImages", isDirectory: true)

                let imageURL = imagesDirectoryURL.URLByAppendingPathComponent(pathComponent).URLByAppendingPathExtension("png")

                let imageData = try! NSData(contentsOfURL: imageURL, options: [])
                return UIImage(data: imageData)
            } else {
                return nil
            }
        }
        set(newImage) {
            let fileManager = NSFileManager.defaultManager()
            let documentsDirectoryURLs = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
            let imagesDirectoryURL = documentsDirectoryURLs.last!.URLByAppendingPathComponent("AdventureImages", isDirectory: true)
            
            try! fileManager.createDirectoryAtURL(imagesDirectoryURL, withIntermediateDirectories: true, attributes: nil)

            if let oldPathComponent = rawImagePathComponent {
                let oldImageURL = imagesDirectoryURL.URLByAppendingPathComponent(oldPathComponent).URLByAppendingPathExtension("png")
                try! fileManager.removeItemAtURL(oldImageURL)
            }
            
            if let newImage = newImage {
                let imageData = UIImagePNGRepresentation(newImage)!
    
                let pathComponent = NSUUID().UUIDString
                let imageURL = imagesDirectoryURL.URLByAppendingPathComponent(pathComponent).URLByAppendingPathExtension("png")
                try! imageData.writeToURL(imageURL, options: [])
                
                rawImagePathComponent = pathComponent
            } else {
                rawImagePathComponent = nil
            }
        }
    }
    @NSManaged private var rawImagePathComponent: String?

    /// Fraction of the image, in unit value, to be used.
    ///
    /// For square images 1.0 represents the entire image; for non-square images, 1.0 represents a box anchored at `origin` that is as wide or tall as the shortest dimension of the image. Values smaller than 1.0 represent a "zoomed" portion of the image anchored at `origin`.
    var fraction: CGFloat {
        get {
            return CGFloat(rawFraction.floatValue)
        }
        set(newFraction) {
            rawFraction = NSNumber(float: Float(newFraction))
        }
    }
    @NSManaged private var rawFraction: NSNumber
    
    /// Origin of the fraction of the image, in unit value, to be used.
    ///
    /// This is anchored at the top-left of the image, thus (0.0, 0.0) is the top left. Unit value is used based on a square image, for an image twice as wide as it is tall, and with a `fraction` of 1.0, (0.0, 0.0) represents the left half of the image, (1.0, 0.0) represents the right half, and (0.5, 0.0) would be the central box.
    var origin: CGPoint {
        get {
            return CGPoint(x: CGFloat(rawOriginX.floatValue), y: CGFloat(rawOriginY.floatValue))
        }
        set(newOrigin) {
            rawOriginX = NSNumber(float: Float(newOrigin.x))
            rawOriginY = NSNumber(float: Float(newOrigin.y))
        }
    }
    @NSManaged private var rawOriginX: NSNumber
    @NSManaged private var rawOriginY: NSNumber
    
    convenience init(adventure: Adventure, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.AdventureImage, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.adventure = adventure
    }
    
    override func prepareForDeletion() {
        super.prepareForDeletion()
        
        // Remove the image from the filesystem on deletion.
        image = nil
    }
    
}
