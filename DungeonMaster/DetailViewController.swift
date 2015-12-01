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

                text.appendAttributedString(NSAttributedString(string: "Hit Points ", attributes: statsLabelStyle))
                text.appendAttributedString(NSAttributedString(string: "\(monster.hitPoints)\n", attributes: statsValueStyle))

                text.appendAttributedString(NSAttributedString(string: "Speed ", attributes: statsLabelStyle))
                text.appendAttributedString(NSAttributedString(string: "\(monster.speed)\n", attributes: statsValueStyle))
                
                text.appendAttributedString(NSAttributedString(string: "\tSTR\tDEX\tCON\tINT\tWIS\tCHA\n", attributes: abilityScoresLabelStyle))
                
                text.appendAttributedString(NSAttributedString(string: "\t\(monster.strength)", attributes: abilityScoresValueStyle))
                text.appendAttributedString(NSAttributedString(string: "\t\(monster.dexterity)", attributes: abilityScoresValueStyle))
                text.appendAttributedString(NSAttributedString(string: "\t\(monster.constitution)", attributes: abilityScoresValueStyle))
                text.appendAttributedString(NSAttributedString(string: "\t\(monster.intelligence)", attributes: abilityScoresValueStyle))
                text.appendAttributedString(NSAttributedString(string: "\t\(monster.wisdom)", attributes: abilityScoresValueStyle))
                text.appendAttributedString(NSAttributedString(string: "\t\(monster.charisma)", attributes: abilityScoresValueStyle))
                text.appendAttributedString(NSAttributedString(string: "\n", attributes: abilityScoresValueStyle))

                
                
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
                text.appendAttributedString(NSAttributedString(string: "\(monster.languages)\n", attributes: statsValueStyle))

                text.appendAttributedString(NSAttributedString(string: "Challenge ", attributes: statsLabelStyle))
                text.appendAttributedString(NSAttributedString(string: "\(monster.challenge)\n", attributes: statsValueStyle))

                var nextIsName = true
                var lastWasText = false
                var suppressNames = false
                var resumeNamesAfterText = false
                monster.text.enumerateLines {
                    line, stop in
                    
                    if line == "" {
                        if !suppressNames {
                            nextIsName = true
                        }
                        lastWasText = false
                    } else if line == line.uppercaseString {
                        text.appendAttributedString(NSAttributedString(string: "\(line.capitalizedString)\n", attributes: titleStyle))
                        if line != "ACTIONS" && line != "REACTIONS" {
                            suppressNames = true
                            nextIsName = false
                            if line == "LEGENDARY ACTIONS" {
                                resumeNamesAfterText = true
                            }
                        }
                    } else if nextIsName {
                        text.appendAttributedString(NSAttributedString(string: "\(line) ", attributes: featureNameStyle))
                        nextIsName = false
                    } else {
                        if lastWasText {
                            text.appendAttributedString(NSAttributedString(string: "\(line)\n", attributes: featureContinuedStyle))
                        } else {
                            text.appendAttributedString(NSAttributedString(string: "\(line)\n", attributes: featureTextStyle))
                        }
                        lastWasText = true
                        if resumeNamesAfterText {
                            suppressNames = false
                            resumeNamesAfterText = false
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

