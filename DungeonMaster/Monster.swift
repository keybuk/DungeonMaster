//
//  Monster.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 11/30/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import Foundation
import CoreData

final class Monster: NSManagedObject {
    
    @NSManaged var name: String
    @NSManaged var sources: NSSet
    
    // Hit Points and dice expression to generate.
    @NSManaged var hp: Int16
    @NSManaged var hpDice: String

    // Parsed ability scores, saving throws, skills, and passive Perception.
    @NSManaged var str: Int16
    @NSManaged var dex: Int16
    @NSManaged var con: Int16
    @NSManaged var int: Int16
    @NSManaged var wis: Int16
    @NSManaged var cha: Int16
    @NSManaged var passivePerception: Int16
    
    // Original stat block text.
    @NSManaged var sizeTypeAlignment: String
    @NSManaged var armorClass: String
    @NSManaged var hitPoints: String
    @NSManaged var speed: String
    @NSManaged var strength: String
    @NSManaged var dexterity: String
    @NSManaged var constitution: String
    @NSManaged var intelligence: String
    @NSManaged var wisdom: String
    @NSManaged var charisma: String
    @NSManaged var savingThrows: String?
    @NSManaged var skills: String?
    @NSManaged var damageVulnerabilities: String?
    @NSManaged var damageResistances: String?
    @NSManaged var damageImmunities: String?
    @NSManaged var conditionImmunities: String?
    @NSManaged var senses: String
    @NSManaged var languages: String?
    @NSManaged var challenge: String
    
    @NSManaged var traits: NSOrderedSet
    @NSManaged var actions: NSOrderedSet
    @NSManaged var reactions: NSOrderedSet
    @NSManaged var legendaryActions: NSOrderedSet
    @NSManaged var lair: Lair?
    
    var nameInitial: String {
        return String(name.characters.first!)
    }

    convenience init(name: String, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.Monster, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.name = name
    }

}
