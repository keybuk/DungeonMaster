//
//  DetailViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 11/20/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit
import CoreData

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
                    sizeType = "\(swarmSize.stringValue.capitalizedString) swarm of \(monster.size.stringValue.capitalizedString) \(monster.type.stringValue)s"
                } else {
                    sizeType = "\(monster.size.stringValue.capitalizedString) \(monster.type.stringValue)"
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
                    text.appendAttributedString(NSAttributedString(string: ", \(alignment.stringValue)\n", attributes: sizeTypeAlignmentStyle))
                } else if monster.alignmentOptions.filter({ ($0 as! AlignmentOption).weight != nil }).count > 0 {
                    // By weight
                    let weightSortDescriptor = NSSortDescriptor(key: "rawWeight", ascending: false)
                    let alignmentSortDescriptor = NSSortDescriptor(key: "rawAlignment", ascending: true)
                    
                    let alignmentString = monster.alignmentOptions.sortedArrayUsingDescriptors([ weightSortDescriptor, alignmentSortDescriptor ]).map {
                        let alignmentOption = $0 as! AlignmentOption
                        let formattedWeight = NSString(format: "%.0f", alignmentOption.weight! * 100.0)
                        return "\(alignmentOption.alignment.stringValue) (\(formattedWeight)%)"
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

                let basicArmorPredicate = NSPredicate(format: "rawCondition == nil AND spellName == nil AND form == nil")
                for case let armor as Armor in monster.armor.filteredSetUsingPredicate(basicArmorPredicate) {
                    switch armor.type {
                    case .None:
                        armorString += "\(armor.armorClass)"
                    default:
                        var typeString = armor.type.stringValue
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
                    armorString += ", \(armor.armorClass) while \(armor.condition!.stringValue)"
                }
                
                do {
                    let fetchRequest = NSFetchRequest(entity: Model.Armor)
                    fetchRequest.predicate = NSPredicate(format: "monster = %@ AND form != nil", monster)
                    fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "rawArmorClass", ascending: true) ]

                    for armor in try managedObjectContext.executeFetchRequest(fetchRequest) as! [Armor] {
                        if armorString != "" {
                            armorString += ", "
                        }
                        
                        switch armor.type {
                        case .None:
                            armorString += "\(armor.armorClass)"
                        default:
                            if armor.includesShield {
                                armorString += "\(armor.armorClass) (\(armor.type.stringValue), shield)"
                            } else {
                                armorString += "\(armor.armorClass) (\(armor.type.stringValue))"
                            }
                        }
                        
                        armorString += " \(armor.form!)"
                    }
                } catch {
                    let error = error as NSError
                    print("Unresolved error \(error), \(error.userInfo)")
                    abort()
                }
                
                text.appendAttributedString(NSAttributedString(string: "Armor Class ", attributes: statsLabelStyle))
                text.appendAttributedString(NSAttributedString(string: "\(armorString)\n", attributes: statsValueStyle))
                
                let hitPoints = monster.hitPoints ?? monster.hitDice.averageValue
                text.appendAttributedString(NSAttributedString(string: "Hit Points ", attributes: statsLabelStyle))
                text.appendAttributedString(NSAttributedString(string: "\(hitPoints) (\(monster.hitDice.description))\n", attributes: statsValueStyle))

                text.appendAttributedString(NSAttributedString(string: "Speed ", attributes: statsLabelStyle))
                text.appendAttributedString(NSAttributedString(string: "\(monster.speed)\n", attributes: statsValueStyle))
                
                let str = String(format: "%d (%+d)", monster.strengthScore, monster.strengthModifier)
                let dex = String(format: "%d (%+d)", monster.dexterityScore, monster.dexterityModifier)
                let con = String(format: "%d (%+d)", monster.constitutionScore, monster.constitutionModifier)
                let int = String(format: "%d (%+d)", monster.intelligenceScore, monster.intelligenceModifier)
                let wis = String(format: "%d (%+d)", monster.wisdomScore, monster.wisdomModifier)
                let cha = String(format: "%d (%+d)", monster.charismaScore, monster.charismaModifier)
                
                text.appendAttributedString(NSAttributedString(string: "\tSTR\tDEX\tCON\tINT\tWIS\tCHA\n", attributes: abilityScoresLabelStyle))
                text.appendAttributedString(NSAttributedString(string: "\t\(str)\t\(dex)\t\(con)\t\(int)\t\(wis)\t\(cha)\n", attributes: abilityScoresValueStyle))
                
                var savingThrows = [String]()
                if monster.strengthSavingThrow != monster.strengthModifier {
                    savingThrows.append(String(format: "Str %+d", monster.strengthSavingThrow))
                }
                if monster.dexteritySavingThrow != monster.dexterityModifier {
                    savingThrows.append(String(format: "Dex %+d", monster.dexteritySavingThrow))
                }
                if monster.constitutionSavingThrow != monster.constitutionModifier {
                    savingThrows.append(String(format: "Con %+d", monster.constitutionSavingThrow))
                }
                if monster.intelligenceSavingThrow != monster.intelligenceModifier {
                    savingThrows.append(String(format: "Int %+d", monster.intelligenceSavingThrow))
                }
                if monster.wisdomSavingThrow != monster.wisdomModifier {
                    savingThrows.append(String(format: "Wis %+d", monster.wisdomSavingThrow))
                }
                if monster.charismaSavingThrow != monster.charismaModifier {
                    savingThrows.append(String(format: "Cha %+d", monster.charismaSavingThrow))
                }

                if savingThrows.count > 0 {
                    let savingThrowsString = savingThrows.joinWithSeparator(", ")
                    text.appendAttributedString(NSAttributedString(string: "Saving Throws ", attributes: statsLabelStyle))
                    text.appendAttributedString(NSAttributedString(string: "\(savingThrowsString)\n", attributes: statsValueStyle))
                }
                
                var skills = [String]()
                if monster.acrobaticsSkill != monster.dexterityModifier {
                    skills.append(String(format: "Acrobatics %+d", monster.acrobaticsSkill))
                }
                if monster.animalHandlingSkill != monster.wisdomModifier {
                    skills.append(String(format: "Animal Handling %+d", monster.animalHandlingSkill))
                }
                if monster.arcanaSkill != monster.intelligenceModifier {
                    skills.append(String(format: "Arcana %+d", monster.arcanaSkill))
                }
                if monster.athleticsSkill != monster.strengthModifier {
                    skills.append(String(format: "Athletics %+d", monster.athleticsSkill))
                }
                if monster.deceptionSkill != monster.charismaModifier {
                    skills.append(String(format: "Deception %+d", monster.deceptionSkill))
                }
                if monster.historySkill != monster.intelligenceModifier {
                    skills.append(String(format: "History %+d", monster.historySkill))
                }
                if monster.insightSkill != monster.wisdomModifier {
                    skills.append(String(format: "Insight %+d", monster.insightSkill))
                }
                if monster.intimidationSkill != monster.charismaModifier {
                    skills.append(String(format: "Intimidation %+d", monster.intimidationSkill))
                }
                if monster.investigationSkill != monster.intelligenceModifier {
                    skills.append(String(format: "Investigation %+d", monster.investigationSkill))
                }
                if monster.medicineSkill != monster.wisdomModifier {
                    skills.append(String(format: "Medicine %+d", monster.medicineSkill))
                }
                if monster.natureSkill != monster.intelligenceModifier {
                    skills.append(String(format: "Nature %+d", monster.natureSkill))
                }
                if monster.perceptionSkill != monster.wisdomModifier {
                    skills.append(String(format: "Perception %+d", monster.perceptionSkill))
                }
                if monster.performanceSkill != monster.charismaModifier {
                    skills.append(String(format: "Performance %+d", monster.performanceSkill))
                }
                if monster.persuasionSkill != monster.charismaModifier {
                    skills.append(String(format: "Persuasion %+d", monster.persuasionSkill))
                }
                if monster.religionSkill != monster.intelligenceModifier {
                    skills.append(String(format: "Religion %+d", monster.religionSkill))
                }
                if monster.sleightOfHandSkill != monster.dexterityModifier {
                    skills.append(String(format: "Sleight of Hand %+d", monster.sleightOfHandSkill))
                }
                if monster.stealthSkill != monster.dexterityModifier {
                    skills.append(String(format: "Stealth %+d", monster.stealthSkill))
                }
                if monster.survivalSkill != monster.wisdomModifier {
                    skills.append(String(format: "Survival %+d", monster.survivalSkill))
                }

                if skills.count > 0 {
                    let skillsString = skills.joinWithSeparator(", ")
                    text.appendAttributedString(NSAttributedString(string: "Skills ", attributes: statsLabelStyle))
                    text.appendAttributedString(NSAttributedString(string: "\(skillsString)\n", attributes: statsValueStyle))
                }
    
                if let damageVulnerabilities = monster.damageVulnerabilities {
                    text.appendAttributedString(NSAttributedString(string: "Damage Vulnerabilities ", attributes: statsLabelStyle))
                    text.appendAttributedString(NSAttributedString(string: "\(damageVulnerabilities)\n", attributes: statsValueStyle))
                }

                if let damageResistances = monster.damageResistances {
                    text.appendAttributedString(NSAttributedString(string: "Damage Resistances ", attributes: statsLabelStyle))
                    text.appendAttributedString(NSAttributedString(string: "\(damageResistances)\n", attributes: statsValueStyle))
                }
    
                if let damageImmunities = monster.damageImmunities {
                    text.appendAttributedString(NSAttributedString(string: "Damage Immunities ", attributes: statsLabelStyle))
                    text.appendAttributedString(NSAttributedString(string: "\(damageImmunities)\n", attributes: statsValueStyle))
                }

                if let conditionImmunities = monster.conditionImmunities {
                    text.appendAttributedString(NSAttributedString(string: "Condition Immunities ", attributes: statsLabelStyle))
                    text.appendAttributedString(NSAttributedString(string: "\(conditionImmunities)\n", attributes: statsValueStyle))
                }

                text.appendAttributedString(NSAttributedString(string: "Senses ", attributes: statsLabelStyle))
                if let senses = monster.senses {
                    text.appendAttributedString(NSAttributedString(string: "\(senses), ", attributes: statsValueStyle))
                }
                text.appendAttributedString(NSAttributedString(string: "passive Perception \(monster.passivePerception)\n", attributes: statsValueStyle))

                text.appendAttributedString(NSAttributedString(string: "Languages ", attributes: statsLabelStyle))
                if let languages = monster.languages {
                    text.appendAttributedString(NSAttributedString(string: "\(languages)\n", attributes: statsValueStyle))
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

