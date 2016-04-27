//
//  FetchedResultsController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 3/14/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

// TODO index path API

// TODO other API methods I'm missing?
// - check API for compatibility, e.g. I think section should have .objects?
// - don't stick just because, think about each case
// - likewise maybe get rid of ? where it makes no sense, e.g. pre-performFetch()

// TODO it might be cheaper to just build+update sectionIndexes rather than cache-as-we-go

// TODO static sections
// - optional array of [Section] passed at constructor time, stored in a variable
// - variable can be changed/re-evaluated at performFetch() time
// - sections in this set do not get purged when empty

// TODO placeholder entry in sections
// - need to check where I use this, e.g all sections, or certain ones
// - object would still have to conform to Entity, which is not able to be an optional

// TODO it would be nice for sections to be able to be managed objects in their own right
// - would need to wrap somewhere to turn Section into ObjectIdentifier(Section) everywhere
// - would need to sort Section objects by NSSortDescriptor instead of directly comparable
// - using nil in a sort descriptor means self, so we could do this without a block

/// Provides a dynamic results set for a Core Data fetch request.
///
/// The results are determined by the `NSFetchRequest` and `NSManagedObjectContext` provided during initialization, and are made available in `fetchedObjects` once `performFetch()` has been called. Changes to `managedObjectContext` are observed, and `fetchedObjects` is updated automatically based on the changes.
///
/// Objects are sorted into sections based on the `sectionForObject` block provided during initialization, and are made available in the `sections`, with sections identified by a value of your choosing providing the type confirms to `Hashable` and `Comparable`. For efficiency, you can avoid repeated calls to `sectionForObject` unless specific keys of the object change by providing those keys in the optional `sectionKeys` initializer parameter.
///
/// Unlike `NSFetchedResultsController`, changes are always observed. To receive notification provide a block to the `handleChanges` initializer parameter. This block is passed an array of `FetchedResultsChange`, index paths (including those for updates) always refer to the index path prior to the changes being applied while the new index paths always refer to the index path after all changes have been applied.
///
/// # Changes to the controller
/// Various changes to the controller are permitted: changes to the `fetchRequest` `predicate` and `sortDescriptors`, and sectioning criteria by changing the `sectionForObject` block and corresponding `sectionKeys`.
///
/// After making changes you must call `performFetch()` to refresh both `fetchedObjects` and `sections`.
///
/// When called without parameters, you should reload the data of your `view` to match the new results, e.g. through `UITableView.reloadData()`:
///
///     controller.fetchRequest.sortDescriptors = ...
///     try! controller.performFetch()
///     tableView.reloadData()
///
/// In some circumstances, particularly if the changes are a result of transitioning between editing and non-editing states, you may instead wish to update the view through the normal `handleChanges` block. Drop the call to reload the data and instead call `performFetch(notifyChanges: true)`.
///
///     controller.fetchRequest.sortDescriptors = ...
///     try! controller.performFetch(notifyChanges: true)
///     // handleChanges() has been called from the above method
///
public class FetchedResultsController<Section : protocol<Hashable, Comparable>, Entity : NSManagedObject> : NSObject {
    
    /// The fetch request used to do the fetching.
    ///
    /// Changes to the fetch request are not automatically reflected in the fetched results. You must call `performFetch()` to refresh the fetched results.
    public let fetchRequest: NSFetchRequest
    
    /// The managed object context used to fetch objects.
    ///
    /// The controller registers to listen to change notifications on this context in order to update the fetched results.
    public let managedObjectContext: NSManagedObjectContext

    /// Returns the section to place the passed object into.
    ///
    /// Where the block examines specific keys of the object, consider providing these keys in `sectionKeys` to avoid calls to the block when these keys haven't changed.
    ///
    /// This block may be replaced with another that returns a different section, if you do so, you must call `performFetch()` to refresh the fetched results.
    public var sectionForObject: (Entity) -> Section
    
    /// Keys that indicate an object may have changed section.
    ///
    /// When `nil`, `sectionForObject` will be called for every update to an object. When non-`nil`, `sectionForObject` will only be called if the value for a key listed in this set is updated.
    public var sectionKeys: Set<String>?
    
    /// The results of the fetch.
    ///
    /// The value is empty until `performFetch()` is called.
    public private(set) var fetchedObjects: [Entity] = []
    
    /// The sections objects are sored into.
    ///
    /// The value is empty until `performFetch()` is called. Each member is a `FetchedResultsSectionInfo` providing the identifier for the section, along with the objects sorted into it.
    public private(set) var sections: [FetchedResultsSectionInfo<Section, Entity>] = []
    
    /// Called to update a view based on changes to the results.
    ///
    /// Each member of the passed array is a `FetchedResultsChange` detailing the specific change. Index paths (including those for updates) always refer to the index path prior to the changes being applied, while the new index paths always refer to the index path after all changes have been applied.
    public let handleChanges: (([FetchedResultsChange<Section, Entity>]) -> Void)?

    public init(fetchRequest: NSFetchRequest, managedObjectContext: NSManagedObjectContext, sectionForObject: (Entity) -> Section, sectionKeys: Set<String>?, handleChanges: (([FetchedResultsChange<Section, Entity>]) -> Void)?) {
        self.fetchRequest = fetchRequest
        self.managedObjectContext = managedObjectContext
        
        self.sectionForObject = sectionForObject
        self.sectionKeys = sectionKeys
        
        self.handleChanges = handleChanges
        
        super.init()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(managedObjectContextObjectsDidChange(_:)), name: NSManagedObjectContextObjectsDidChangeNotification, object: self.managedObjectContext)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    /// Cache mapping Section to Index.
    private var sectionIndexes: [Section: Int] = [:]
    
    /// Rebuilds the `sectionIndexes` cache.
    private func rebuildSectionIndexes() {
        sectionIndexes = [:]
        
        for (index, sectionInfo) in sections.enumerate() {
            sectionIndexes[sectionInfo.name] = index
        }
    }

    /// Returns a new SectionInfo for `section` containing `object`.
    ///
    /// The object is added to both the `sections` list, and the `sectionIndexes` cache.
    private func makeSection(section section: Section, object: Entity) -> FetchedResultsSectionInfo<Section, Entity> {
        var sectionInfo = FetchedResultsSectionInfo<Section, Entity>(name: section)
        
        sectionInfo.objects.append(object)
        
        sectionIndexes[section] = sections.count
        sections.append(sectionInfo)
        
        return sectionInfo
    }

    /// Sorts the sections list.
    private func sortSections() {
        sections = sections.sort({ $0.name < $1.name })
        rebuildSectionIndexes()
    }
    
    /// Cache of sort descriptor keys used for the previous fetch.
    private var sortKeys: Set<String>?
    
    /// Cache mapping ObjectIdentifier to Section it can be found within.
    private var objectSections: [ObjectIdentifier: Section] = [:]
    
    /// Executes the fetch request.
    ///
    /// This must be called after creating the controller to populate the initial `fetchedObjects` and `sections`, and after making changes to the fetch request or changes that would change the section of any object.
    ///
    /// Normally changes to the fetched results caused by this method call will not result in `handleChanges` being called, and you should instead call a method such as `UITableView.reloadData()` to refresh the entire data set. This is almost always the most appropriate action since a large number of changes would be expected, including when changing a search predicate, sort order, etc.
    ///
    /// Sometimes however you may want the changes "animated", for example transitioning between editing and non-editing modes, in that case pass `notifyChanges: true`. The changes in the fetched results will be analyzed and `handleChanges` called with a list of the changes found.
    ///
    /// **Note:** this will not include any updates to the object values, since it assumed that merely changing the fetch request cannot change the values of the objects returned.
    ///
    /// - parameter notifyChanges: when `true`, the changes to the fetched results set are analyzed and `handleChanges` called. Default is `false`.
    public func performFetch(notifyChanges notifyChanges: Bool = false) throws {
        fetchedObjects = try managedObjectContext.executeFetchRequest(fetchRequest) as! [Entity]
        
        // Save the old sections if we need to examine it for changes. This is done after performing the fetch since that can cause pending changes to be committed, and the notification observer called, and we don't want to double-notify changes.
        let oldSections = sections

        sections = []
        objectSections = [:]
        sectionIndexes = [:]
        
        for object in fetchedObjects {
            let section = sectionForObject(object)
            objectSections[ObjectIdentifier(object)] = section
            
            if let sectionIndex = sectionIndexes[section] {
                sections[sectionIndex].objects.append(object)
            } else {
                makeSection(section: section, object: object)
            }
        }
        
        sortSections()
        
        if  notifyChanges {
            let changes = determineChanges(from: oldSections)
            handleChanges?(changes)
        }
        
        // Make a cache of the top-level keys that we used to sort the objects; when objects are updated later, we'll check the update keys against this set, and only re-sort when an update potentially changes the sort order.
        if let sortDescriptorKeys = fetchRequest.sortDescriptors?.flatMap({ $0.key?.componentsSeparatedByString(".").first }) {
            sortKeys = Set(sortDescriptorKeys)
        } else {
            sortKeys = nil
        }
    }
    
    /// Calls `handleChanges` with changes from `oldSections` to the current results set.
    ///
    /// - parameter from: section information for prior results set.
    private func determineChanges(from oldSections: [FetchedResultsSectionInfo<Section, Entity>]) -> [FetchedResultsChange<Section, Entity>] {
        var changes: [FetchedResultsChange<Section, Entity>] = []
        
        // Iterate over each of the sections from the prior results set, and objects within, checking the newer object cache to determine whether objects have been deleted, or moved out of a section to a new one. We build a map from object identifier to old section information during this process.
        var indexes: [ObjectIdentifier: (oldSection: Section, oldSectionIndex: Int, oldIndex: Int)] = [:]
        var priorDeletes: [Section: [Int]] = [:]
        for (oldSectionIndex, oldSectionInfo) in oldSections.enumerate() {
            let oldSection = oldSectionInfo.name
            
            priorDeletes[oldSection] = []
            for (oldIndex, object) in oldSectionInfo.objects.enumerate() {
                if let section = objectSections[ObjectIdentifier(object)] {
                    indexes[ObjectIdentifier(object)] = (oldSection: oldSection, oldSectionIndex: oldSectionIndex, oldIndex: oldIndex)
                    if section != oldSection {
                        // Object has been moved from this section to another.
                        priorDeletes[oldSection]!.append((priorDeletes[oldSection]!.last ?? 0) + 1)
                    } else {
                        // Object remains in the same section.
                        priorDeletes[oldSection]!.append(priorDeletes[oldSection]!.last ?? 0)
                    }
                } else {
                    // Object has been deleted.
                    changes.append(.Delete(object: object, indexPath: NSIndexPath(forRow: oldIndex, inSection: oldSectionIndex)))
                    priorDeletes[oldSection]!.append((priorDeletes[oldSection]!.last ?? 0) + 1)
                }
            }

            // Delete the section if has no index in the new results.
            if sectionIndexes[oldSection] == nil {
                // Strictly speaking this oldSectionInfo is wrong as it has members.
                changes.append(.DeleteSection(sectionInfo: oldSectionInfo, index: oldSectionIndex))
            }
        }
        
        // Now we iterate over each of the sections in the new results set, and objects within, using the information from the map we just built to detect inserts, as well as completing the handling of moves between and within sections with the new index paths.
        for (sectionIndex, sectionInfo) in sections.enumerate() {
            let section = sectionInfo.name
            
            // If the section didn't exist in the old results, insert it.
            let priorDeletes = priorDeletes[section]
            if priorDeletes == nil {
                // Strictly speaking this sectionInfo is wrong as it has members.
                changes.append(.InsertSection(sectionInfo: sectionInfo, newIndex: sectionIndex))
            }
            
            var priorInserts = 0
            for (index, object) in sectionInfo.objects.enumerate() {
                if let (oldSection, oldSectionIndex, oldIndex) = indexes[ObjectIdentifier(object)] {
                    if section != oldSection {
                        // Object has been moved into this section from another.
                        changes.append(.Move(object: object, indexPath: NSIndexPath(forRow: oldIndex, inSection: oldSectionIndex), newIndexPath: NSIndexPath(forRow: index, inSection: sectionIndex)))
                        priorInserts += 1
                    } else {
                        // The object has remained in the same section, we need to determine whether it's moved. We want to avoid false-positives caused by other objects moving out or into this section before it, so we create "adjusted indexes" which assume deleted objects never existed before, and inserted objects don't exist after, and compare those indexes instead.
                        let adjustedIndex = oldIndex - priorDeletes![oldIndex]
                        let adjustedNewIndex = index - priorInserts
                        
                        if adjustedIndex != adjustedNewIndex {
                            // Moved.
                            changes.append(.Move(object: object, indexPath: NSIndexPath(forRow: oldIndex, inSection: oldSectionIndex), newIndexPath: NSIndexPath(forRow: index, inSection: sectionIndex)))
                        }
                    }
                } else {
                    // Object was inserted.
                    changes.append(.Insert(object: object, newIndexPath: NSIndexPath(forRow: index, inSection: sectionIndex)))
                    priorInserts += 1
                }
            }
        }
        
        return changes
    }

    /// Called on changes to the managed object context.
    @objc private func managedObjectContextObjectsDidChange(notification: NSNotification) {
        assert(notification.name == NSManagedObjectContextObjectsDidChangeNotification, "Notification method called for wrong notification.")
        assert(notification.object === managedObjectContext, "Notification called for incorrect managed object context.")
        
        // Collect all of the objects together, rather than processing each key indvidually, since the handling is the same.
        var objects: Set<Entity> = []
        if let objectsSet = notification.userInfo?[NSInsertedObjectsKey] as? NSSet {
            objects.unionInPlace(objectsSet.allObjects as! [Entity])
        }
        if let objectsSet = notification.userInfo?[NSDeletedObjectsKey] as? NSSet {
            objects.unionInPlace(objectsSet.allObjects as! [Entity])
        }
        if let objectsSet = notification.userInfo?[NSUpdatedObjectsKey] as? NSSet {
            objects.unionInPlace(objectsSet.allObjects as! [Entity])
        }
        
        var changes: [FetchedResultsChange<Section, Entity>] = []
        var insertedSections: [Section] = []
        var insertedObjects: [Section: [(object: Entity, sectionIndex: Int?, index: Int?)]] = [:]
        var deleteIndexes: [Section: NSMutableIndexSet] = [:]

        // For each object, we fundamentally check two things: is it in the existing results, and if not, does it match the predicate and thus should be inserted?
        for object in objects {
            guard object.entity === fetchRequest.entity else { continue }
            
            if let section = objectSections[ObjectIdentifier(object)] {
                let sectionIndex = sectionIndexes[section]!
                let index = sections[sectionIndex].objects.indexOf(object)!

                if object.deleted || !(fetchRequest.predicate?.evaluateWithObject(object) ?? true) {
                    // Object was deleted, or previously did, but no now longer does, match the predicate.
                    objectSections[ObjectIdentifier(object)] = nil
                    
                    if deleteIndexes[section] == nil { deleteIndexes[section] = NSMutableIndexSet() }
                    deleteIndexes[section]!.addIndex(index)
                    
                    // Since we don't care about the indexes remaining stable, we can directly remove objects here.
                    fetchedObjects.removeAtIndex(fetchedObjects.indexOf(object)!)
                    
                    changes.append(.Delete(object: object, indexPath: NSIndexPath(forRow: index, inSection: sectionIndex)))
                    continue
                }
                
                // Determine the new section for the object, optimizing to avoid this where possible.
                let changedValues = object.changedValuesForCurrentEvent().keys
                let newSection: Section
                if let sectionKeys = sectionKeys {
                    if sectionKeys.isSubsetOf(changedValues) {
                        newSection = sectionForObject(object)
                    } else {
                        newSection = section
                    }
                } else {
                    newSection = sectionForObject(object)
                }
                
                let insertRecord = (object: object, sectionIndex: Int?.Some(sectionIndex), index: Int?.Some(index))
                if section != newSection {
                    // Object has changed section.
                    objectSections[ObjectIdentifier(object)] = newSection
                    
                    if deleteIndexes[section] == nil { deleteIndexes[section] = NSMutableIndexSet() }
                    deleteIndexes[section]!.addIndex(index)
                    
                    if let newSectionIndex = sectionIndexes[newSection] {
                        sections[newSectionIndex].objects.append(object)
                        
                        if insertedObjects[newSection] == nil { insertedObjects[newSection] = [] }
                        insertedObjects[newSection]!.append(insertRecord)
                    } else {
                        makeSection(section: newSection, object: object)
                        
                        insertedSections.append(newSection)
                        insertedObjects[newSection] = [insertRecord]
                    }
                } else if let sortKeys = sortKeys where sortKeys.isSubsetOf(changedValues) {
                    // Object may have moved within the sort order.
                    if insertedObjects[section] == nil { insertedObjects[section] = [] }
                    insertedObjects[section]!.append(insertRecord)
                } else {
                    // Object has changed in some other way.
                    changes.append(.Update(object: object, indexPath: NSIndexPath(forRow: index, inSection: sectionIndex)))
                }

            } else if fetchRequest.predicate?.evaluateWithObject(object) ?? true {
                // Object previous did not, but now does, match the predicate. This becomes an insert.
                let section = sectionForObject(object)
                objectSections[ObjectIdentifier(object)] = section
                
                let insertRecord = (object: object, sectionIndex: Int?.None, index: Int?.None)
                if let sectionIndex = sectionIndexes[section] {
                    sections[sectionIndex].objects.append(object)
                    
                    if insertedObjects[section] == nil { insertedObjects[section] = [] }
                    insertedObjects[section]!.append(insertRecord)
                } else {
                    makeSection(section: section, object: object)
                    
                    insertedSections.append(section)
                    insertedObjects[section] = [insertRecord]
                }
                
                fetchedObjects.append(object)
            }
        }
        
        // Use the complete list of objects to be removed, including those moving out of a section to another, to do a single-pass of all removes. If a section becomes empty, we'll delete it in a second pass after (so indexes remain consistent).
        let deleteSectionIndexes = NSMutableIndexSet()
        
        for (section, indexes) in deleteIndexes {
            let sectionIndex = sectionIndexes[section]!
            
            for index in indexes.reverse() {
                sections[sectionIndex].objects.removeAtIndex(index)
            }
            
            if sections[sectionIndex].objects.count == 0 {
                deleteSectionIndexes.addIndex(sectionIndex)

                changes.append(.DeleteSection(sectionInfo: sections[sectionIndex], index: sectionIndex))
            }
        }
        
        for sectionIndex in deleteSectionIndexes.reverse() {
            sections.removeAtIndex(sectionIndex)
        }

        // The sections list now contains the final list of sections, but the indexes are potentially wrong. If we inserted any sections, we re-sort the list and rebuild the cache; if we deleted any, we just rebuild the cache. Section indexes are final after this, so we can build those changes.
        if insertedSections.count > 0 {
            sortSections()
            
            for newSection in insertedSections {
                let newSectionIndex = sectionIndexes[newSection]!
                
                changes.append(.InsertSection(sectionInfo: sections[newSectionIndex], newIndex: newSectionIndex))
            }
        } else if deleteSectionIndexes.count > 0 {
            rebuildSectionIndexes()
        }

        // Finally we can iterate the set of inserted and moved objects, re-sort the sections, and then to generate the changes with the correct new indexes for them.
        if insertedObjects.count > 0 {
            for (newSection, insertRecords) in insertedObjects {
                let newSectionIndex = sectionIndexes[newSection]!

                if let sortDescriptors = fetchRequest.sortDescriptors {
                    sections[newSectionIndex].objects = (sections[newSectionIndex].objects as NSArray).sortedArrayUsingDescriptors(sortDescriptors) as! [Entity]
                }
                
                for (object, sectionIndex, index) in insertRecords {
                    let newIndex = sections[newSectionIndex].objects.indexOf(object)!
                    
                    if let index = index, sectionIndex = sectionIndex {
                        changes.append(.Move(object: object, indexPath: NSIndexPath(forRow: index, inSection: sectionIndex), newIndexPath: NSIndexPath(forRow: newIndex, inSection: newSectionIndex)))
                    } else {
                        changes.append(.Insert(object: object, newIndexPath: NSIndexPath(forRow: newIndex, inSection: newSectionIndex)))
                    }
                }
            }
        
            if let sortDescriptors = fetchRequest.sortDescriptors {
                fetchedObjects = (fetchedObjects as NSArray).sortedArrayUsingDescriptors(sortDescriptors) as! [Entity]
            }
        }

        handleChanges?(changes)
    }
    
}

/// Types of changes passed to `handleChanges`.
///
/// - `InsertSection`: `sectionInfo` was inserted at `newIndex`.
/// - `DeleteSection`: `sectionInfo` was deleted from `index`.
/// - `Insert`: `object` was inserted at `newIndexPath`.
/// - `Delete`: `object` at `indexPath` was deleted.
/// - `Move`: the object `object` was moved from `indexPath` to `newIndexPath`.
/// - `Update`: the object `object` at `indexPath` was updated.
public enum FetchedResultsChange<Section, Entity : NSManagedObject> {
    case InsertSection(sectionInfo: FetchedResultsSectionInfo<Section, Entity>, newIndex: Int)
    case DeleteSection(sectionInfo: FetchedResultsSectionInfo<Section, Entity>, index: Int)

    case Insert(object: Entity, newIndexPath: NSIndexPath)
    case Delete(object: Entity, indexPath: NSIndexPath)
    case Move(object: Entity, indexPath: NSIndexPath, newIndexPath: NSIndexPath)
    case Update(object: Entity, indexPath: NSIndexPath)
}

/// Section information for `FetchedResultsController`.
public struct FetchedResultsSectionInfo<Section, Entity : NSManagedObject> {
    /// Identifier of the section.
    public private(set) var name: Section
    
    /// Objects sorted into it.
    public private(set) var objects: [Entity]
    
    private init(name: Section) {
        self.name = name
        self.objects = []
    }
    
}


