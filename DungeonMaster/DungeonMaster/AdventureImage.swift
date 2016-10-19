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
                let documentsDirectoryURLs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                let imagesDirectoryURL = documentsDirectoryURLs.last!.appendingPathComponent("AdventureImages", isDirectory: true)

                let imageURL = imagesDirectoryURL.appendingPathComponent(pathComponent).appendingPathExtension("png")

                let imageData = try! Data(contentsOf: imageURL, options: [])
                return UIImage(data: imageData)
            } else {
                return nil
            }
        }
        set(newImage) {
            let fileManager = FileManager.default
            let documentsDirectoryURLs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
            let imagesDirectoryURL = documentsDirectoryURLs.last!.appendingPathComponent("AdventureImages", isDirectory: true)
            
            try! fileManager.createDirectory(at: imagesDirectoryURL, withIntermediateDirectories: true, attributes: nil)

            if let oldPathComponent = rawImagePathComponent {
                let oldImageURL = imagesDirectoryURL.appendingPathComponent(oldPathComponent).appendingPathExtension("png")
                try! fileManager.removeItem(at: oldImageURL)
            }
            
            if let newImage = newImage {
                let imageData = UIImagePNGRepresentation(newImage)!
    
                let pathComponent = UUID().uuidString
                let imageURL = imagesDirectoryURL.appendingPathComponent(pathComponent).appendingPathExtension("png")
                try! imageData.write(to: imageURL, options: [])
                
                rawImagePathComponent = pathComponent
            } else {
                rawImagePathComponent = nil
            }
        }
    }
    @NSManaged fileprivate var rawImagePathComponent: String?

    /// Fraction of the image, in unit value, to be used.
    ///
    /// For square images 1.0 represents the entire image; for non-square images, 1.0 represents a box anchored at `origin` that is as wide or tall as the shortest dimension of the image. Values smaller than 1.0 represent a "zoomed" portion of the image anchored at `origin`.
    var fraction: CGFloat {
        get {
            return CGFloat(rawFraction.floatValue)
        }
        set(newFraction) {
            rawFraction = NSNumber(value: Float(newFraction) as Float)
        }
    }
    @NSManaged fileprivate var rawFraction: NSNumber
    
    /// Origin of the fraction of the image, in unit value, to be used.
    ///
    /// This is anchored at the top-left of the image, thus (0.0, 0.0) is the top left. Unit value is used based on a square image, for an image twice as wide as it is tall, and with a `fraction` of 1.0, (0.0, 0.0) represents the left half of the image, (1.0, 0.0) represents the right half, and (0.5, 0.0) would be the central box.
    var origin: CGPoint {
        get {
            return CGPoint(x: CGFloat(rawOriginX.floatValue), y: CGFloat(rawOriginY.floatValue))
        }
        set(newOrigin) {
            rawOriginX = NSNumber(value: Float(newOrigin.x) as Float)
            rawOriginY = NSNumber(value: Float(newOrigin.y) as Float)
        }
    }
    @NSManaged fileprivate var rawOriginX: NSNumber
    @NSManaged fileprivate var rawOriginY: NSNumber
    
    convenience init(adventure: Adventure, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.AdventureImage, inManagedObjectContext: context)
        self.init(entity: entity, insertInto: context)
        
        self.adventure = adventure
    }
    
    override func prepareForDeletion() {
        super.prepareForDeletion()
        
        // Remove the image from the filesystem on deletion.
        image = nil
    }
    
}
