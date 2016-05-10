//
//  FetchedResultsControllerTests.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 3/14/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import CoreData
import XCTest
@testable import DungeonMaster

class FetchedResultsControllerTests : XCTestCase {
    
    let sampleData = [
        ( "Scott", 35, 0 ),
        ( "Shane", 29, 0 ),
        ( "Tague", 43, 0 ),
        ( "Jinger", 30, 1 ),
        ( "Sam", 34, 1 ),
        ( "Caitlin", 13, 1 )
    ]
    var sampleObjects: [String:NSManagedObject] = [:]
    
    func makeEntityDescription(name: String) -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = name
        
        let nameAttribute = NSAttributeDescription()
        nameAttribute.name = "name"
        nameAttribute.attributeType = .StringAttributeType
        entity.properties.append(nameAttribute)
        
        let ageAttribute = NSAttributeDescription()
        ageAttribute.name = "age"
        ageAttribute.attributeType = .Integer16AttributeType
        entity.properties.append(ageAttribute)
        
        let sexAttribute = NSAttributeDescription()
        sexAttribute.name = "sex"
        sexAttribute.attributeType = .Integer16AttributeType
        entity.properties.append(sexAttribute)

        return entity
    }
    
    lazy var managedObjectModel: NSManagedObjectModel = { [unowned self] in
        let model = NSManagedObjectModel()
        
        let person = self.makeEntityDescription("Person")
        model.entities.append(person)
        
        let npc = self.makeEntityDescription("NPC")
        model.entities.append(npc)
        
        return model
    }()
    
    var managedObjectContext: NSManagedObjectContext!
    
    func makePerson(name name: String, age: Int, sex: Int) -> NSManagedObject {
        let personEntity = NSEntityDescription.entityForName("Person", inManagedObjectContext: managedObjectContext)!
        
        let person = NSManagedObject(entity: personEntity, insertIntoManagedObjectContext: managedObjectContext)
        person.setValue(name, forKey: "name")
        person.setValue(age, forKey: "age")
        person.setValue(sex, forKey: "sex")
        
        sampleObjects[name] = person

        return person
    }
    
    func removePerson(name: String) -> NSManagedObject {
        let person = sampleObjects[name]!
        
        sampleObjects[name] = nil
        
        managedObjectContext.deleteObject(person)
        
        return person
    }
    
    func checkResults<T>(controller: FetchedResultsController<T, NSManagedObject>, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?, sections: [(T, NSPredicate?)]) {
        var expectedObjects: [NSManagedObject] = Array(sampleObjects.values)
        if let predicate = predicate {
            expectedObjects = (expectedObjects as NSArray).filteredArrayUsingPredicate(predicate) as! [NSManagedObject]
        }
        if let sortDescriptors = sortDescriptors {
            expectedObjects = (expectedObjects as NSArray).sortedArrayUsingDescriptors(sortDescriptors) as! [NSManagedObject]
        }
        
        XCTAssertNotNil(controller.fetchedObjects, "Expected fetched objects after performing fetch.")
        XCTAssertEqual(controller.fetchedObjects.count, expectedObjects.count, "Count of fetched objects was incorrect.")
        
        if let _ = sortDescriptors {
            let expectedNames = expectedObjects.map({ $0.valueForKey("name") as! String })
            let fetchedNames = controller.fetchedObjects.map({ $0.valueForKey("name") as! String })
            
            XCTAssertEqual(expectedNames, fetchedNames, "List of fetched objects was incorrect.")
        } else {
            let expectedNames = Set(expectedObjects.map({ $0.valueForKey("name") as! String }))
            let fetchedNames = Set(controller.fetchedObjects.map({ $0.valueForKey("name") as! String }))
            
            XCTAssertEqual(expectedNames, fetchedNames, "Set of fetched objects was incorrect.")
        }
        
        XCTAssertNotNil(controller.sections, "Expected list of sections after performing fetch.")
        XCTAssertEqual(controller.sections.count, sections.count, "Count of sections was incorrect.")
        
        for (sectionIndex, sectionInfo) in sections.enumerate() {
            let (name, sectionPredicate) = sectionInfo
            let section = controller.sections[sectionIndex]
            
            var sectionObjects = expectedObjects
            if let sectionPredicate = sectionPredicate {
                sectionObjects = (sectionObjects as NSArray).filteredArrayUsingPredicate(sectionPredicate) as! [NSManagedObject]
            }
            
            XCTAssertEqual(section.name, name, "Section name was incorrect.")
            XCTAssertEqual(section.objects.count, sectionObjects.count, "Count of objects in section was incorrect.")
            XCTAssertNotNil(section.objects, "Expected objects list for section.")
            
            if let _ = sortDescriptors {
                let expectedNames = sectionObjects.map({ $0.valueForKey("name") as! String })
                let fetchedNames = section.objects.map({ $0.valueForKey("name") as! String })
                
                XCTAssertEqual(expectedNames, fetchedNames, "List of objects in section incorrect.")
            } else {
                let expectedNames = Set(sectionObjects.map({ $0.valueForKey("name")  as! String }))
                let fetchedNames = Set(section.objects.map({ $0.valueForKey("name") as! String }))
                
                XCTAssertEqual(expectedNames, fetchedNames, "Set of objects in section was incorrect.")
            }
            
            for (index, object) in section.objects.enumerate() {
                let indexPath = NSIndexPath(forRow: index, inSection: sectionIndex)
                XCTAssertEqual(controller.indexPath(of: object), indexPath, "Index path of object was incorrect.")
                XCTAssert(controller.object(at: indexPath) === object, "Object at index path was incorrect.")
            }
        }
    }

    override func setUp() {
        super.setUp()
        
        // Set up the in-memory store.
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        try! persistentStoreCoordinator.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil)
        
        managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        // Set up the sample data.
        sampleObjects = [:]
        for (name, age, sex) in sampleData {
            makePerson(name: name, age: age, sex: sex)
        }
        
        try! managedObjectContext.save()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // MARK: - Request/results tests

    func testSingleSection() {
        // Make the simplest fetch request that we can.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        
        // Create the controller, return the same value for all sections.
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { _ in "" }, sectionKeys: nil, handleChanges: nil)
        try! controller.performFetch()
        
        // Expect all the objects to be returned, and a single section containing the same set.
        checkResults(controller, predicate: nil, sortDescriptors: nil, sections: [ ("", nil) ])
    }
    
    func testSingleSectionWithPredicate() {
        // Make a fetch request with a predicate.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.predicate = NSPredicate(format: "age > 30")

        // Create the controller, return the same value for all sections.
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { _ in "" }, sectionKeys: nil, handleChanges: nil)
        try! controller.performFetch()
        
        // Expect the matching subset of objects to be returned, and a single section containing the same set.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: nil, sections: [ ("", nil) ])
    }
    
    func testSingleSectionWithSort() {
        // Make a fetch request with sort descriptors.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]

        // Create the controller, return the same value for all sections.
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { _ in "" }, sectionKeys: nil, handleChanges: nil)
        try! controller.performFetch()
        
        // Expect all the objects to be returned in the right order, and a single section containing the same list.
        checkResults(controller, predicate: nil, sortDescriptors: fetchRequest.sortDescriptors, sections: [ ("", nil) ])
    }

    func testSingleSectionWithPredicateAndSort() {
        // Make a fetch request with a predicate and sort descriptors.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.predicate = NSPredicate(format: "age > 30")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, return the same value for all sections.
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { _ in "" }, sectionKeys: nil, handleChanges: nil)
        try! controller.performFetch()
        
        // Expect the matching subset of objects to be returned in the right order, and a single section containing the same list.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ ("", nil) ])
    }

    func testMultipleSection() {
        // Make the simplest fetch request that we can.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        
        // Create the controller, section the results by sex.
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: nil)
        try! controller.performFetch()
        
        // Expect all of the objects to be returned, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: nil, sortDescriptors: nil, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }
    
    func testMultipleSectionsWithPredicate() {
        // Make a fetch request with a predicate.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.predicate = NSPredicate(format: "age > 30")
        
        // Create the controller, section the results by sex.
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: nil)
        try! controller.performFetch()
        
        // Expect the matching subset of objects to be returned, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: nil, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }
    
    func testMultipleSectionsWithSort() {
        // Make a fetch request with sort descriptors.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex.
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: nil)
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }
    
    func testMultipleSectionsWithPredicateAndSort() {
        // Make a fetch request with a predicate and sort descriptors.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.predicate = NSPredicate(format: "age > 30")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex.
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: nil)
        try! controller.performFetch()
        
        // Expect the matching subset of objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }
    
    // MARK: - Insertion tests
    
    func testInsertSingleItem() {
        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]

        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Insert the item. Expect the fetched objects and appropriate section counts to go up, and the new object to be inserted in both.
        let oldFetchedObjects = Set(controller.fetchedObjects)
        let oldSectionObjects = Set(controller.sections[0].objects)
        
        let newObject = makePerson(name: "Ryan", age: 31, sex: 0)
        try! managedObjectContext.save()
        
        XCTAssertEqual(controller.fetchedObjects.count, oldFetchedObjects.count + 1, "Expected increase in object count.")
        XCTAssertEqual(controller.sections[0].objects.count, oldSectionObjects.count + 1, "Expected increase in section object count.")

        let newFetchedObjects = Set(controller.fetchedObjects).subtract(oldFetchedObjects)
        let newSectionObjects = Set(controller.sections[0].objects).subtract(oldSectionObjects)
        
        XCTAssertEqual(newFetchedObjects, Set([newObject]), "Expected object was not present in fetched objects list.")
        XCTAssertEqual(newSectionObjects, Set([newObject]), "Expected object was not present in section objects list.")
        
        switch changes.removeFirst() {
        case .Insert(newObject, NSIndexPath(forRow: 1, inSection: 0)):
            break
        default:
            XCTFail("Incorrect change.")
        }

        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }
    
    func testInsertTwoItemsIntoSameSection() {
        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Insert the items. Expect the fetched objects and appropriate section counts to go up, and the new objects to be inserted in both.
        let oldFetchedObjects = Set(controller.fetchedObjects)
        let oldSectionObjects = Set(controller.sections[0].objects)
        
        let newObject1 = makePerson(name: "Ryan", age: 31, sex: 0)
        let newObject2 = makePerson(name: "Michael", age: 32, sex: 0)
        try! managedObjectContext.save()
        
        XCTAssertEqual(controller.fetchedObjects.count, oldFetchedObjects.count + 2, "Expected increase in object count.")
        XCTAssertEqual(controller.sections[0].objects.count, oldSectionObjects.count + 2, "Expected increase in section object count.")
        
        let newFetchedObjects = Set(controller.fetchedObjects).subtract(oldFetchedObjects)
        let newSectionObjects = Set(controller.sections[0].objects).subtract(oldSectionObjects)
        
        XCTAssertEqual(newFetchedObjects, Set([newObject1, newObject2]), "Expected object was not present in fetched objects list.")
        XCTAssertEqual(newSectionObjects, Set([newObject1, newObject2]), "Expected object was not present in section objects list.")
        
        for _ in 0..<2 {
            switch changes.removeFirst() {
            case .Insert(newObject1, NSIndexPath(forRow: 1, inSection: 0)):
                break
            case .Insert(newObject2, NSIndexPath(forRow: 2, inSection: 0)):
                break
            default:
                XCTFail("Incorrect change.")
            }
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")

        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }

    func testInsertTwoItemsIntoDifferentSections() {
        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Insert the items. Expect the fetched objects and appropriate section counts to go up, and the new objects to be inserted in both.
        let oldFetchedObjects = Set(controller.fetchedObjects)
        let oldSection0Objects = Set(controller.sections[0].objects)
        let oldSection1Objects = Set(controller.sections[1].objects)

        let newObject1 = makePerson(name: "Ryan", age: 31, sex: 0)
        let newObject2 = makePerson(name: "Sallyanne", age: 56, sex: 1)
        try! managedObjectContext.save()
        
        XCTAssertEqual(controller.fetchedObjects.count, oldFetchedObjects.count + 2, "Expected increase in object count.")
        XCTAssertEqual(controller.sections[0].objects.count, oldSection0Objects.count + 1, "Expected increase in section object count.")
        XCTAssertEqual(controller.sections[1].objects.count, oldSection1Objects.count + 1, "Expected increase in section object count.")

        let newFetchedObjects = Set(controller.fetchedObjects).subtract(oldFetchedObjects)
        let newSection0Objects = Set(controller.sections[0].objects).subtract(oldSection0Objects)
        let newSection1Objects = Set(controller.sections[1].objects).subtract(oldSection1Objects)

        XCTAssertEqual(newFetchedObjects, Set([newObject1, newObject2]), "Expected object was not present in fetched objects list.")
        XCTAssertEqual(newSection0Objects, Set([newObject1]), "Expected object was not present in section objects list.")
        XCTAssertEqual(newSection1Objects, Set([newObject2]), "Expected object was not present in section objects list.")

        for _ in 0..<2 {
            switch changes.removeFirst() {
            case .Insert(newObject1, NSIndexPath(forRow: 1, inSection: 0)):
                break
            case .Insert(newObject2, NSIndexPath(forRow: 3, inSection: 1)):
                break
            default:
                XCTFail("Incorrect change.")
            }
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
    
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }

    func testInsertItemMatchingPredicate() {
        // Make a fetch request with a predicate, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.predicate = NSPredicate(format: "age > 30")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect the matching subset of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Insert the item. Expect the fetched objects and appropriate section counts to go up, and the new object to be inserted in both.
        let oldFetchedObjects = Set(controller.fetchedObjects)
        let oldSectionObjects = Set(controller.sections[0].objects)
        
        let newObject = makePerson(name: "Ryan", age: 31, sex: 0)
        try! managedObjectContext.save()
        
        XCTAssertEqual(controller.fetchedObjects.count, oldFetchedObjects.count + 1, "Expected increase in object count.")
        XCTAssertEqual(controller.sections[0].objects.count, oldSectionObjects.count + 1, "Expected increase in section object count.")
        
        let newFetchedObjects = Set(controller.fetchedObjects).subtract(oldFetchedObjects)
        let newSectionObjects = Set(controller.sections[0].objects).subtract(oldSectionObjects)
        
        XCTAssertEqual(newFetchedObjects, Set([newObject]), "Expected object was not present in fetched objects list.")
        XCTAssertEqual(newSectionObjects, Set([newObject]), "Expected object was not present in section objects list.")
        
        switch changes.removeFirst() {
        case .Insert(newObject, NSIndexPath(forRow: 0, inSection: 0)):
            break
        default:
            XCTFail("Incorrect change.")
        }

        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")

        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }

    func testInsertItemNotMatchingPredicate() {
        // Make a fetch request with a predicate, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.predicate = NSPredicate(format: "age > 30")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect the matching subset of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Insert the item. Expect no change in the results count, since the item does not match the predicate.
        let oldFetchedObjects = Set(controller.fetchedObjects)
        let oldSectionObjects = Set(controller.sections[1].objects)
        
        makePerson(name: "Taylor", age: 26, sex: 1)
        try! managedObjectContext.save()
        
        XCTAssertEqual(controller.fetchedObjects.count, oldFetchedObjects.count, "Expected no change in object count.")
        XCTAssertEqual(controller.sections[1].objects.count, oldSectionObjects.count, "Expected no change in section object count.")
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }

    func testInsertSingleItemIntoNewSection() {
        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Insert the item. Expect the fetched objects count to go up, as well as the section count to go up, and the new object to be inserted into the new section.
        let oldFetchedObjects = Set(controller.fetchedObjects)
        let oldSectionCount = controller.sections.count
        
        let newObject = makePerson(name: "Rachel", age: 24, sex: 2)
        try! managedObjectContext.save()
        
        XCTAssertEqual(controller.fetchedObjects.count, oldFetchedObjects.count + 1, "Expected increase in object count.")
        XCTAssertEqual(controller.sections.count, oldSectionCount + 1, "Expected increase in section count.")
        
        let newFetchedObjects = Set(controller.fetchedObjects).subtract(oldFetchedObjects)
        let newSectionObjects = Set(controller.sections[2].objects)
        
        XCTAssertEqual(newFetchedObjects, Set([newObject]), "Expected object was not present in fetched objects list.")
        XCTAssertEqual(newSectionObjects, Set([newObject]), "Expected object was not present in objects list for new section.")
        
        switch changes.removeFirst() {
        case .InsertSection(sectionInfo: _, newIndex: 2):
            break
        default:
            XCTFail("Incorrect change.")
        }

        switch changes.removeFirst() {
        case .Insert(newObject, NSIndexPath(forRow: 0, inSection: 2)):
            break
        default:
            XCTFail("Incorrect change.")
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")

        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")), (2, NSPredicate(format: "sex == 2")) ])
    }
    
    func testInsertTwoItemsIntoNewSection() {
        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Insert the items. Expect the fetched objects count to go up, as well as the section count to go up, and the new objects to be inserted into the new section.
        let oldFetchedObjects = Set(controller.fetchedObjects)
        let oldSectionCount = controller.sections.count
        
        let newObject1 = makePerson(name: "Rachel", age: 24, sex: 2)
        let newObject2 = makePerson(name: "Alex", age: 37, sex: 2)
        try! managedObjectContext.save()
        
        XCTAssertEqual(controller.fetchedObjects.count, oldFetchedObjects.count + 2, "Expected increase in object count.")
        XCTAssertEqual(controller.sections.count, oldSectionCount + 1, "Expected increase in section count.")
        
        let newFetchedObjects = Set(controller.fetchedObjects).subtract(oldFetchedObjects)
        let newSectionObjects = Set(controller.sections[2].objects)
        
        XCTAssertEqual(newFetchedObjects, Set([newObject1, newObject2]), "Expected object was not present in fetched objects list.")
        XCTAssertEqual(newSectionObjects, Set([newObject1, newObject2]), "Expected object was not present in objects list for new section.")
        
        switch changes.removeFirst() {
        case .InsertSection(sectionInfo: _, newIndex: 2):
            break
        default:
            XCTFail("Incorrect change.")
        }

        for _ in 0..<2 {
            switch changes.removeFirst() {
            case .Insert(newObject1, NSIndexPath(forRow: 0, inSection: 2)):
                break
            case .Insert(newObject2, NSIndexPath(forRow: 1, inSection: 2)):
                break
            default:
                XCTFail("Incorrect change.")
            }
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")

        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")), (2, NSPredicate(format: "sex == 2")) ])
    }
    
    func testInsertOtherItem() {
        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Create an item of a different type of entity. Expect nothing to change.
        let oldFetchedObjects = Set(controller.fetchedObjects)
        let oldSectionObjects = Set(controller.sections[0].objects)

        let entity = NSEntityDescription.entityForName("NPC", inManagedObjectContext: managedObjectContext)!
        
        let object = NSManagedObject(entity: entity, insertIntoManagedObjectContext: managedObjectContext)
        object.setValue("Jordan", forKey: "name")
        object.setValue(30, forKey: "age")
        object.setValue(0, forKey: "sex")

        try! managedObjectContext.save()
        
        XCTAssertEqual(controller.fetchedObjects.count, oldFetchedObjects.count, "Expected no change in object count.")
        XCTAssertEqual(controller.sections[0].objects.count, oldSectionObjects.count, "Expected no change in section object count.")
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }

    // MARK: - Deletion tests

    func testDeleteSingleItem() {
        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Delete the item. Expect the fetched objects and appropriate section counts to go down, and the removed object to be removed from both.
        let oldFetchedObjects = Set(controller.fetchedObjects)
        let oldSectionObjects = Set(controller.sections[1].objects)
        
        let deletedObject = removePerson("Sam")
        try! managedObjectContext.save()
        
        XCTAssertEqual(controller.fetchedObjects.count, oldFetchedObjects.count - 1, "Expected decrease in object count.")
        XCTAssertEqual(controller.sections[1].objects.count, oldSectionObjects.count - 1, "Expected decrease in section object count.")
        
        let deletedFetchedObjects = oldFetchedObjects.subtract(controller.fetchedObjects)
        let deletedSectionObjects = oldSectionObjects.subtract(controller.sections[1].objects)
        
        XCTAssertEqual(deletedFetchedObjects, Set([deletedObject]), "Expected object was present in fetched objects list.")
        XCTAssertEqual(deletedSectionObjects, Set([deletedObject]), "Expected object was present in section objects list.")
        
        switch changes.removeFirst() {
        case .Delete(object: deletedObject, indexPath: NSIndexPath(forRow: 2, inSection: 1)):
            break
        default:
            XCTFail("Incorrect change.")
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }

    func testDeleteTwoItemsFromSameSection() {
        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Delete the items. Expect the fetched objects and appropriate section counts to go down, and the removed objects to be removed from both.
        let oldFetchedObjects = Set(controller.fetchedObjects)
        let oldSectionObjects = Set(controller.sections[1].objects)
        
        let deletedObject1 = removePerson("Sam")
        let deletedObject2 = removePerson("Caitlin")
        try! managedObjectContext.save()
        
        XCTAssertEqual(controller.fetchedObjects.count, oldFetchedObjects.count - 2, "Expected decrease in object count.")
        XCTAssertEqual(controller.sections[1].objects.count, oldSectionObjects.count - 2, "Expected decrease in section object count.")
        
        let deletedFetchedObjects = oldFetchedObjects.subtract(controller.fetchedObjects)
        let deletedSectionObjects = oldSectionObjects.subtract(controller.sections[1].objects)
        
        XCTAssertEqual(deletedFetchedObjects, Set([deletedObject1, deletedObject2]), "Expected object was present in fetched objects list.")
        XCTAssertEqual(deletedSectionObjects, Set([deletedObject1, deletedObject2]), "Expected object was present in section objects list.")
        
        for _ in 0..<2 {
            switch changes.removeFirst() {
            case .Delete(object: deletedObject1, indexPath: NSIndexPath(forRow: 2, inSection: 1)):
                break
            case .Delete(object: deletedObject2, indexPath: NSIndexPath(forRow: 0, inSection: 1)):
                break
            default:
                XCTFail("Incorrect change.")
            }
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }

    func testDeleteTwoItemsFromDifferentSections() {
        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Delete the items. Expect the fetched objects and appropriate section counts to go down, and the removed objects to be removed from both.
        let oldFetchedObjects = Set(controller.fetchedObjects)
        let oldSection0Objects = Set(controller.sections[0].objects)
        let oldSection1Objects = Set(controller.sections[1].objects)
        
        let deletedObject1 = removePerson("Shane")
        let deletedObject2 = removePerson("Caitlin")
        try! managedObjectContext.save()
        
        XCTAssertEqual(controller.fetchedObjects.count, oldFetchedObjects.count - 2, "Expected decrease in object count.")
        XCTAssertEqual(controller.sections[0].objects.count, oldSection0Objects.count - 1, "Expected decrease in section object count.")
        XCTAssertEqual(controller.sections[1].objects.count, oldSection1Objects.count - 1, "Expected decrease in section object count.")
        
        let deletedFetchedObjects = oldFetchedObjects.subtract(controller.fetchedObjects)
        let deletedSection0Objects = oldSection0Objects.subtract(controller.sections[0].objects)
        let deletedSection1Objects = oldSection1Objects.subtract(controller.sections[1].objects)

        XCTAssertEqual(deletedFetchedObjects, Set([deletedObject1, deletedObject2]), "Expected object was present in fetched objects list.")
        XCTAssertEqual(deletedSection0Objects, Set([deletedObject1]), "Expected object was present in section objects list.")
        XCTAssertEqual(deletedSection1Objects, Set([deletedObject2]), "Expected object was present in section objects list.")

        for _ in 0..<2 {
            switch changes.removeFirst() {
            case .Delete(object: deletedObject1, indexPath: NSIndexPath(forRow: 0, inSection: 0)):
                break
            case .Delete(object: deletedObject2, indexPath: NSIndexPath(forRow: 0, inSection: 1)):
                break
            default:
                XCTFail("Incorrect change.")
            }
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }

    func testDeleteItemMatchingPredicate() {
        // Make a fetch request with a predicate, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.predicate = NSPredicate(format: "age > 30")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Delete the item. Expect the fetched objects and appropriate section counts to go down, and the removed object to be removed from both.
        let oldFetchedObjects = Set(controller.fetchedObjects)
        let oldSectionObjects = Set(controller.sections[0].objects)
        
        let deletedObject = removePerson("Scott")
        try! managedObjectContext.save()
        
        XCTAssertEqual(controller.fetchedObjects.count, oldFetchedObjects.count - 1, "Expected decrease in object count.")
        XCTAssertEqual(controller.sections[0].objects.count, oldSectionObjects.count - 1, "Expected decrease in section object count.")
        
        let deletedFetchedObjects = oldFetchedObjects.subtract(controller.fetchedObjects)
        let deletedSectionObjects = oldSectionObjects.subtract(controller.sections[0].objects)
        
        XCTAssertEqual(deletedFetchedObjects, Set([deletedObject]), "Expected object was present in fetched objects list.")
        XCTAssertEqual(deletedSectionObjects, Set([deletedObject]), "Expected object was present in section objects list.")
        
        switch changes.removeFirst() {
        case .Delete(object: deletedObject, indexPath: NSIndexPath(forRow: 0, inSection: 0)):
            break
        default:
            XCTFail("Incorrect change.")
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }

    func testDeleteItemNotMatchingPredicate() {
        // Make a fetch request with a predicate, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.predicate = NSPredicate(format: "age > 30")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Delete the item. Expect the fetched objects and appropriate section counts to remain the same, since the object shouldn't have been in the results.
        let oldFetchedObjects = Set(controller.fetchedObjects)
        let oldSectionObjects = Set(controller.sections[1].objects)
        
        removePerson("Caitlin")
        try! managedObjectContext.save()
        
        XCTAssertEqual(controller.fetchedObjects.count, oldFetchedObjects.count, "Expected no change in object count.")
        XCTAssertEqual(controller.sections[1].objects.count, oldSectionObjects.count, "Expected no change in section object count.")
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }
    
    func testDeleteSingleItemAndDeleteSection() {
        // Insert an item into a new section so that we have something to delete.
        makePerson(name: "Rachel", age: 24, sex: 2)
        try! managedObjectContext.save()

        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")), (2, NSPredicate(format: "sex == 2")) ])
        
        // Delete the item. Expect the fetched objects and section count to go down, and the removed object to be removed, followed by the section removed.
        let oldFetchedObjects = Set(controller.fetchedObjects)
        let oldSectionCount = controller.sections.count
        
        let deletedObject = removePerson("Rachel")
        try! managedObjectContext.save()
        
        XCTAssertEqual(controller.fetchedObjects.count, oldFetchedObjects.count - 1, "Expected decrease in object count.")
        XCTAssertEqual(controller.sections.count, oldSectionCount - 1, "Expected decrease in section count.")
        
        let deletedFetchedObjects = oldFetchedObjects.subtract(controller.fetchedObjects)
        
        XCTAssertEqual(deletedFetchedObjects, Set([deletedObject]), "Expected object was present in fetched objects list.")
        
        switch changes.removeFirst() {
        case .Delete(object: deletedObject, indexPath: NSIndexPath(forRow: 0, inSection: 2)):
            break
        default:
            XCTFail("Incorrect change.")
        }
        
        switch changes.removeFirst() {
        case .DeleteSection(sectionInfo: _, index: 2):
            break
        default:
            XCTFail("Incorrect change.")
        }

        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }

    func testDeleteTwoItemsAndDeleteSection() {
        // Insert items into a new section so that we have something to delete.
        makePerson(name: "Rachel", age: 24, sex: 2)
        makePerson(name: "Alex", age: 37, sex: 2)
        try! managedObjectContext.save()
        
        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")), (2, NSPredicate(format: "sex == 2")) ])
        
        // Delete the item. Expect the fetched objects and section count to go down, and the removed object to be removed, followed by the section removed.
        let oldFetchedObjects = Set(controller.fetchedObjects)
        let oldSectionCount = controller.sections.count
        
        let deletedObject1 = removePerson("Rachel")
        let deletedObject2 = removePerson("Alex")
        try! managedObjectContext.save()
        
        XCTAssertEqual(controller.fetchedObjects.count, oldFetchedObjects.count - 2, "Expected decrease in object count.")
        XCTAssertEqual(controller.sections.count, oldSectionCount - 1, "Expected decrease in section count.")
        
        let deletedFetchedObjects = oldFetchedObjects.subtract(controller.fetchedObjects)
        
        XCTAssertEqual(deletedFetchedObjects, Set([deletedObject1, deletedObject2]), "Expected object was present in fetched objects list.")
        
        for _ in 0..<2 {
            switch changes.removeFirst() {
            case .Delete(object: deletedObject1, indexPath: NSIndexPath(forRow: 0, inSection: 2)):
                break
            case .Delete(object: deletedObject2, indexPath: NSIndexPath(forRow: 1, inSection: 2)):
                break
            default:
                XCTFail("Incorrect change.")
            }
        }
    
        switch changes.removeFirst() {
        case .DeleteSection(sectionInfo: _, index: 2):
            break
        default:
            XCTFail("Incorrect change.")
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }
    
    func testDeleteOtherItem() {
        // Create an item of the other type so we have something to delete.
        let entity = NSEntityDescription.entityForName("NPC", inManagedObjectContext: managedObjectContext)!
        
        let object = NSManagedObject(entity: entity, insertIntoManagedObjectContext: managedObjectContext)
        object.setValue("Jordan", forKey: "name")
        object.setValue(30, forKey: "age")
        object.setValue(0, forKey: "sex")
        
        try! managedObjectContext.save()

        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Delete the non-person item. Expect nothing to change.
        let oldFetchedObjects = Set(controller.fetchedObjects)
        let oldSectionObjects = Set(controller.sections[1].objects)
        
        managedObjectContext.deleteObject(object)
        try! managedObjectContext.save()
        
        XCTAssertEqual(controller.fetchedObjects.count, oldFetchedObjects.count, "Expected no change in object count.")
        XCTAssertEqual(controller.sections[1].objects.count, oldSectionObjects.count, "Expected no change in section object count.")
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }

    // MARK: - Move tests

    func testMoveItemWithinSection() {
        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Change the item's age, thus moving it. Expect a move for the item.
        sampleObjects["Shane"]!.setValue(42, forKey: "age")
        try! managedObjectContext.save()
        
        switch changes.removeFirst() {
        case .Move(object: sampleObjects["Shane"]!, indexPath: NSIndexPath(forRow: 0, inSection: 0), newIndexPath: NSIndexPath(forRow: 1, inSection: 0)):
            break
        default:
            XCTFail("Incorrect change.")
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }

    func testMoveTwoItemsWithinSection() {
        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Change the items' ages, thus moving them. Expect a move for each item.
        sampleObjects["Shane"]!.setValue(52, forKey: "age")
        sampleObjects["Scott"]!.setValue(47, forKey: "age")
        try! managedObjectContext.save()
        
        for _ in 0..<2 {
            switch changes.removeFirst() {
            case .Move(object: sampleObjects["Shane"]!, indexPath: NSIndexPath(forRow: 0, inSection: 0), newIndexPath: NSIndexPath(forRow: 2, inSection: 0)):
                break
            case .Move(object: sampleObjects["Scott"]!, indexPath: NSIndexPath(forRow: 1, inSection: 0), newIndexPath: NSIndexPath(forRow: 1, inSection: 0)):
                break
            default:
                XCTFail("Incorrect change.")
            }
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }

    func testMoveItemWithinSectionWithoutKeys() {
        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes; don't use section keys tough.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: nil, handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Change the item's age, thus moving it. Expect a move for the item, but only within the section.
        sampleObjects["Shane"]!.setValue(42, forKey: "age")
        try! managedObjectContext.save()
        
        switch changes.removeFirst() {
        case .Move(object: sampleObjects["Shane"]!, indexPath: NSIndexPath(forRow: 0, inSection: 0), newIndexPath: NSIndexPath(forRow: 1, inSection: 0)):
            break
        default:
            XCTFail("Incorrect change.")
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }

    func testMoveItemBetweenSections() {
        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Change the item's sex, thus moving it to a different section. Expect a move for the item.
        sampleObjects["Shane"]!.setValue(1, forKey: "sex")
        try! managedObjectContext.save()
        
        switch changes.removeFirst() {
        case .Move(object: sampleObjects["Shane"]!, indexPath: NSIndexPath(forRow: 0, inSection: 0), newIndexPath: NSIndexPath(forRow: 1, inSection: 1)):
            break
        default:
            XCTFail("Incorrect change.")
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }

    func testMoveTwoItemsBetweenSections() {
        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Change the items' sex, thus moving them to a different section. Expect a move for both items.
        sampleObjects["Shane"]!.setValue(1, forKey: "sex")
        sampleObjects["Tague"]!.setValue(1, forKey: "sex")
        try! managedObjectContext.save()
        
        for _ in 0..<2 {
            switch changes.removeFirst() {
            case .Move(object: sampleObjects["Shane"]!, indexPath: NSIndexPath(forRow: 0, inSection: 0), newIndexPath: NSIndexPath(forRow: 1, inSection: 1)):
                break
            case .Move(object: sampleObjects["Tague"]!, indexPath: NSIndexPath(forRow: 2, inSection: 0), newIndexPath: NSIndexPath(forRow: 4, inSection: 1)):
                break
            default:
                XCTFail("Incorrect change.")
            }
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }

    func testMoveItemBetweenSectionsWithoutKeys() {
        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes; but don't use section keys.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: nil, handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Change the item's sex, thus moving it to a different section. Expect a move for the item.
        sampleObjects["Shane"]!.setValue(1, forKey: "sex")
        try! managedObjectContext.save()
        
        switch changes.removeFirst() {
        case .Move(object: sampleObjects["Shane"]!, indexPath: NSIndexPath(forRow: 0, inSection: 0), newIndexPath: NSIndexPath(forRow: 1, inSection: 1)):
            break
        default:
            XCTFail("Incorrect change.")
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }

    func testMoveTwoItemsSwappingSections() {
        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Change the items' sex, thus moving them to a different section (each swapping with the other). Expect a move for both items.
        sampleObjects["Shane"]!.setValue(1, forKey: "sex")
        sampleObjects["Jinger"]!.setValue(0, forKey: "sex")
        try! managedObjectContext.save()
        
        for _ in 0..<2 {
            switch changes.removeFirst() {
            case .Move(object: sampleObjects["Shane"]!, indexPath: NSIndexPath(forRow: 0, inSection: 0), newIndexPath: NSIndexPath(forRow: 1, inSection: 1)):
                break
            case .Move(object: sampleObjects["Jinger"]!, indexPath: NSIndexPath(forRow: 1, inSection: 1), newIndexPath: NSIndexPath(forRow: 0, inSection: 0)):
                break
            default:
                XCTFail("Incorrect change.")
            }
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }

    func testMoveItemOutOfSection() {
        // Insert an item into a new section so that we have something to move.
        let movedObject = makePerson(name: "Rachel", age: 24, sex: 2)
        try! managedObjectContext.save()

        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")), (2, NSPredicate(format: "sex == 2")) ])
        
        // Change the item's sex, thus moving it. Expect a move for the item, and the section it moved out of to be deleted.
        // Currently the delete comes first, not sure if that's correct or not.
        movedObject.setValue(1, forKey: "sex")
        try! managedObjectContext.save()
        
        switch changes.removeFirst() {
        case .DeleteSection(sectionInfo: _, index: 2):
            break
        default:
            XCTFail("Incorrect change.")
        }

        switch changes.removeFirst() {
        case .Move(object: movedObject, indexPath: NSIndexPath(forRow: 0, inSection: 2), newIndexPath: NSIndexPath(forRow: 1, inSection: 1)):
            break
        default:
            XCTFail("Incorrect change.")
        }

        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }
    
    func testMoveTwoItemsOutOfSection() {
        // Insert items into a new section so that we have something to move.
        let movedObject1 = makePerson(name: "Rachel", age: 24, sex: 2)
        let movedObject2 = makePerson(name: "Alex", age: 37, sex: 2)
        try! managedObjectContext.save()
        
        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")), (2, NSPredicate(format: "sex == 2")) ])
        
        // Change the item's sex, thus moving it. Expect a move for the item, and the section it moved out of to be deleted.
        // Currently the delete comes first, not sure if that's correct or not.
        movedObject1.setValue(1, forKey: "sex")
        movedObject2.setValue(1, forKey: "sex")
        try! managedObjectContext.save()
        
        switch changes.removeFirst() {
        case .DeleteSection(sectionInfo: _, index: 2):
            break
        default:
            XCTFail("Incorrect change.")
        }
        
        for _ in 0..<2 {
            switch changes.removeFirst() {
            case .Move(object: movedObject1, indexPath: NSIndexPath(forRow: 0, inSection: 2), newIndexPath: NSIndexPath(forRow: 1, inSection: 1)):
                break
            case .Move(object: movedObject2, indexPath: NSIndexPath(forRow: 1, inSection: 2), newIndexPath: NSIndexPath(forRow: 4, inSection: 1)):
                break
            default:
                XCTFail("Incorrect change.")
            }
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }

    func testMoveItemIntoNewSection() {
        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Change the item's sex, thus moving it. Expect a move for the item, and the section it moved out of to be deleted.
        sampleObjects["Tague"]!.setValue(2, forKey: "sex")
        try! managedObjectContext.save()
        
        switch changes.removeFirst() {
        case .InsertSection(sectionInfo: _, newIndex: 2):
            break
        default:
            XCTFail("Incorrect change.")
        }
        
        switch changes.removeFirst() {
        case .Move(object: sampleObjects["Tague"]!, indexPath: NSIndexPath(forRow: 2, inSection: 0), newIndexPath: NSIndexPath(forRow: 0, inSection: 2)):
            break
        default:
            XCTFail("Incorrect change.")
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")), (2, NSPredicate(format: "sex == 2")) ])
    }
    
    func testMoveTwoItemsIntoNewSection() {
        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Change the item's sex, thus moving it. Expect a move for the item, and the section it moved out of to be deleted.
        sampleObjects["Tague"]!.setValue(2, forKey: "sex")
        sampleObjects["Shane"]!.setValue(2, forKey: "sex")
        try! managedObjectContext.save()
        
        switch changes.removeFirst() {
        case .InsertSection(sectionInfo: _, newIndex: 2):
            break
        default:
            XCTFail("Incorrect change.")
        }
        
        for _ in 0..<2 {
            switch changes.removeFirst() {
            case .Move(object: sampleObjects["Tague"]!, indexPath: NSIndexPath(forRow: 2, inSection: 0), newIndexPath: NSIndexPath(forRow: 1, inSection: 2)):
                break
            case .Move(object: sampleObjects["Shane"]!, indexPath: NSIndexPath(forRow: 0, inSection: 0), newIndexPath: NSIndexPath(forRow: 0, inSection: 2)):
                break
            default:
                XCTFail("Incorrect change.")
            }
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")), (2, NSPredicate(format: "sex == 2")) ])
    }
    
    func testMoveItemOutOfSectionAndIntoNewSection() {
        // Insert an item into a new section so that we have something to move.
        let movedObject = makePerson(name: "Rachel", age: 24, sex: 2)
        try! managedObjectContext.save()
        
        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")), (2, NSPredicate(format: "sex == 2")) ])
        
        // Change the item's sex, thus moving it. Expect a move for the item, and the section it moved out of to be deleted.
        // Currently the delete comes before the move, not sure if that's correct or not.
        movedObject.setValue(-1, forKey: "sex")
        try! managedObjectContext.save()
        
        switch changes.removeFirst() {
        case .DeleteSection(sectionInfo: _, index: 2):
            break
        default:
            XCTFail("Incorrect change.")
        }
        
        switch changes.removeFirst() {
        case .InsertSection(sectionInfo: _, newIndex: 0):
            break
        default:
            XCTFail("Incorrect change.")
        }
        
        switch changes.removeFirst() {
        case .Move(object: movedObject, indexPath: NSIndexPath(forRow: 0, inSection: 2), newIndexPath: NSIndexPath(forRow: 0, inSection: 0)):
            break
        default:
            XCTFail("Incorrect change.")
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (-1, NSPredicate(format: "sex == -1")), (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }
    
    func testMoveTwoItemsOutOfSectionAndIntoNewSection() {
        // Insert items into a new section so that we have something to move.
        let movedObject1 = makePerson(name: "Rachel", age: 24, sex: 2)
        let movedObject2 = makePerson(name: "Alex", age: 37, sex: 2)
        try! managedObjectContext.save()
        
        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")), (2, NSPredicate(format: "sex == 2")) ])
        
        // Change the item's sex, thus moving it. Expect a move for the item, and the section it moved out of to be deleted.
        // Currently the delete comes before the move, not sure if that's correct or not.
        movedObject1.setValue(-1, forKey: "sex")
        movedObject2.setValue(-1, forKey: "sex")
        try! managedObjectContext.save()
        
        switch changes.removeFirst() {
        case .DeleteSection(sectionInfo: _, index: 2):
            break
        default:
            XCTFail("Incorrect change.")
        }
        
        switch changes.removeFirst() {
        case .InsertSection(sectionInfo: _, newIndex: 0):
            break
        default:
            XCTFail("Incorrect change.")
        }
        
        for _ in 0..<2 {
            switch changes.removeFirst() {
            case .Move(object: movedObject1, indexPath: NSIndexPath(forRow: 0, inSection: 2), newIndexPath: NSIndexPath(forRow: 0, inSection: 0)):
                break
            case .Move(object: movedObject2, indexPath: NSIndexPath(forRow: 1, inSection: 2), newIndexPath: NSIndexPath(forRow: 1, inSection: 0)):
                break
            default:
                XCTFail("Incorrect change.")
            }
        }
    
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (-1, NSPredicate(format: "sex == -1")), (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }
    
    func testMoveItemOutOfSectionAndIntoNewSectionAtSamePlace() {
        // Insert an item into a new section so that we have something to move.
        let movedObject = makePerson(name: "Rachel", age: 24, sex: 2)
        try! managedObjectContext.save()
        
        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")), (2, NSPredicate(format: "sex == 2")) ])
        
        // Change the item's sex, thus moving it. Expect a move for the item, and the section it moved out of to be deleted.
        // Currently the delete comes before the move, not sure if that's correct or not.
        movedObject.setValue(3, forKey: "sex")
        try! managedObjectContext.save()
        
        switch changes.removeFirst() {
        case .DeleteSection(sectionInfo: _, index: 2):
            break
        default:
            XCTFail("Incorrect change.")
        }
        
        switch changes.removeFirst() {
        case .InsertSection(sectionInfo: _, newIndex: 2):
            break
        default:
            XCTFail("Incorrect change.")
        }
        
        switch changes.removeFirst() {
        case .Move(object: movedObject, indexPath: NSIndexPath(forRow: 0, inSection: 2), newIndexPath: NSIndexPath(forRow: 0, inSection: 2)):
            break
        default:
            XCTFail("Incorrect change.")
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")), (3, NSPredicate(format: "sex == 3")) ])
    }

    func testMoveTwoItemsOutOfSectionAndIntoNewSectionAtSamePlace() {
        // Insert an item into a new section so that we have something to move.
        let movedObject1 = makePerson(name: "Rachel", age: 24, sex: 2)
        let movedObject2 = makePerson(name: "Alex", age: 37, sex: 2)
        try! managedObjectContext.save()
        
        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")), (2, NSPredicate(format: "sex == 2")) ])
        
        // Change the item's sex, thus moving it. Expect a move for the item, and the section it moved out of to be deleted.
        // Currently the delete comes before the move, not sure if that's correct or not.
        movedObject1.setValue(3, forKey: "sex")
        movedObject2.setValue(3, forKey: "sex")
        try! managedObjectContext.save()
        
        switch changes.removeFirst() {
        case .DeleteSection(sectionInfo: _, index: 2):
            break
        default:
            XCTFail("Incorrect change.")
        }
        
        switch changes.removeFirst() {
        case .InsertSection(sectionInfo: _, newIndex: 2):
            break
        default:
            XCTFail("Incorrect change.")
        }
        
        for _ in 0..<2 {
            switch changes.removeFirst() {
            case .Move(object: movedObject1, indexPath: NSIndexPath(forRow: 0, inSection: 2), newIndexPath: NSIndexPath(forRow: 0, inSection: 2)):
                break
            case .Move(object: movedObject2, indexPath: NSIndexPath(forRow: 1, inSection: 2), newIndexPath: NSIndexPath(forRow: 1, inSection: 2)):
                break
            default:
                XCTFail("Incorrect change.")
            }
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")), (3, NSPredicate(format: "sex == 3")) ])
    }
    
    func testMoveItemWithinAndBetweenSections() {
        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Change the item's age and sex, thus moving it between sections, and within the sort order. Expect a move for the item.
        sampleObjects["Shane"]!.setValue(42, forKey: "age")
        sampleObjects["Shane"]!.setValue(1, forKey: "sex")
        try! managedObjectContext.save()
        
        switch changes.removeFirst() {
        case .Move(object: sampleObjects["Shane"]!, indexPath: NSIndexPath(forRow: 0, inSection: 0), newIndexPath: NSIndexPath(forRow: 3, inSection: 1)):
            break
        default:
            XCTFail("Incorrect change.")
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }

    func testMoveThatDoesntMove() {
        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Change the item's age, but to one that wouldn't move it. We still expect a move for the item, just with identical paths, because that's how NSFetchedResultsController would behave.
        sampleObjects["Shane"]!.setValue(32, forKey: "age")
        try! managedObjectContext.save()
        
        switch changes.removeFirst() {
        case .Move(object: sampleObjects["Shane"]!, indexPath: NSIndexPath(forRow: 0, inSection: 0), newIndexPath: NSIndexPath(forRow: 0, inSection: 0)):
            break
        default:
            XCTFail("Incorrect change.")
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }
   
    func testMoveOtherItemBySortKey() {
        // Create an item of the other type so we have something to move.
        let entity = NSEntityDescription.entityForName("NPC", inManagedObjectContext: managedObjectContext)!
        
        let object = NSManagedObject(entity: entity, insertIntoManagedObjectContext: managedObjectContext)
        object.setValue("Jordan", forKey: "name")
        object.setValue(30, forKey: "age")
        object.setValue(0, forKey: "sex")
        
        try! managedObjectContext.save()

        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Change the other item's age. Expect nothing to change.
        object.setValue(42, forKey: "age")
        try! managedObjectContext.save()
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }

    func testMoveOtherItemBySectionKey() {
        // Create an item of the other type so we have something to move.
        let entity = NSEntityDescription.entityForName("NPC", inManagedObjectContext: managedObjectContext)!
        
        let object = NSManagedObject(entity: entity, insertIntoManagedObjectContext: managedObjectContext)
        object.setValue("Jordan", forKey: "name")
        object.setValue(30, forKey: "age")
        object.setValue(0, forKey: "sex")
        
        try! managedObjectContext.save()
        
        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Change the other item's sex. Expect nothing to change.
        object.setValue(2, forKey: "sex")
        try! managedObjectContext.save()
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }
    
    // MARK: - Other update tests
    
    func testUpdateItem() {
        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Change the item's name, this should result in an update to the item.
        sampleObjects["Shane"]!.setValue("Sean", forKey: "name")
        try! managedObjectContext.save()
        
        switch changes.removeFirst() {
        case .Update(object: sampleObjects["Shane"]!, indexPath: NSIndexPath(forRow: 0, inSection: 0)):
            break
        default:
            XCTFail("Incorrect change.")
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }

    func testUpdateItemWithoutKeys() {
        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes; don't use section keys.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: nil, handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Change the item's name, this should result in an update to the item.
        sampleObjects["Shane"]!.setValue("Sean", forKey: "name")
        try! managedObjectContext.save()
        
        switch changes.removeFirst() {
        case .Update(object: sampleObjects["Shane"]!, indexPath: NSIndexPath(forRow: 0, inSection: 0)):
            break
        default:
            XCTFail("Incorrect change.")
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        // Sanity check the full results.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }
    
    // Change of section and other update together
    // And when there's no section keys
    
    // Change of predicate without notification
    // Change of predicate with notification
    
    // Change of sectioning without notification
    // Change of secitoning with notification

    // MARK: - Notify changes tests
    
    func testChangePredicateWithoutNotification() {
        // Make a fetch request with a predicate, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.predicate = NSPredicate(format: "age > 30")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]

        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect the matching subset of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Change the predicate and call perform fetch again, without notification. Expect the new subset to be returned, but no notification of changes.
        fetchRequest.predicate = NSPredicate(format: "age > 20")
        
        try! controller.performFetch(notifyChanges: false)
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")

        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }
    
    func testNotifyInsertAtStartChange() {
        // Make a fetch request with a predicate, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.predicate = NSPredicate(format: "age > 30")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect the matching subset of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Change the predicate and call perform fetch again, with notification. Expect the new subset to be returned, and notification of insertions for the new values.
        fetchRequest.predicate = NSPredicate(format: "age > 20")
        
        try! controller.performFetch(notifyChanges: true)
        
        for _ in 0..<2 {
            switch changes.removeFirst() {
            case .Insert(object: sampleObjects["Shane"]!, newIndexPath: NSIndexPath(forRow: 0, inSection: 0)):
                break
            case .Insert(object: sampleObjects["Jinger"]!, newIndexPath: NSIndexPath(forRow: 0, inSection: 1)):
                break
            default:
                XCTFail("Incorrect change.")
            }
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }

    func testNotifyInsertAtEndChange() {
        // Make a fetch request with a predicate, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.predicate = NSPredicate(format: "age < 35")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect the matching subset of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Change the predicate and call perform fetch again, with notification. Expect the new subset to be returned, and notification of insertions for the new values.
        fetchRequest.predicate = NSPredicate(format: "age < 50")
        
        try! controller.performFetch(notifyChanges: true)
        
        for _ in 0..<2 {
            switch changes.removeFirst() {
            case .Insert(object: sampleObjects["Scott"]!, newIndexPath: NSIndexPath(forRow: 1, inSection: 0)):
                break
            case .Insert(object: sampleObjects["Tague"]!, newIndexPath: NSIndexPath(forRow: 2, inSection: 0)):
                break
            default:
                XCTFail("Incorrect change.")
            }
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }

    func testNotifyDeleteFromStartChange() {
        // Make a fetch request with a predicate, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.predicate = NSPredicate(format: "age > 20")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect the matching subset of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Change the predicate and call perform fetch again, with notification. Expect the new subset to be returned, and notification of deletions for the lost values.
        fetchRequest.predicate = NSPredicate(format: "age > 30")
        
        try! controller.performFetch(notifyChanges: true)
        
        for _ in 0..<2 {
            switch changes.removeFirst() {
            case .Delete(object: sampleObjects["Shane"]!, indexPath: NSIndexPath(forRow: 0, inSection: 0)):
                break
            case .Delete(object: sampleObjects["Jinger"]!, indexPath: NSIndexPath(forRow: 0, inSection: 1)):
                break
            default:
                XCTFail("Incorrect change.")
            }
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }

    func testNotifyDeleteFromEndChange() {
        // Make a fetch request with a predicate, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.predicate = NSPredicate(format: "age < 50")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect the matching subset of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Change the predicate and call perform fetch again, with notification. Expect the new subset to be returned, and notification of deletions for the lost values.
        fetchRequest.predicate = NSPredicate(format: "age < 35")
        
        try! controller.performFetch(notifyChanges: true)
        
        for _ in 0..<2 {
            switch changes.removeFirst() {
            case .Delete(object: sampleObjects["Scott"]!, indexPath: NSIndexPath(forRow: 1, inSection: 0)):
                break
            case .Delete(object: sampleObjects["Tague"]!, indexPath: NSIndexPath(forRow: 2, inSection: 0)):
                break
            default:
                XCTFail("Incorrect change.")
            }
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }

    func testNotifyInsertSectionChange() {
        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, place all of the results in a single section, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { _ in 0 }, sectionKeys: nil, handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, in a single section.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, nil) ])
        
        // Change the sectioning key to instead place everything in the same section, and then call perform fetch again, with notification. Expect all objects in the one section, and notification of moves and deletion of the extra section.
        controller.sectionForObject = { $0.valueForKey("sex")!.integerValue }
        controller.sectionKeys = ["sex"]
        
        try! controller.performFetch(notifyChanges: true)
        
        switch changes.removeFirst() {
        case .InsertSection(sectionInfo: _, newIndex: 1):
            break
        default:
            XCTFail("Incorrect change.")
        }
        
        for _ in 0..<3 {
            switch changes.removeFirst() {
            case .Move(object: sampleObjects["Caitlin"]!, indexPath: NSIndexPath(forRow: 0, inSection: 0), newIndexPath: NSIndexPath(forRow: 0, inSection: 1)):
                break
            case .Move(object: sampleObjects["Jinger"]!, indexPath: NSIndexPath(forRow: 2, inSection: 0), newIndexPath: NSIndexPath(forRow: 1, inSection: 1)):
                break
            case .Move(object: sampleObjects["Sam"]!, indexPath: NSIndexPath(forRow: 3, inSection: 0), newIndexPath: NSIndexPath(forRow: 2, inSection: 1)):
                break
            default:
                XCTFail("Incorrect change.")
            }
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }
    
    func testNotifyDeleteSectionChange() {
        // Make a fetch request, provide sort descriptors to make the test results consistent.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect the matching subset of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Change the sectioning key to instead place everything in the same section, and then call perform fetch again, with notification. Expect all objects in the one section, and notification of moves and deletion of the extra section.
        controller.sectionForObject = { _ in 0 }
        controller.sectionKeys = nil
        
        try! controller.performFetch(notifyChanges: true)
        
        switch changes.removeFirst() {
        case .DeleteSection(sectionInfo: _, index: 1):
            break
        default:
            XCTFail("Incorrect change.")
        }
        
        for _ in 0..<3 {
            switch changes.removeFirst() {
            case .Move(object: sampleObjects["Caitlin"]!, indexPath: NSIndexPath(forRow: 0, inSection: 1), newIndexPath: NSIndexPath(forRow: 0, inSection: 0)):
                break
            case .Move(object: sampleObjects["Jinger"]!, indexPath: NSIndexPath(forRow: 1, inSection: 1), newIndexPath: NSIndexPath(forRow: 2, inSection: 0)):
                break
            case .Move(object: sampleObjects["Sam"]!, indexPath: NSIndexPath(forRow: 2, inSection: 1), newIndexPath: NSIndexPath(forRow: 3, inSection: 0)):
                break
            default:
                XCTFail("Incorrect change.")
            }
        }

        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, nil) ])
    }
    
    func testNotifyMoveChange() {
        // Make a fetch request, provide sort descriptors to use to force movement.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex, and collect changes.
        var changes: [FetchedResultsChange<Int, NSManagedObject>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: { changes.appendContentsOf($0) })
        try! controller.performFetch()
        
        // Expect all of the objects to be returned in the right order, divided into two sections each with a subset of the objects.
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
        
        // Change the sort order, and then call perform fetch again, with notification. Expect the objects to remain in their same sections, but move about. Since we invert the sort, and there are three objects, the middle one should stay put.
        controller.fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: false) ]
        
        try! controller.performFetch(notifyChanges: true)
        
        for _ in 0..<4 {
            switch changes.removeFirst() {
            case .Move(object: sampleObjects["Caitlin"]!, indexPath: NSIndexPath(forRow: 0, inSection: 1), newIndexPath: NSIndexPath(forRow: 2, inSection: 1)):
                break
            case .Move(object: sampleObjects["Sam"]!, indexPath: NSIndexPath(forRow: 2, inSection: 1), newIndexPath: NSIndexPath(forRow: 0, inSection: 1)):
                break
            case .Move(object: sampleObjects["Shane"]!, indexPath: NSIndexPath(forRow: 0, inSection: 0), newIndexPath: NSIndexPath(forRow: 2, inSection: 0)):
                break
            case .Move(object: sampleObjects["Tague"]!, indexPath: NSIndexPath(forRow: 2, inSection: 0), newIndexPath: NSIndexPath(forRow: 0, inSection: 0)):
                break
            default:
                XCTFail("Incorrect change.")
            }
        }
        
        XCTAssertEqual(changes.count, 0, "Incorrect number of changes.")
        
        checkResults(controller, predicate: fetchRequest.predicate, sortDescriptors: fetchRequest.sortDescriptors, sections: [ (0, NSPredicate(format: "sex == 0")), (1, NSPredicate(format: "sex == 1")) ])
    }
    
    // MARK: - Miscellaneous tests
    
    func testIndexPathOfObject() {
        // Make a fetch request with a predicate and sort descriptors.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.predicate = NSPredicate(format: "age > 30")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex.
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: nil)
        try! controller.performFetch()
        
        // Expect the index path of the object to be correct.
        XCTAssertEqual(controller.indexPath(of: sampleObjects["Tague"]!), NSIndexPath(forRow: 1, inSection: 0), "Index path of object was incorrect.")
    }
    
    func testIndexPathOfMissingObject() {
        // Make a fetch request with a predicate and sort descriptors.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.predicate = NSPredicate(format: "age > 30")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex.
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: nil)
        try! controller.performFetch()
        
        // Expect the index path of an object not in the results to be nil.
        XCTAssertNil(controller.indexPath(of: sampleObjects["Shane"]!), "Unexpected index path for object.")
    }
    
    func testObjectAtIndexPath() {
        // Make a fetch request with a predicate and sort descriptors.
        let fetchRequest = NSFetchRequest(entityName: "Person")
        fetchRequest.predicate = NSPredicate(format: "age > 30")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "age", ascending: true) ]
        
        // Create the controller, section the results by sex.
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionForObject: { $0.valueForKey("sex")!.integerValue }, sectionKeys: ["sex"], handleChanges: nil)
        try! controller.performFetch()
        
        // Expect the object at an index path to be correct.
        XCTAssert(controller.object(at: NSIndexPath(forRow: 1, inSection: 0)) === sampleObjects["Tague"]!, "Object at index path was incorrect.")
    }

    // MARK: - Performance tests
    
    func testPerformance() {
        let fetchRequest = NSFetchRequest(entityName: "Monster")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "name", ascending: true) ]
        
        var changes: [FetchedResultsChange<Character, DungeonMaster.Monster>] = []
        let controller = FetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DungeonMaster.managedObjectContext, sectionForObject: { (monster: DungeonMaster.Monster) -> Character in monster.name.characters[monster.name.startIndex] }, sectionKeys: ["name"], handleChanges: { changes.appendContentsOf($0) })

        measureBlock {
            try! controller.performFetch()
        }
    }

    func testCoreDataPerformance() {
        let fetchRequest = NSFetchRequest(entityName: "Monster")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "name", ascending: true) ]
        
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DungeonMaster.managedObjectContext, sectionNameKeyPath: "nameInitial", cacheName: nil)
        
        measureBlock {
            try! controller.performFetch()
        }
    }
    

}
