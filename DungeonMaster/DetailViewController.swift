//
//  DetailViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 11/20/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

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
                text.appendAttributedString(NSAttributedString(string: "\(monster.sizeTypeAlignment)\n", attributes: sizeTypeAlignmentStyle))
                
                text.appendAttributedString(NSAttributedString(string: "Armor Class ", attributes: statsLabelStyle))
                text.appendAttributedString(NSAttributedString(string: "\(monster.armorClass)\n", attributes: statsValueStyle))
                
                let hitPoints = monster.hitPoints ?? monster.hitDice.averageValue
                text.appendAttributedString(NSAttributedString(string: "Hit Points ", attributes: statsLabelStyle))
                text.appendAttributedString(NSAttributedString(string: "\(hitPoints) (\(monster.hitDice.description))\n", attributes: statsValueStyle))

                text.appendAttributedString(NSAttributedString(string: "Speed ", attributes: statsLabelStyle))
                text.appendAttributedString(NSAttributedString(string: "\(monster.speed)\n", attributes: statsValueStyle))
                
                let str = String(format: "%d (%+d)", monster.strength, monster.strengthModifier)
                let dex = String(format: "%d (%+d)", monster.dexterity, monster.dexterityModifier)
                let con = String(format: "%d (%+d)", monster.constitution, monster.constitutionModifier)
                let int = String(format: "%d (%+d)", monster.intelligence, monster.intelligenceModifier)
                let wis = String(format: "%d (%+d)", monster.wisdom, monster.wisdomModifier)
                let cha = String(format: "%d (%+d)", monster.charisma, monster.charismaModifier)
                
                text.appendAttributedString(NSAttributedString(string: "\tSTR\tDEX\tCON\tINT\tWIS\tCHA\n", attributes: abilityScoresLabelStyle))
                text.appendAttributedString(NSAttributedString(string: "\t\(str)\t\(dex)\t\(con)\t\(int)\t\(wis)\t\(cha)\n", attributes: abilityScoresValueStyle))
                
                
                if let savingThrows = monster.savingThrows {
                    text.appendAttributedString(NSAttributedString(string: "Saving Throws ", attributes: statsLabelStyle))
                    text.appendAttributedString(NSAttributedString(string: "\(savingThrows)\n", attributes: statsValueStyle))
                }

                if let skills = monster.skills {
                    text.appendAttributedString(NSAttributedString(string: "Skills ", attributes: statsLabelStyle))
                    text.appendAttributedString(NSAttributedString(string: "\(skills)\n", attributes: statsValueStyle))
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
                text.appendAttributedString(NSAttributedString(string: "\(monster.senses)\n", attributes: statsValueStyle))

                text.appendAttributedString(NSAttributedString(string: "Languages ", attributes: statsLabelStyle))
                if let languages = monster.languages {
                    text.appendAttributedString(NSAttributedString(string: "\(languages)\n", attributes: statsValueStyle))
                } else {
                    text.appendAttributedString(NSAttributedString(string: "—\n", attributes: statsValueStyle))
                }

                text.appendAttributedString(NSAttributedString(string: "Challenge ", attributes: statsLabelStyle))
                text.appendAttributedString(NSAttributedString(string: "\(monster.challenge)\n", attributes: statsValueStyle))
                
                for trait in monster.allTraits {
                    text.appendAttributedString(NSAttributedString(string: "\(trait.name). ", attributes: featureNameStyle))
                    
                    var attributes = featureTextStyle
                    trait.text.enumerateLines { line, stop in
                        text.appendAttributedString(NSAttributedString(string: "\(line)\n", attributes: attributes))
                        attributes = featureContinuedStyle
                    }
                }

                if monster.actions.count > 0 {
                    text.appendAttributedString(NSAttributedString(string: "Actions\n", attributes: titleStyle))
                
                    for action in monster.allActions {
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
                
                    for reaction in monster.allReactions {
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
                
                    for legendaryAction in monster.allLegendaryActions {
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

                        for lairAction in lair.allLairActions {
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

                        for lairTrait in lair.allLairTraits {
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

                        for regionalEffect in lair.allRegionalEffects {
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

                textView.attributedText = text
                textView.scrollRangeToVisible(NSRange(location: 0, length: 0))
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

