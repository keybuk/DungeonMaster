//
//  MonsterSkill.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/22/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import Foundation

/// MonsterSkill represents a skill that a monster is proficient in.
///
/// Monster proficiencies don't always match the proficiency bonus for their level, or even the double for expertise rule, so this includes the specific modifier for that proficiency.
final class MonsterSkill: NSManagedObject {
    
    /// Monster that this proficiency applies to.
    @NSManaged var monster: Monster
    
    /// Skill that the monster is proficient in.
    var skill: Skill {
        get {
            return Skill(rawAbilityValue: rawAbility.integerValue, rawSkillValue: rawSkill.integerValue)!
        }
        set(newSkill) {
            rawAbility = NSNumber(integer: newSkill.rawAbilityValue)
            rawSkill = NSNumber(integer: newSkill.rawSkillValue)
        }
    }
    @NSManaged private var rawAbility: NSNumber
    @NSManaged private var rawSkill: NSNumber
    
    /// Modifier for this skill.
    var modifier: Int {
        get {
            return rawModifier.integerValue
        }
        set(newModifier) {
            rawModifier = NSNumber(integer: newModifier)
        }
    }
    @NSManaged private var rawModifier: NSNumber
    
    convenience init(monster: Monster, skill: Skill, inManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(Model.MonsterSkill, inManagedObjectContext: context)
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.monster = monster
        self.skill = skill
    }
    
}
