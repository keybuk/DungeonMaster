//
//  MonsterViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 11/20/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class MonsterViewController : UIViewController {

    @IBOutlet var textView: UITextView!

    var monster: Monster! {
        didSet {
            configureView()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        textView.textContainerInset.left = 10.0
        textView.textContainerInset.right = 10.0

        // Disable scrolling, otherwise we end up at the bottom.
        textView.isScrollEnabled = false
        configureView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Enable scrolling, doing this earlier just scrolls to the bottom again.
        textView.isScrollEnabled = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        configureView()
    }

    func configureView() {
        guard let textView = textView else { return }
        guard let monster = monster else { return }
        
        let markupParser = MarkupParser()
        markupParser.paragraphSpacingBefore = markupParser.paragraphSpacing
        markupParser.tableWidth = textView.bounds.size.width - textView.textContainerInset.left - textView.textContainerInset.right
        markupParser.linkColor = textView.tintColor
        

        let nameFont = UIFontDescriptor.preferredFontDescriptor(withTextStyle: UIFontTextStyle.title1)

        let subheadlineFont = UIFontDescriptor.preferredFontDescriptor(withTextStyle: UIFontTextStyle.subheadline)
        let subheadlineItalicFont = subheadlineFont.withSymbolicTraits(.traitItalic)

        let bodyFont = UIFontDescriptor.preferredFontDescriptor(withTextStyle: UIFontTextStyle.body)
        let bodyBoldFont = bodyFont.withSymbolicTraits(.traitBold)
        let bodyBoldItalicFont = bodyFont.withSymbolicTraits([ .traitBold, .traitItalic ])

        let titleFont = UIFontDescriptor.preferredFontDescriptor(withTextStyle: UIFontTextStyle.title2)

        
        let nameStyle = [
            NSFontAttributeName: UIFont(descriptor: nameFont, size: 0.0),
        ]
        

        let sizeTypeAlignmentParaStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        sizeTypeAlignmentParaStyle.paragraphSpacing = 12.0

        let sizeTypeAlignmentStyle = [
            NSFontAttributeName: UIFont(descriptor: subheadlineItalicFont!, size: 0.0),
            NSParagraphStyleAttributeName: sizeTypeAlignmentParaStyle
        ]
        

        let statsParaStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        statsParaStyle.headIndent = 12.0
        
        let statsLabelStyle = [
            NSFontAttributeName: UIFont(descriptor: bodyBoldFont!, size: 0.0),
            NSParagraphStyleAttributeName: statsParaStyle,
        ]

        let statsValueStyle = [
            NSFontAttributeName: UIFont(descriptor: bodyFont, size: 0.0),
            NSParagraphStyleAttributeName: statsParaStyle,
        ]
        
        
        let abilityScoresParaStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        
        let cellWidth = markupParser.tableWidth! / 6

        abilityScoresParaStyle.tabStops = [
            NSTextTab(textAlignment: .center, location: 0.5 * cellWidth, options: [String:AnyObject]()),
            NSTextTab(textAlignment: .center, location: 1.5 * cellWidth, options: [String:AnyObject]()),
            NSTextTab(textAlignment: .center, location: 2.5 * cellWidth, options: [String:AnyObject]()),
            NSTextTab(textAlignment: .center, location: 3.5 * cellWidth, options: [String:AnyObject]()),
            NSTextTab(textAlignment: .center, location: 4.5 * cellWidth, options: [String:AnyObject]()),
            NSTextTab(textAlignment: .center, location: 5.5 * cellWidth, options: [String:AnyObject]()),
            ]
        
        let abilityScoresLabelParaStyle = abilityScoresParaStyle.mutableCopy() as! NSMutableParagraphStyle
        abilityScoresLabelParaStyle.paragraphSpacingBefore = 12.0
        
        let abilityScoresValueParaStyle = abilityScoresParaStyle.mutableCopy() as! NSMutableParagraphStyle
        abilityScoresValueParaStyle.paragraphSpacing = 12.0
        
        let abilityScoresLabelStyle = [
            NSFontAttributeName: UIFont(descriptor: bodyBoldFont!, size: 0.0),
            NSParagraphStyleAttributeName: abilityScoresLabelParaStyle,
        ]
        
        let abilityScoresValueStyle = [
            NSFontAttributeName: UIFont(descriptor: bodyFont, size: 0.0),
            NSParagraphStyleAttributeName: abilityScoresValueParaStyle,
        ]


        let titleParaStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        titleParaStyle.paragraphSpacingBefore = 24.0
        
        let titleStyle = [
            NSFontAttributeName: UIFont(descriptor: titleFont, size: 0.0),
            NSParagraphStyleAttributeName: titleParaStyle,
        ]


        let text = NSMutableAttributedString()
        
        text.append(NSAttributedString(string: "\(monster.name)\n", attributes: nameStyle))
        
        
        let sizeType: String
        if let swarmSize = monster.swarmSize {
            sizeType = "\(swarmSize.stringValue) swarm of \(monster.size.stringValue) \(monster.type.stringValue)s"
        } else {
            sizeType = "\(monster.size.stringValue) \(monster.type.stringValue.lowercased())"
        }
        text.append(NSAttributedString(string: "\(sizeType)", attributes: sizeTypeAlignmentStyle))

        if monster.tags.count > 0 || monster.requiresRace {
            let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
            var tags = monster.tags.sortedArray(using: [ sortDescriptor ]).map { ($0 as! Tag).name }
            if monster.requiresRace {
                tags.insert("any race", at: 0)
            }
            let tagString = tags.joined(separator: ", ")
            text.append(NSAttributedString(string: " (\(tagString))", attributes: sizeTypeAlignmentStyle))
        }
        
        if let alignment = monster.alignment {
            text.append(NSAttributedString(string: ", \(alignment.stringValue.lowercased())\n", attributes: sizeTypeAlignmentStyle))
        } else if monster.alignmentOptions.filter({ ($0 as! AlignmentOption).weight != nil }).count > 0 {
            // By weight
            let weightSortDescriptor = NSSortDescriptor(key: "rawWeight", ascending: false)
            let alignmentSortDescriptor = NSSortDescriptor(key: "rawAlignment", ascending: true)
            
            let alignmentString = monster.alignmentOptions.sortedArray(using: [ weightSortDescriptor, alignmentSortDescriptor ]).map({
                let alignmentOption = $0 as! AlignmentOption
                let formattedWeight = NSString(format: "%.0f", alignmentOption.weight! * 100.0)
                return "\(alignmentOption.alignment.stringValue.lowercased()) (\(formattedWeight)%)"
            }).joined(separator: " or ")
            
            text.append(NSAttributedString(string: ", \(alignmentString)\n", attributes: sizeTypeAlignmentStyle))

        } else {
            // By set;
            let alignmentSet = Set<Alignment>(monster.alignmentOptions.map({ ($0 as! AlignmentOption).alignment }))
            
            let alignmentString: String
            if alignmentSet == Set(Alignment.cases) {
                alignmentString = "any alignment"
            } else if alignmentSet == Alignment.chaoticAlignments {
                alignmentString = "any chaotic alignment"
            } else if alignmentSet == Alignment.evilAlignments {
                alignmentString = "any evil alignment"
            } else if alignmentSet == Set(Alignment.cases).subtracting(Alignment.goodAlignments) {
                alignmentString = "any non-good alignment"
            } else if alignmentSet == Set(Alignment.cases).subtracting(Alignment.lawfulAlignments) {
                alignmentString = "any non-lawful alignment"
            } else {
                alignmentString = "various alignments"
            }
            
            text.append(NSAttributedString(string: ", \(alignmentString)\n", attributes: sizeTypeAlignmentStyle))
        }
        
        var armorString = ""

        let basicArmorPredicate = NSPredicate(format: "rawCondition == nil AND spellName == nil")
        for case let armor as Armor in monster.armor.filtered(using: basicArmorPredicate) {
            switch armor.type {
            case .none:
                armorString += "\(armor.armorClass)"
            default:
                var typeString = armor.type.stringValue.lowercased()
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
        for case let armor as Armor in monster.armor.filtered(using: spellArmorPredicate) {
            armorString += " (\(armor.armorClass) with \(armor.spellName!))"
        }
        
        let conditionArmorPredicate = NSPredicate(format: "rawCondition != nil")
        for case let armor as Armor in monster.armor.filtered(using: conditionArmorPredicate) {
            armorString += ", \(armor.armorClass) while \(armor.condition!.stringValue.lowercased())"
        }
        
        text.append(NSAttributedString(string: "Armor Class ", attributes: statsLabelStyle))
        text.append(NSAttributedString(string: "\(armorString)\n", attributes: statsValueStyle))
        
        let hitPoints = monster.hitPoints ?? monster.hitDice.averageValue
        text.append(NSAttributedString(string: "Hit Points ", attributes: statsLabelStyle))
        text.append(NSAttributedString(string: "\(hitPoints) (\(monster.hitDice.description))\n", attributes: statsValueStyle))

        text.append(NSAttributedString(string: "Speed ", attributes: statsLabelStyle))
        text.append(NSAttributedString(string: "\(monster.speed) ft.", attributes: statsValueStyle))
        
        if let speed = monster.burrowSpeed {
            text.append(NSAttributedString(string: ", burrow \(speed) ft.", attributes: statsValueStyle))
        }
        
        if let speed = monster.climbSpeed {
            text.append(NSAttributedString(string: ", climb \(speed) ft.", attributes: statsValueStyle))
        }

        if let speed = monster.flySpeed {
            text.append(NSAttributedString(string: ", fly \(speed) ft.", attributes: statsValueStyle))
            if monster.canHover {
                text.append(NSAttributedString(string: " (hover)", attributes: statsValueStyle))
            }
        }

        if let speed = monster.swimSpeed {
            text.append(NSAttributedString(string: ", swim \(speed) ft.", attributes: statsValueStyle))
        }
        text.append(NSAttributedString(string: "\n", attributes: statsValueStyle))

        let str = String(format: "%d (%+d)", monster.strengthScore, monster.modifier(forAbility: .strength))
        let dex = String(format: "%d (%+d)", monster.dexterityScore, monster.modifier(forAbility: .dexterity))
        let con = String(format: "%d (%+d)", monster.constitutionScore, monster.modifier(forAbility: .constitution))
        let int = String(format: "%d (%+d)", monster.intelligenceScore, monster.modifier(forAbility: .intelligence))
        let wis = String(format: "%d (%+d)", monster.wisdomScore, monster.modifier(forAbility: .wisdom))
        let cha = String(format: "%d (%+d)", monster.charismaScore, monster.modifier(forAbility: .charisma))
        
        text.append(NSAttributedString(string: "\tSTR\tDEX\tCON\tINT\tWIS\tCHA\n", attributes: abilityScoresLabelStyle))
        text.append(NSAttributedString(string: "\t\(str)\t\(dex)\t\(con)\t\(int)\t\(wis)\t\(cha)\n", attributes: abilityScoresValueStyle))
        
        if monster.savingThrows.count > 0 {
            let sortDescriptor = NSSortDescriptor(key: "rawSavingThrow", ascending: true)
            let savingThrowsString = monster.savingThrows.sortedArray(using: [ sortDescriptor ]).map({
                String(format: "%@ %+d", ($0 as! MonsterSavingThrow).savingThrow.shortStringValue, ($0 as! MonsterSavingThrow).modifier)
            }).joined(separator: ", ")
            
            text.append(NSAttributedString(string: "Saving Throws ", attributes: statsLabelStyle))
            text.append(NSAttributedString(string: "\(savingThrowsString)\n", attributes: statsValueStyle))
        }
        
        if monster.skills.count > 0 {
            let skillsString = monster.skills.map({
                String(format: "%@ %+d", ($0 as! MonsterSkill).skill.stringValue, ($0 as! MonsterSkill).modifier)
            }).sorted().joined(separator: ", ")

            text.append(NSAttributedString(string: "Skills ", attributes: statsLabelStyle))
            text.append(NSAttributedString(string: "\(skillsString)\n", attributes: statsValueStyle))
        }
        
        func damageList(_ damages: NSSet, spellDamage: Bool = false) -> String {
            var damageList = ""

            let allAttacksPredicate = NSPredicate(format: "rawAttackType == %@", NSNumber(value: AttackType.all.rawValue as Int))
            let allAttackDamages = damages.filtered(using: allAttacksPredicate)
            
            if spellDamage {
                damageList += "damage from spells"
                if damages.count > 0 {
                    damageList += "; "
                }
            }
            
            if allAttackDamages.count > 0 {
                damageList += allAttackDamages.map({
                    DamageType(rawValue: (($0 as! NSManagedObject).value(forKey: "rawDamageType") as! NSNumber).intValue)!.stringValue.lowercased()
                }).sorted(by: <).joined(separator: ", ")
                
                if allAttackDamages.count < damages.count || spellDamage {
                    damageList += "; "
                }
            }
            
            let otherAttacksPredicate = NSPredicate(format: "rawAttackType != %@", NSNumber(value: AttackType.all.rawValue as Int))
            let otherAttackDamages = damages.filtered(using: otherAttacksPredicate)
            
            if otherAttackDamages.count > 0 {
                let anyDamage = (otherAttackDamages.first! as! NSManagedObject)
                let attackType = AttackType(rawValue: (anyDamage.value(forKey: "rawAttackType") as! NSNumber).intValue)!

                if spellDamage && attackType == .nonmagical && anyDamage.value(forKey: "spellName") != nil {
                    damageList += "nonmagical "
                }
                
                var damageStrings = otherAttackDamages.map({
                    DamageType(rawValue: (($0 as! NSManagedObject).value(forKey: "rawDamageType") as! NSNumber).intValue)!.stringValue.lowercased()
                }).sorted(by: <)
                let lastDamageString = damageStrings.removeLast()
                
                if damageStrings.count > 1 {
                    damageList += damageStrings.joined(separator: ", ") + ", and \(lastDamageString)"
                } else if damageStrings.count == 1 {
                    damageList += "\(damageStrings[0]) and \(lastDamageString)"
                } else {
                    damageList += lastDamageString
                }
                
                switch attackType {
                case .all:
                    break
                case .nonmagical:
                    if spellDamage && attackType == .nonmagical && anyDamage.value(forKey: "spellName") != nil {
                        let spellName = anyDamage.value(forKey: "spellName")! as! String
                        damageList += " (from \(spellName))"
                    } else {
                        damageList += " from nonmagical attacks"
                    }
                case .nonmagicalNotAdamantine:
                    damageList += " from nonmagical attacks not made with adamantine weapons"
                case .nonmagicalNotSilvered:
                    damageList += " from nonmagical attacks not made with silvered weapons"
                case .magical:
                    damageList += " from magic weapons"
                case .magicalByGood:
                    damageList += " from magic weapons wielded by good creatures"
                }
            }

            return damageList
        }
        
        if monster.damageVulnerabilities.count > 0 {
            text.append(NSAttributedString(string: "Damage Vulnerabilities ", attributes: statsLabelStyle))
            text.append(NSAttributedString(string: "\(damageList(monster.damageVulnerabilities))\n", attributes: statsValueStyle))
        }

        if monster.damageResistances.count > 0 {
            text.append(NSAttributedString(string: "Damage Resistances ", attributes: statsLabelStyle))
            text.append(NSAttributedString(string: "\(damageList(monster.damageResistances, spellDamage: monster.isResistantToSpellDamage))\n", attributes: statsValueStyle))
        } else if monster.damageResistanceOptions.count > 0 {
            text.append(NSAttributedString(string: "Damage Resistances ", attributes: statsLabelStyle))

            var damageStrings = monster.damageResistanceOptions.map({ ($0 as! DamageResistanceOption).damageType.stringValue.lowercased() }).sorted(by: <)
            let lastDamageString = damageStrings.removeLast()
            
            text.append(NSAttributedString(string: "one of the following: \(damageStrings.joined(separator: ", ")), or \(lastDamageString)\n", attributes: statsValueStyle))
        }
        
        if monster.damageImmunities.count > 0 {
            text.append(NSAttributedString(string: "Damage Immunities ", attributes: statsLabelStyle))
            text.append(NSAttributedString(string: "\(damageList(monster.damageImmunities))\n", attributes: statsValueStyle))
        }

        if monster.conditionImmunities.count > 0 {
            text.append(NSAttributedString(string: "Condition Immunities ", attributes: statsLabelStyle))
            
            let conditionStrings = monster.conditionImmunities.map({ ($0 as! ConditionImmunity).condition.stringValue.lowercased() }).sorted(by: <).joined(separator: ", ")
            text.append(NSAttributedString(string: "\(conditionStrings)\n", attributes: statsValueStyle))
        }

        text.append(NSAttributedString(string: "Senses ", attributes: statsLabelStyle))
        if let blindsight = monster.blindsight {
            text.append(NSAttributedString(string: "blindsight \(blindsight) ft.", attributes: statsValueStyle))
            if monster.isBlind {
                text.append(NSAttributedString(string: " (blind beyond this radius)", attributes: statsValueStyle))
            }
            text.append(NSAttributedString(string: ", ", attributes: statsValueStyle))

        }
        if let darkvision = monster.darkvision {
            text.append(NSAttributedString(string: "darkvision \(darkvision) ft., ", attributes: statsValueStyle))
        }
        if let tremorsense = monster.tremorsense {
            text.append(NSAttributedString(string: "tremorsense \(tremorsense) ft., ", attributes: statsValueStyle))
        }
        if let truesight = monster.truesight {
            text.append(NSAttributedString(string: "truesight \(truesight) ft., ", attributes: statsValueStyle))
        }
        text.append(NSAttributedString(string: "passive Perception \(monster.passivePerception)\n", attributes: statsValueStyle))

        var languageStrings: [String] = []
        text.append(NSAttributedString(string: "Languages ", attributes: statsLabelStyle))
        
        if monster.canSpeakAllLanguages {
            languageStrings.append("all")
        } else if monster.languagesSpoken.count > 0 {
            languageStrings.append(contentsOf: monster.languagesSpoken.map({ ($0 as! Language).name }).sorted(by: <))
            
            // Special case for "plus..."
            if let languagesSpokenOption = monster.languagesSpokenOption {
                var thisString = languageStrings.removeLast()
                
                switch languagesSpokenOption {
                case .anyOne:
                    thisString += " plus one other language"
                case .anyTwo:
                    thisString += " plus any two languages"
                case .anyFour:
                    thisString += " plus any four languages"
                case .upToFive:
                    thisString += " plus up to five other languages"
                case .anySix:
                    thisString += " plus any six languages"
                default:
                    break
                }
                
                languageStrings.append(thisString)
            }
        } else if let languagesSpokenOption = monster.languagesSpokenOption {
            switch languagesSpokenOption {
            case .usuallyCommon:
                languageStrings.append("any one language (usually Common)")
            case .knewInLife:
                languageStrings.append("the languages it knew in life")
            case .ofItsCreator:
                languageStrings.append("the languages of its creator")
            case .oneOfItsCreator:
                languageStrings.append("one language known by its creator")
            case .anyOne:
                languageStrings.append("any one language")
            case .anyTwo:
                languageStrings.append("any two languages")
            case .anyFour:
                languageStrings.append("any four languages")
            case .upToFive:
                languageStrings.append("up to five languages")
            case .anySix:
                languageStrings.append("any six languages")
            }
        }

        if monster.canUnderstandAllLanguages {
            if monster.type == .construct {
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
            var languageNames = monster.languagesUnderstood.map({ ($0 as! Language).name }).sorted(by: <)
            
            var thisString = "understands "
            if languageNames.count == 2 {
                thisString += "\(languageNames[0]) and \(languageNames[1])"
            } else {
                let lastName = languageNames.removeLast()
                thisString += "\(languageNames.joined(separator: ", ")), and \(lastName)"
            }
            thisString += " but can't speak"
            if languageStrings.count > 0 {
                thisString += " them"
            }
            
            languageStrings.append(thisString)
        } else if let languagesUnderstoodOption = monster.languagesUnderstoodOption {
            var thisString = "understands "
            
            switch languagesUnderstoodOption {
            case .usuallyCommon:
                thisString += "any one language (usually Common)"
            case .knewInLife:
                thisString += "the languages it knew in life"
            case .ofItsCreator:
                thisString += "the languages of its creator"
            case .oneOfItsCreator:
                thisString += "one language known by its creator"
            case .anyOne:
                thisString += "any one language"
            case .anyTwo:
                thisString += "any two languages"
            case .anyFour:
                thisString += "any four languages"
            case .upToFive:
                thisString += "up to five languages"
            case .anySix:
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
                let languages = monster.languagesSpoken.map({ ($0 as! Language).name }).sorted(by: <).joined(separator: ", ")

                languageString += " (works only with creatures that understand \(languages)))"
            }
            
            languageStrings.append(languageString)
        }
        
        if languageStrings.count > 0 {
            text.append(NSAttributedString(string: "\(languageStrings.joined(separator: ", "))\n", attributes: statsValueStyle))
        } else {
            text.append(NSAttributedString(string: "—\n", attributes: statsValueStyle))
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
        
        text.append(NSAttributedString(string: "Challenge ", attributes: statsLabelStyle))
        text.append(NSAttributedString(string: "\(challengeString) (\(monster.xpString))\n", attributes: statsValueStyle))
        
        for case let trait as Trait in monster.traits {
            markupParser.parse("***\(trait.name).*** \(trait.text)")
            text.append(markupParser.text)
            markupParser.reset()
        }
        
        if monster.actions.count > 0 {
            text.append(NSAttributedString(string: "Actions\n", attributes: titleStyle))
        
            for case let action as Action in monster.actions {
                markupParser.parse("***\(action.name).*** \(action.text)")
                text.append(markupParser.text)
                markupParser.reset()
            }
        }
        
        if monster.reactions.count > 0 {
            text.append(NSAttributedString(string: "Reactions\n", attributes: titleStyle))
        
            for case let reaction as Reaction in monster.reactions {
                markupParser.parse("***\(reaction.name).*** \(reaction.text)")
                text.append(markupParser.text)
                markupParser.reset()
            }
        }

        if monster.legendaryActions.count > 0 {
            text.append(NSAttributedString(string: "Legendary Actions\n", attributes: titleStyle))
        
            for case let legendaryAction as LegendaryAction in monster.legendaryActions {
                markupParser.parse("} **\(legendaryAction.name).** \(legendaryAction.text)")
            }
            
            text.append(markupParser.text)
            markupParser.reset()
        }
        
        if let lair = monster.lair {
            text.append(NSAttributedString(string: "Lair\n", attributes: titleStyle))
            
            markupParser.parse(lair.text)
            text.append(markupParser.text)
            markupParser.reset()

            if lair.lairActions.count > 0 {
                text.append(NSAttributedString(string: "Lair Actions\n", attributes: titleStyle))
                
                
                if let lairActionsText = lair.lairActionsText {
                    markupParser.parse(lairActionsText)
                }
                
                for case let lairAction as LairAction in lair.lairActions {
                    markupParser.parse(lairAction.text)
                }
                
                if let lairActionsLimit = lair.lairActionsLimit {
                    markupParser.parse(lairActionsLimit)
                }
                
                text.append(markupParser.text)
                markupParser.reset()
            }
            
            if lair.lairTraits.count > 0 {
                text.append(NSAttributedString(string: "Lair Traits\n", attributes: titleStyle))

                if let lairTraitsText = lair.lairTraitsText {
                    markupParser.parse(lairTraitsText)
                }

                for case let lairTrait as LairTrait in lair.lairTraits {
                    markupParser.parse(lairTrait.text)
                }
                
                if let lairTraitsDuration = lair.lairTraitsDuration {
                    markupParser.parse(lairTraitsDuration)
                }
                
                text.append(markupParser.text)
                markupParser.reset()
            }
            
            if lair.regionalEffects.count > 0 {
                text.append(NSAttributedString(string: "Regional Effects\n", attributes: titleStyle))
                
                if let regionalEffectsText = lair.regionalEffectsText {
                    markupParser.parse(regionalEffectsText)
                }

                for case let regionalEffect as RegionalEffect in lair.regionalEffects {
                    markupParser.parse(regionalEffect.text)
                }
                
                if let regionalEffectsDuration = lair.regionalEffectsDuration {
                    markupParser.parse(regionalEffectsDuration)
                }
                
                text.append(markupParser.text)
                markupParser.reset()
            }
        }

        textView.attributedText = text
    }

    // MARK: Actions
    
    @IBAction func textViewTapped(_ sender: UITapGestureRecognizer) {
        let textView = sender.view! as! UITextView
        
        var location = sender.location(in: textView)
        location.x -= textView.textContainerInset.left
        location.y -= textView.textContainerInset.top
        
        let index = textView.layoutManager.characterIndex(for: location, in: textView.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        if let linkName = textView.attributedText.attribute(MarkupParser.linkAttributeName, at: index, effectiveRange: nil) as? String {
            let fetchRequest = NSFetchRequest<Spell>()
            fetchRequest.entity = NSEntityDescription.entity(forModel: Model.Spell, in: managedObjectContext)
            fetchRequest.predicate = NSPredicate(format: "name LIKE[cd] %@", linkName)
            
            let spells = try! managedObjectContext.fetch(fetchRequest)
            if spells.count > 0 {
                let viewController = storyboard?.instantiateViewController(withIdentifier: "SpellViewController") as! SpellViewController
                viewController.spell = spells.first
                navigationController?.pushViewController(viewController, animated: true)
            }
        }
    }
    
}

