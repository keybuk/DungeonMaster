//
//  DetailViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 11/20/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class DetailViewController: UIViewController {

    @IBOutlet var textView: UITextView!
    @IBOutlet var addButton: UIBarButtonItem!
    @IBOutlet var doneButton: UIBarButtonItem!

    var detailItem: AnyObject? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        if let monster = self.detailItem as? Monster,
            textView = self.textView {
                let text = NSTextStorage()

                let nameFont = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleTitle1)

                let subheadlineFont = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleSubheadline)
                let subheadlineItalicFont = subheadlineFont.fontDescriptorWithSymbolicTraits(.TraitItalic)

                let bodyFont = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleBody)
                let bodyBoldFont = bodyFont.fontDescriptorWithSymbolicTraits(.TraitBold)
                let bodyBoldItalicFont = bodyFont.fontDescriptorWithSymbolicTraits([ .TraitBold, .TraitItalic ])

                let titleFont = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleTitle2)

                
                let nameStyle = [
                    NSFontAttributeName: UIFont(descriptor: nameFont, size: 0.0),
                ]
                
    
                let sizeTypeAlignmentParaStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
                sizeTypeAlignmentParaStyle.paragraphSpacing = 12.0

                let sizeTypeAlignmentStyle = [
                    NSFontAttributeName: UIFont(descriptor: subheadlineItalicFont, size: 0.0),
                    NSParagraphStyleAttributeName: sizeTypeAlignmentParaStyle
                ]
                
    
                let statsParaStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
                statsParaStyle.headIndent = 12.0
                
                let statsLabelStyle = [
                    NSFontAttributeName: UIFont(descriptor: bodyBoldFont, size: 0.0),
                    NSParagraphStyleAttributeName: statsParaStyle,
                ]

                let statsValueStyle = [
                    NSFontAttributeName: UIFont(descriptor: bodyFont, size: 0.0),
                    NSParagraphStyleAttributeName: statsParaStyle,
                ]
                
                
                let abilityScoresParaStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle

                abilityScoresParaStyle.tabStops = [
                    NSTextTab(textAlignment: .Center, location:  40.0, options: [String:AnyObject]()),
                    NSTextTab(textAlignment: .Center, location: 120.0, options: [String:AnyObject]()),
                    NSTextTab(textAlignment: .Center, location: 200.0, options: [String:AnyObject]()),
                    NSTextTab(textAlignment: .Center, location: 280.0, options: [String:AnyObject]()),
                    NSTextTab(textAlignment: .Center, location: 360.0, options: [String:AnyObject]()),
                    NSTextTab(textAlignment: .Center, location: 440.0, options: [String:AnyObject]()),
                    ]
                
                let abilityScoresLabelParaStyle = abilityScoresParaStyle.mutableCopy() as! NSMutableParagraphStyle
                abilityScoresLabelParaStyle.paragraphSpacingBefore = 12.0
                
                let abilityScoresValueParaStyle = abilityScoresParaStyle.mutableCopy() as! NSMutableParagraphStyle
                abilityScoresValueParaStyle.paragraphSpacing = 12.0
                
                let abilityScoresLabelStyle = [
                    NSFontAttributeName: UIFont(descriptor: bodyBoldFont, size: 0.0),
                    NSParagraphStyleAttributeName: abilityScoresLabelParaStyle,
                ]
                
                let abilityScoresValueStyle = [
                    NSFontAttributeName: UIFont(descriptor: bodyFont, size: 0.0),
                    NSParagraphStyleAttributeName: abilityScoresValueParaStyle,
                ]


                let featureParaStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
                featureParaStyle.paragraphSpacingBefore = 12.0
                
                let featureContinuedParaStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
                featureContinuedParaStyle.firstLineHeadIndent = 12.0
    
                let featureNameStyle = [
                    NSFontAttributeName: UIFont(descriptor: bodyBoldItalicFont, size: 0.0),
                    NSParagraphStyleAttributeName: featureParaStyle,
                ]
                
                let featureTextStyle = [
                    NSFontAttributeName: UIFont(descriptor: bodyFont, size: 0.0),
                    NSParagraphStyleAttributeName: featureParaStyle,
                ]

                let featureContinuedStyle = [
                    NSFontAttributeName: UIFont(descriptor: bodyFont, size: 0.0),
                    NSParagraphStyleAttributeName: featureContinuedParaStyle,
                ]


                let titleParaStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
                titleParaStyle.paragraphSpacingBefore = 24.0
                
                let titleStyle = [
                    NSFontAttributeName: UIFont(descriptor: titleFont, size: 0.0),
                    NSParagraphStyleAttributeName: titleParaStyle,
                ]

                
                text.appendAttributedString(NSAttributedString(string: "\(monster.name)\n", attributes: nameStyle))
                
                
                let sizeType: String
                if let swarmSize = monster.swarmSize {
                    sizeType = "\(swarmSize.stringValue) swarm of \(monster.size.stringValue) \(monster.type.stringValue)s"
                } else {
                    sizeType = "\(monster.size.stringValue) \(monster.type.stringValue.lowercaseString)"
                }
                text.appendAttributedString(NSAttributedString(string: "\(sizeType)", attributes: sizeTypeAlignmentStyle))

                if monster.tags.count > 0 || monster.requiresRace {
                    let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
                    var tags = monster.tags.sortedArrayUsingDescriptors([ sortDescriptor ]).map { ($0 as! Tag).name }
                    if monster.requiresRace {
                        tags.insert("any race", atIndex: 0)
                    }
                    let tagString = tags.joinWithSeparator(", ")
                    text.appendAttributedString(NSAttributedString(string: " (\(tagString))", attributes: sizeTypeAlignmentStyle))
                }
                
                if let alignment = monster.alignment {
                    text.appendAttributedString(NSAttributedString(string: ", \(alignment.stringValue.lowercaseString)\n", attributes: sizeTypeAlignmentStyle))
                } else if monster.alignmentOptions.filter({ ($0 as! AlignmentOption).weight != nil }).count > 0 {
                    // By weight
                    let weightSortDescriptor = NSSortDescriptor(key: "rawWeight", ascending: false)
                    let alignmentSortDescriptor = NSSortDescriptor(key: "rawAlignment", ascending: true)
                    
                    let alignmentString = monster.alignmentOptions.sortedArrayUsingDescriptors([ weightSortDescriptor, alignmentSortDescriptor ]).map {
                        let alignmentOption = $0 as! AlignmentOption
                        let formattedWeight = NSString(format: "%.0f", alignmentOption.weight! * 100.0)
                        return "\(alignmentOption.alignment.stringValue.lowercaseString) (\(formattedWeight)%)"
                    }.joinWithSeparator(" or ")
                    
                    text.appendAttributedString(NSAttributedString(string: ", \(alignmentString)\n", attributes: sizeTypeAlignmentStyle))

                } else {
                    // By set;
                    let alignmentSet = Set<Alignment>(monster.alignmentOptions.map({ ($0 as! AlignmentOption).alignment }))
                    
                    let alignmentString: String
                    if alignmentSet == Alignment.allAlignments {
                        alignmentString = "any alignment"
                    } else if alignmentSet == Alignment.chaoticAlignments {
                        alignmentString = "any chaotic alignment"
                    } else if alignmentSet == Alignment.evilAlignments {
                        alignmentString = "any evil alignment"
                    } else if alignmentSet == Alignment.allAlignments.subtract(Alignment.goodAlignments) {
                        alignmentString = "any non-good alignment"
                    } else if alignmentSet == Alignment.allAlignments.subtract(Alignment.lawfulAlignments) {
                        alignmentString = "any non-lawful alignment"
                    } else {
                        alignmentString = "various alignments"
                    }
                    
                    text.appendAttributedString(NSAttributedString(string: ", \(alignmentString)\n", attributes: sizeTypeAlignmentStyle))
                }
                
                var armorString = ""

                let basicArmorPredicate = NSPredicate(format: "rawCondition == nil AND spellName == nil")
                for case let armor as Armor in monster.armor.filteredSetUsingPredicate(basicArmorPredicate) {
                    switch armor.type {
                    case .None:
                        armorString += "\(armor.armorClass)"
                    default:
                        var typeString = armor.type.stringValue.lowercaseString
                        if let magicModifier = armor.magicModifier {
                            typeString = String(format: "%+d", magicModifier) + " \(typeString)"
                        }
                        if armor.includesShield {
                            typeString += ", shield"
                        }
                        
                        armorString += "\(armor.armorClass) (\(typeString))"
                    }
                }
                
                let spellArmorPredicate = NSPredicate(format: "spellName != nil")
                for case let armor as Armor in monster.armor.filteredSetUsingPredicate(spellArmorPredicate) {
                    armorString += " (\(armor.armorClass) with \(armor.spellName!))"
                }
                
                let conditionArmorPredicate = NSPredicate(format: "rawCondition != nil")
                for case let armor as Armor in monster.armor.filteredSetUsingPredicate(conditionArmorPredicate) {
                    armorString += ", \(armor.armorClass) while \(armor.condition!.stringValue.lowercaseString)"
                }
                
                text.appendAttributedString(NSAttributedString(string: "Armor Class ", attributes: statsLabelStyle))
                text.appendAttributedString(NSAttributedString(string: "\(armorString)\n", attributes: statsValueStyle))
                
                let hitPoints = monster.hitPoints ?? monster.hitDice.averageValue
                text.appendAttributedString(NSAttributedString(string: "Hit Points ", attributes: statsLabelStyle))
                text.appendAttributedString(NSAttributedString(string: "\(hitPoints) (\(monster.hitDice.description))\n", attributes: statsValueStyle))

                text.appendAttributedString(NSAttributedString(string: "Speed ", attributes: statsLabelStyle))
                text.appendAttributedString(NSAttributedString(string: "\(monster.speed) ft.", attributes: statsValueStyle))
                
                if let speed = monster.burrowSpeed {
                    text.appendAttributedString(NSAttributedString(string: ", burrow \(speed) ft.", attributes: statsValueStyle))
                }
                
                if let speed = monster.climbSpeed {
                    text.appendAttributedString(NSAttributedString(string: ", climb \(speed) ft.", attributes: statsValueStyle))
                }

                if let speed = monster.flySpeed {
                    text.appendAttributedString(NSAttributedString(string: ", fly \(speed) ft.", attributes: statsValueStyle))
                    if monster.canHover {
                        text.appendAttributedString(NSAttributedString(string: " (hover)", attributes: statsValueStyle))
                    }
                }

                if let speed = monster.swimSpeed {
                    text.appendAttributedString(NSAttributedString(string: ", swim \(speed) ft.", attributes: statsValueStyle))
                }
                text.appendAttributedString(NSAttributedString(string: "\n", attributes: statsValueStyle))

                let str = String(format: "%d (%+d)", monster.strengthScore, monster.modifierFor(ability: .Strength))
                let dex = String(format: "%d (%+d)", monster.dexterityScore, monster.modifierFor(ability: .Dexterity))
                let con = String(format: "%d (%+d)", monster.constitutionScore, monster.modifierFor(ability: .Constitution))
                let int = String(format: "%d (%+d)", monster.intelligenceScore, monster.modifierFor(ability: .Intelligence))
                let wis = String(format: "%d (%+d)", monster.wisdomScore, monster.modifierFor(ability: .Wisdom))
                let cha = String(format: "%d (%+d)", monster.charismaScore, monster.modifierFor(ability: .Charisma))
                
                text.appendAttributedString(NSAttributedString(string: "\tSTR\tDEX\tCON\tINT\tWIS\tCHA\n", attributes: abilityScoresLabelStyle))
                text.appendAttributedString(NSAttributedString(string: "\t\(str)\t\(dex)\t\(con)\t\(int)\t\(wis)\t\(cha)\n", attributes: abilityScoresValueStyle))
                
                if monster.savingThrows.count > 0 {
                    let sortDescriptor = NSSortDescriptor(key: "rawSavingThrow", ascending: true)
                    let savingThrowsString = monster.savingThrows.sortedArrayUsingDescriptors([ sortDescriptor ]).map({
                        String(format: "%@ %+d", ($0 as! MonsterSavingThrow).savingThrow.shortStringValue, ($0 as! MonsterSavingThrow).modifier)
                    }).joinWithSeparator(", ")
                    
                    text.appendAttributedString(NSAttributedString(string: "Saving Throws ", attributes: statsLabelStyle))
                    text.appendAttributedString(NSAttributedString(string: "\(savingThrowsString)\n", attributes: statsValueStyle))
                }
                
                if monster.skills.count > 0 {
                    let skillsString = monster.skills.map({
                        String(format: "%@ %+d", ($0 as! MonsterSkill).skill.stringValue, ($0 as! MonsterSkill).modifier)
                    }).sort().joinWithSeparator(", ")

                    text.appendAttributedString(NSAttributedString(string: "Skills ", attributes: statsLabelStyle))
                    text.appendAttributedString(NSAttributedString(string: "\(skillsString)\n", attributes: statsValueStyle))
                }
                
                func damageList(damages: NSSet, spellDamage: Bool = false) -> String {
                    var damageList = ""

                    let allAttacksPredicate = NSPredicate(format: "rawAttackType = %@", NSNumber(integer: AttackType.All.rawValue))
                    let allAttackDamages = damages.filteredSetUsingPredicate(allAttacksPredicate)
                    
                    if spellDamage {
                        damageList += "damage from spells"
                        if damages.count > 0 {
                            damageList += "; "
                        }
                    }
                    
                    if allAttackDamages.count > 0 {
                        damageList += allAttackDamages.map({
                            DamageType(rawValue: (($0 as! NSManagedObject).valueForKey("rawDamageType") as! NSNumber).integerValue)!.stringValue.lowercaseString
                        }).sort(<).joinWithSeparator(", ")
                        
                        if allAttackDamages.count < damages.count || spellDamage {
                            damageList += "; "
                        }
                    }
                    
                    let otherAttacksPredicate = NSPredicate(format: "rawAttackType != %@", NSNumber(integer: AttackType.All.rawValue))
                    let otherAttackDamages = damages.filteredSetUsingPredicate(otherAttacksPredicate)
                    
                    if otherAttackDamages.count > 0 {
                        let anyDamage = (otherAttackDamages.first! as! NSManagedObject)
                        let attackType = AttackType(rawValue: (anyDamage.valueForKey("rawAttackType") as! NSNumber).integerValue)!

                        if spellDamage && attackType == .Nonmagical && anyDamage.valueForKey("spellName") != nil {
                            damageList += "nonmagical "
                        }
                        
                        var damageStrings = otherAttackDamages.map({
                            DamageType(rawValue: (($0 as! NSManagedObject).valueForKey("rawDamageType") as! NSNumber).integerValue)!.stringValue.lowercaseString
                        }).sort(<)
                        let lastDamageString = damageStrings.removeLast()
                        
                        if damageStrings.count > 1 {
                            damageList += damageStrings.joinWithSeparator(", ") + ", and \(lastDamageString)"
                        } else if damageStrings.count == 1 {
                            damageList += "\(damageStrings[0]) and \(lastDamageString)"
                        } else {
                            damageList += lastDamageString
                        }
                        
                        switch attackType {
                        case .All:
                            break
                        case .Nonmagical:
                            if spellDamage && attackType == .Nonmagical && anyDamage.valueForKey("spellName") != nil {
                                let spellName = anyDamage.valueForKey("spellName")! as! String
                                damageList += " (from \(spellName))"
                            } else {
                                damageList += " from nonmagical attacks"
                            }
                        case .NonmagicalNotAdamantine:
                            damageList += " from nonmagical attacks not made with adamantine weapons"
                        case .NonmagicalNotSilvered:
                            damageList += " from nonmagical attacks not made with silvered weapons"
                        case .Magical:
                            damageList += " from magic weapons"
                        case .MagicalByGood:
                            damageList += " from magic weapons wielded by good creatures"
                        }
                    }

                    return damageList
                }
                
                if monster.damageVulnerabilities.count > 0 {
                    text.appendAttributedString(NSAttributedString(string: "Damage Vulnerabilities ", attributes: statsLabelStyle))
                    text.appendAttributedString(NSAttributedString(string: "\(damageList(monster.damageVulnerabilities))\n", attributes: statsValueStyle))
                }

                if monster.damageResistances.count > 0 {
                    text.appendAttributedString(NSAttributedString(string: "Damage Resistances ", attributes: statsLabelStyle))
                    text.appendAttributedString(NSAttributedString(string: "\(damageList(monster.damageResistances, spellDamage: monster.isResistantToSpellDamage))\n", attributes: statsValueStyle))
                } else if monster.damageResistanceOptions.count > 0 {
                    text.appendAttributedString(NSAttributedString(string: "Damage Resistances ", attributes: statsLabelStyle))

                    var damageStrings = monster.damageResistanceOptions.map({ ($0 as! DamageResistanceOption).damageType.stringValue.lowercaseString }).sort(<)
                    let lastDamageString = damageStrings.removeLast()
                    
                    text.appendAttributedString(NSAttributedString(string: "one of the following: \(damageStrings.joinWithSeparator(", ")), or \(lastDamageString)\n", attributes: statsValueStyle))
                }
                
                if monster.damageImmunities.count > 0 {
                    text.appendAttributedString(NSAttributedString(string: "Damage Immunities ", attributes: statsLabelStyle))
                    text.appendAttributedString(NSAttributedString(string: "\(damageList(monster.damageImmunities))\n", attributes: statsValueStyle))
                }

                if monster.conditionImmunities.count > 0 {
                    text.appendAttributedString(NSAttributedString(string: "Condition Immunities ", attributes: statsLabelStyle))
                    
                    let conditionStrings = monster.conditionImmunities.map({ ($0 as! ConditionImmunity).condition.stringValue.lowercaseString }).sort(<).joinWithSeparator(", ")
                    text.appendAttributedString(NSAttributedString(string: "\(conditionStrings)\n", attributes: statsValueStyle))
                }

                text.appendAttributedString(NSAttributedString(string: "Senses ", attributes: statsLabelStyle))
                if let blindsight = monster.blindsight {
                    text.appendAttributedString(NSAttributedString(string: "blindsight \(blindsight) ft.", attributes: statsValueStyle))
                    if monster.isBlind {
                        text.appendAttributedString(NSAttributedString(string: " (blind beyond this radius)", attributes: statsValueStyle))
                    }
                    text.appendAttributedString(NSAttributedString(string: ", ", attributes: statsValueStyle))

                }
                if let darkvision = monster.darkvision {
                    text.appendAttributedString(NSAttributedString(string: "darkvision \(darkvision) ft., ", attributes: statsValueStyle))
                }
                if let tremorsense = monster.tremorsense {
                    text.appendAttributedString(NSAttributedString(string: "tremorsense \(tremorsense) ft., ", attributes: statsValueStyle))
                }
                if let truesight = monster.truesight {
                    text.appendAttributedString(NSAttributedString(string: "truesight \(truesight) ft., ", attributes: statsValueStyle))
                }
                text.appendAttributedString(NSAttributedString(string: "passive Perception \(monster.passivePerception)\n", attributes: statsValueStyle))

                var languageStrings = [String]()
                text.appendAttributedString(NSAttributedString(string: "Languages ", attributes: statsLabelStyle))
                
                if monster.canSpeakAllLanguages {
                    languageStrings.append("all")
                } else if monster.languagesSpoken.count > 0 {
                    languageStrings.appendContentsOf(monster.languagesSpoken.map({ ($0 as! Language).name }).sort(<))
                    
                    // Special case for "plus..."
                    if let languagesSpokenOption = monster.languagesSpokenOption {
                        var thisString = languageStrings.removeLast()
                        
                        switch languagesSpokenOption {
                        case .AnyOne:
                            thisString += " plus one other language"
                        case .AnyTwo:
                            thisString += " plus any two languages"
                        case .AnyFour:
                            thisString += " plus any four languages"
                        case .UpToFive:
                            thisString += " plus up to five other languages"
                        case .AnySix:
                            thisString += " plus any six languages"
                        default:
                            break
                        }
                        
                        languageStrings.append(thisString)
                    }
                } else if let languagesSpokenOption = monster.languagesSpokenOption {
                    switch languagesSpokenOption {
                    case .UsuallyCommon:
                        languageStrings.append("any one language (usually Common)")
                    case .KnewInLife:
                        languageStrings.append("the languages it knew in life")
                    case .OfItsCreator:
                        languageStrings.append("the languages of its creator")
                    case .OneOfItsCreator:
                        languageStrings.append("one language known by its creator")
                    case .AnyOne:
                        languageStrings.append("any one language")
                    case .AnyTwo:
                        languageStrings.append("any two languages")
                    case .AnyFour:
                        languageStrings.append("any four languages")
                    case .UpToFive:
                        languageStrings.append("up to five languages")
                    case .AnySix:
                        languageStrings.append("any six languages")
                    }
                }
        
                if monster.canUnderstandAllLanguages {
                    if monster.type == .Construct {
                        languageStrings.append("understands commands given in any language but can't speak")
                    } else {
                        languageStrings.append("understands all languages but can't speak")
                    }
                } else if monster.languagesUnderstood.count == 1 {
                    let language = monster.languagesUnderstood.anyObject() as! Language
                    if languageStrings.count > 0 {
                        languageStrings.append("understands \(language.name) but can't speak it")
                    } else {
                        languageStrings.append("understands \(language.name) but can't speak")
                    }
                } else if monster.languagesUnderstood.count > 0 {
                    var languageNames = monster.languagesUnderstood.map({ ($0 as! Language).name }).sort(<)
                    
                    var thisString = "understands "
                    if languageNames.count == 2 {
                        thisString += "\(languageNames[0]) and \(languageNames[1])"
                    } else {
                        let lastName = languageNames.removeLast()
                        thisString += "\(languageNames.joinWithSeparator(", ")), and \(lastName)"
                    }
                    thisString += " but can't speak"
                    if languageStrings.count > 0 {
                        thisString += " them"
                    }
                    
                    languageStrings.append(thisString)
                } else if let languagesUnderstoodOption = monster.languagesUnderstoodOption {
                    var thisString = "understands "
                    
                    switch languagesUnderstoodOption {
                    case .UsuallyCommon:
                        thisString += "any one language (usually Common)"
                    case .KnewInLife:
                        thisString += "the languages it knew in life"
                    case .OfItsCreator:
                        thisString += "the languages of its creator"
                    case .OneOfItsCreator:
                        thisString += "one language known by its creator"
                    case .AnyOne:
                        thisString += "any one language"
                    case .AnyTwo:
                        thisString += "any two languages"
                    case .AnyFour:
                        thisString += "any four languages"
                    case .UpToFive:
                        thisString += "up to five languages"
                    case .AnySix:
                        thisString += "any six languages"
                    }
            
                    thisString += " but can't speak"
                    if languageStrings.count > 0 {
                        thisString += " them"
                    }
                    
                    languageStrings.append(thisString)
                }
                
                if let telepathy = monster.telepathy {
                    var languageString = "telepathy \(telepathy) ft."
                    
                    if monster.telepathyIsLimited {
                        let languages = monster.languagesSpoken.map({ ($0 as! Language).name }).sort(<).joinWithSeparator(", ")

                        languageString += " (works only with creatures that understand \(languages)))"
                    }
                    
                    languageStrings.append(languageString)
                }
                
                if languageStrings.count > 0 {
                    text.appendAttributedString(NSAttributedString(string: "\(languageStrings.joinWithSeparator(", "))\n", attributes: statsValueStyle))
                } else {
                    text.appendAttributedString(NSAttributedString(string: "—\n", attributes: statsValueStyle))
                }
                
                let challengeString: String
                if monster.challenge == NSDecimalNumber(string: "0.125") {
                    challengeString = "1/8"
                } else if monster.challenge == NSDecimalNumber(string: "0.25") {
                    challengeString = "1/4"
                } else if monster.challenge == NSDecimalNumber(string: "0.5") {
                    challengeString = "1/2"
                } else {
                    challengeString = "\(monster.challenge)"
                }
                
                let xpFormatter = NSNumberFormatter()
                xpFormatter.numberStyle = .DecimalStyle
                
                let xpString = xpFormatter.stringFromNumber(monster.XP)!
                
                text.appendAttributedString(NSAttributedString(string: "Challenge ", attributes: statsLabelStyle))
                text.appendAttributedString(NSAttributedString(string: "\(challengeString) (\(xpString) XP)\n", attributes: statsValueStyle))
                
                for case let trait as Trait in monster.traits {
                    text.appendAttributedString(NSAttributedString(string: "\(trait.name). ", attributes: featureNameStyle))
                    
                    var attributes = featureTextStyle
                    trait.text.enumerateLines { line, stop in
                        text.appendAttributedString(NSAttributedString(string: "\(line)\n", attributes: attributes))
                        attributes = featureContinuedStyle
                    }
                }

                if monster.actions.count > 0 {
                    text.appendAttributedString(NSAttributedString(string: "Actions\n", attributes: titleStyle))
                
                    for case let action as Action in monster.actions {
                        text.appendAttributedString(NSAttributedString(string: "\(action.name). ", attributes: featureNameStyle))
                        
                        var attributes = featureTextStyle
                        action.text.enumerateLines { line, stop in
                            text.appendAttributedString(NSAttributedString(string: "\(line)\n", attributes: attributes))
                            attributes = featureContinuedStyle
                        }
                    }
                }
                
                if monster.reactions.count > 0 {
                    text.appendAttributedString(NSAttributedString(string: "Reactions\n", attributes: titleStyle))
                
                    for case let reaction as Reaction in monster.reactions {
                        text.appendAttributedString(NSAttributedString(string: "\(reaction.name). ", attributes: featureNameStyle))
                        
                        var attributes = featureTextStyle
                        reaction.text.enumerateLines { line, stop in
                            text.appendAttributedString(NSAttributedString(string: "\(line)\n", attributes: attributes))
                            attributes = featureContinuedStyle
                        }
                    }
                }

                if monster.legendaryActions.count > 0 {
                    text.appendAttributedString(NSAttributedString(string: "Legendary Actions\n", attributes: titleStyle))
                
                    for case let legendaryAction as LegendaryAction in monster.legendaryActions {
                        text.appendAttributedString(NSAttributedString(string: "\(legendaryAction.name). ", attributes: featureNameStyle))
                        
                        var attributes = featureTextStyle
                        legendaryAction.text.enumerateLines { line, stop in
                            text.appendAttributedString(NSAttributedString(string: "\(line)\n", attributes: attributes))
                            attributes = featureContinuedStyle
                        }
                    }
                }
                
                if let lair = monster.lair {
                    text.appendAttributedString(NSAttributedString(string: "Lair\n", attributes: titleStyle))

                    var attributes = featureTextStyle
                    lair.text.enumerateLines { line, stop in
                        text.appendAttributedString(NSAttributedString(string: "\(line)\n", attributes: attributes))
                        attributes = featureContinuedStyle
                    }

                    if lair.lairActions.count > 0 {
                        text.appendAttributedString(NSAttributedString(string: "Lair Actions\n", attributes: titleStyle))
                        
                        attributes = featureTextStyle
                        lair.lairActionsText?.enumerateLines { line, stop in
                            text.appendAttributedString(NSAttributedString(string: "\(line)\n", attributes: attributes))
                            attributes = featureContinuedStyle
                        }

                        for case let lairAction as LairAction in lair.lairActions {
                            attributes = featureTextStyle
                            lairAction.text.enumerateLines { line, stop in
                                text.appendAttributedString(NSAttributedString(string: "\(line)\n", attributes: attributes))
                                attributes = featureContinuedStyle
                            }
                        }
                        
                        attributes = featureTextStyle
                        lair.lairActionsLimit?.enumerateLines { line, stop in
                            text.appendAttributedString(NSAttributedString(string: "\(line)\n", attributes: attributes))
                            attributes = featureContinuedStyle
                        }
                    }
                    
                    if lair.lairTraits.count > 0 {
                        text.appendAttributedString(NSAttributedString(string: "Lair Traits\n", attributes: titleStyle))
                    
                        attributes = featureTextStyle
                        lair.lairTraitsText?.enumerateLines { line, stop in
                            text.appendAttributedString(NSAttributedString(string: "\(line)\n", attributes: attributes))
                            attributes = featureContinuedStyle
                        }

                        for case let lairTrait as LairTrait in lair.lairTraits {
                            var attributes = featureTextStyle
                            lairTrait.text.enumerateLines { line, stop in
                                text.appendAttributedString(NSAttributedString(string: "\(line)\n", attributes: attributes))
                                attributes = featureContinuedStyle
                            }
                        }
                        
                        attributes = featureTextStyle
                        lair.lairTraitsDuration?.enumerateLines { line, stop in
                            text.appendAttributedString(NSAttributedString(string: "\(line)\n", attributes: attributes))
                            attributes = featureContinuedStyle
                        }
                    }
                    
                    if lair.regionalEffects.count > 0 {
                        text.appendAttributedString(NSAttributedString(string: "Regional Effects\n", attributes: titleStyle))

                        attributes = featureTextStyle
                        lair.regionalEffectsText?.enumerateLines { line, stop in
                            text.appendAttributedString(NSAttributedString(string: "\(line)\n", attributes: attributes))
                            attributes = featureContinuedStyle
                        }

                        for case let regionalEffect as RegionalEffect in lair.regionalEffects {
                            var attributes = featureTextStyle
                            regionalEffect.text.enumerateLines { line, stop in
                                text.appendAttributedString(NSAttributedString(string: "\(line)\n", attributes: attributes))
                                attributes = featureContinuedStyle
                            }
                        }
                        
                        attributes = featureTextStyle
                        lair.regionalEffectsDuration?.enumerateLines { line, stop in
                            text.appendAttributedString(NSAttributedString(string: "\(line)\n", attributes: attributes))
                            attributes = featureContinuedStyle
                        }
                    }
                }

                textView.scrollEnabled = false
                textView.attributedText = text
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        textView.scrollEnabled = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

