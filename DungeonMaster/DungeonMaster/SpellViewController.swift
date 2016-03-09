//
//  SpellViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/29/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class SpellViewController: UIViewController {

    @IBOutlet var textView: UITextView!
    
    var spell: Spell! {
        didSet {
            configureView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.textContainerInset.left = 10.0
        textView.textContainerInset.right = 10.0

        // Disable scrolling, otherwise we end up at the bottom.
        textView.scrollEnabled = false
        configureView()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Enable scrolling, doing this earlier just scrolls to the bottom again.
        textView.scrollEnabled = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        configureView()
    }
    
    func configureView() {
        guard let textView = textView else { return }
        guard let spell = spell else { return }

        let markupParser = MarkupParser()
        markupParser.tableWidth = textView.bounds.size.width - textView.textContainerInset.left - textView.textContainerInset.right
        markupParser.paragraphSpacingBefore = markupParser.paragraphSpacing
        markupParser.linkColor = textView.tintColor
        
    
        let nameFont = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleTitle1)
        
        let subheadlineFont = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleSubheadline)
        let subheadlineItalicFont = subheadlineFont.fontDescriptorWithSymbolicTraits(.TraitItalic)
        
        let bodyFont = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleBody)
        let bodyBoldFont = bodyFont.fontDescriptorWithSymbolicTraits(.TraitBold)
        
        let nameAttributes = [
            NSFontAttributeName: UIFont(descriptor: nameFont, size: 0.0),
        ]
        
        let levelSchoolParagraphStyle = NSMutableParagraphStyle()
        levelSchoolParagraphStyle.paragraphSpacing = 12.0
        
        let levelSchoolAttributes = [
            NSFontAttributeName: UIFont(descriptor: subheadlineItalicFont, size: 0.0),
            NSParagraphStyleAttributeName: levelSchoolParagraphStyle
        ]
        
        let statsParagraphStyle = NSMutableParagraphStyle()
        statsParagraphStyle.headIndent = 12.0
        
        let statsLabelAttributes = [
            NSFontAttributeName: UIFont(descriptor: bodyBoldFont, size: 0.0),
            NSParagraphStyleAttributeName: statsParagraphStyle,
        ]
        
        let statsValueAttributes = [
            NSFontAttributeName: UIFont(descriptor: bodyFont, size: 0.0),
            NSParagraphStyleAttributeName: statsParagraphStyle,
        ]
        
        
        let text = NSMutableAttributedString()
        
        text.appendAttributedString(NSAttributedString(string: "\(spell.name)\n", attributes: nameAttributes))
        
        
        var levelSchoolString: String
        switch spell.level {
        case 0:
            levelSchoolString = "\(spell.school.stringValue) cantrip"
        case 1:
            levelSchoolString = "1st-level \(spell.school.stringValue.lowercaseString)"
        case 2:
            levelSchoolString = "2nd-level \(spell.school.stringValue.lowercaseString)"
        case 3:
            levelSchoolString = "3rd-level \(spell.school.stringValue.lowercaseString)"
        default:
            levelSchoolString = "\(spell.level)th-level \(spell.school.stringValue.lowercaseString)"
        }
        
        if spell.canCastAsRitual {
            levelSchoolString += " (ritual)"
        }
        
        text.appendAttributedString(NSAttributedString(string: "\(levelSchoolString)\n", attributes: levelSchoolAttributes))
        
        
        text.appendAttributedString(NSAttributedString(string: "Casting Time: ", attributes: statsLabelAttributes))
        
        var castingTimeString = ""
        if spell.canCastAsAction {
            castingTimeString = "1 action"
            if let castingTime = spell.castingTime {
                if castingTime > 60 {
                    castingTimeString += " or \(castingTime / 60) hours"
                } else if castingTime == 60 {
                    castingTimeString += " or \(castingTime / 60) hour"
                } else if castingTime > 1 {
                    castingTimeString += " or \(castingTime) minutes"
                } else {
                    castingTimeString += " or \(castingTime) minute"
                }
            }
        } else if spell.canCastAsBonusAction {
            castingTimeString = "1 bonus action"
        } else if spell.canCastAsReaction {
            castingTimeString = "1 reaction, which you take \(spell.reactionResponse!)"
        } else if let castingTime = spell.castingTime {
            if castingTime > 60 {
                castingTimeString = "\(castingTime / 60) hours"
            } else if castingTime == 60 {
                castingTimeString = "\(castingTime / 60) hour"
            } else if castingTime > 1 {
                castingTimeString = "\(castingTime) minutes"
            } else {
                castingTimeString = "\(castingTime) minute"
            }
        }
        
        text.appendAttributedString(markupParser.parseText(castingTimeString, attributes: statsValueAttributes, features: .All, appendNewline: true))
        
        
        text.appendAttributedString(NSAttributedString(string: "Range: ", attributes: statsLabelAttributes))
        
        var rangeString = ""
        switch spell.range {
        case .Distance:
            if let distance = spell.rangeDistance {
                if distance > 5280 {
                    rangeString = "\(distance / 5280) miles"
                } else if distance == 5280 {
                    rangeString = "\(distance / 5280) mile"
                } else if distance > 1 {
                    rangeString = "\(distance) feet"
                } else {
                    rangeString = "\(distance) foot"
                }
            }
        case .CenteredOnSelf:
            rangeString = "Self"
            if let distance = spell.rangeDistance, shape = spell.rangeShape {
                if distance >= 5280 {
                    rangeString += " (\(distance / 5280)-mile"
                } else {
                    rangeString += " (\(distance)-foot"
                }
                
                switch shape {
                case .Radius:
                    rangeString += " radius)"
                case .Sphere:
                    rangeString += "-radius sphere)"
                case .Hemisphere:
                    rangeString += "-radius hemisphere)"
                case .Cube:
                    rangeString += " cube)"
                case .Cone:
                    rangeString += " cone)"
                case .Line:
                    rangeString += " line)"
                }
            }
        case .Touch:
            rangeString = "Touch"
        case .Sight:
            rangeString = "Sight"
        case .Special:
            rangeString = "Special"
        case .Unlimited:
            rangeString = "Unlimited"
        }
        
        text.appendAttributedString(NSAttributedString(string: "\(rangeString)\n", attributes: statsValueAttributes))
        
        
        text.appendAttributedString(NSAttributedString(string: "Components: ", attributes: statsLabelAttributes))
        
        var componentsStrings = [String]()
        if spell.hasVerbalComponent {
            componentsStrings.append("V")
        }
        if spell.hasSomaticComponent {
            componentsStrings.append("S")
        }
        if spell.hasMaterialComponent {
            componentsStrings.append("M (\(spell.materialComponent!))")
        }
        
        text.appendAttributedString(markupParser.parseText(componentsStrings.joinWithSeparator(", "), attributes: statsValueAttributes, features: .All, appendNewline: true))
    
        
        text.appendAttributedString(NSAttributedString(string: "Duration: ", attributes: statsLabelAttributes))
        
        var durationString = ""
        switch spell.duration {
        case .Instantaneous:
            durationString = "Instantaneous"
        case .MaxTime:
            if spell.requiresConcentration {
                durationString = "Concentration, up to "
            } else {
                durationString = "Up to "
            }
            fallthrough
        case .Time:
            if let durationTime = spell.durationTime {
                if durationTime > 1440 {
                    durationString += "\(durationTime / 1440) days"
                } else if durationTime == 1440 {
                    durationString += "\(durationTime / 1440) day"
                } else if durationTime > 60 {
                    durationString += "\(durationTime / 60) hours"
                } else if durationTime == 60 {
                    durationString += "\(durationTime / 60) hour"
                } else if durationTime > 1 {
                    durationString += "\(durationTime) minutes"
                } else {
                    durationString += "\(durationTime) minute"
                }
            }
        case .MaxRounds:
            if spell.requiresConcentration {
                durationString = "Concentration, up to "
            } else {
                durationString = "Up to "
            }
            fallthrough
        case .Rounds:
            if let durationTime = spell.durationTime {
                if durationTime > 1 {
                    durationString += "\(durationTime) rounds"
                } else {
                    durationString += "\(durationTime) round"
                }
            }
        case .UntilDispelled:
            durationString = "Until dispelled"
        case .UntilDispelledOrTriggered:
            durationString = "Until dispelled or triggered"
        case .Special:
            durationString = "Special"
        }
        
        text.appendAttributedString(NSAttributedString(string: "\(durationString)\n", attributes: statsValueAttributes))
        
        
        markupParser.parse(spell.text)
        text.appendAttributedString(markupParser.text)
        
        textView.attributedText = text
    }
    
    // MARK: Actions
    
    @IBAction func textViewTapped(sender: UITapGestureRecognizer) {
        let textView = sender.view! as! UITextView
        
        var location = sender.locationInView(textView)
        location.x -= textView.textContainerInset.left
        location.y -= textView.textContainerInset.top
        
        let index = textView.layoutManager.characterIndexForPoint(location, inTextContainer: textView.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        if let linkName = textView.attributedText.attribute(MarkupParser.linkAttributeName, atIndex: index, effectiveRange: nil) as? String {
            let fetchRequest = NSFetchRequest(entity: Model.Spell)
            fetchRequest.predicate = NSPredicate(format: "name LIKE[cd] %@", linkName)
            
            let spells = try! managedObjectContext.executeFetchRequest(fetchRequest) as! [Spell]
            if spells.count > 0 {
                let viewController = storyboard?.instantiateViewControllerWithIdentifier("SpellViewController") as! SpellViewController
                viewController.spell = spells.first
                navigationController?.pushViewController(viewController, animated: true)
            }
        }
    }
    

}
