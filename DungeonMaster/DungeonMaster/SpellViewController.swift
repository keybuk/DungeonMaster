//
//  SpellViewController.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/29/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import CoreData
import UIKit

class SpellViewController : UIViewController {

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
        guard let spell = spell else { return }

        let markupParser = MarkupParser()
        markupParser.tableWidth = textView.bounds.size.width - textView.textContainerInset.left - textView.textContainerInset.right
        markupParser.paragraphSpacingBefore = markupParser.paragraphSpacing
        markupParser.linkColor = textView.tintColor
        
    
        let nameFont = UIFontDescriptor.preferredFontDescriptor(withTextStyle: UIFontTextStyle.title1)
        
        let subheadlineFont = UIFontDescriptor.preferredFontDescriptor(withTextStyle: UIFontTextStyle.subheadline)
        let subheadlineItalicFont = subheadlineFont.withSymbolicTraits(.traitItalic)
        
        let bodyFont = UIFontDescriptor.preferredFontDescriptor(withTextStyle: UIFontTextStyle.body)
        let bodyBoldFont = bodyFont.withSymbolicTraits(.traitBold)
        
        let nameAttributes = [
            NSFontAttributeName: UIFont(descriptor: nameFont, size: 0.0),
        ]
        
        let levelSchoolParagraphStyle = NSMutableParagraphStyle()
        levelSchoolParagraphStyle.paragraphSpacing = 12.0
        
        let levelSchoolAttributes = [
            NSFontAttributeName: UIFont(descriptor: subheadlineItalicFont!, size: 0.0),
            NSParagraphStyleAttributeName: levelSchoolParagraphStyle
        ]
        
        let statsParagraphStyle = NSMutableParagraphStyle()
        statsParagraphStyle.headIndent = 12.0
        
        let statsLabelAttributes = [
            NSFontAttributeName: UIFont(descriptor: bodyBoldFont!, size: 0.0),
            NSParagraphStyleAttributeName: statsParagraphStyle,
        ]
        
        let statsValueAttributes = [
            NSFontAttributeName: UIFont(descriptor: bodyFont, size: 0.0),
            NSParagraphStyleAttributeName: statsParagraphStyle,
        ]
        
        
        let text = NSMutableAttributedString()
        
        text.append(NSAttributedString(string: "\(spell.name)\n", attributes: nameAttributes))
        
        
        var levelSchoolString: String
        switch spell.level {
        case 0:
            levelSchoolString = "\(spell.school.stringValue) cantrip"
        case 1:
            levelSchoolString = "1st-level \(spell.school.stringValue.lowercased())"
        case 2:
            levelSchoolString = "2nd-level \(spell.school.stringValue.lowercased())"
        case 3:
            levelSchoolString = "3rd-level \(spell.school.stringValue.lowercased())"
        default:
            levelSchoolString = "\(spell.level)th-level \(spell.school.stringValue.lowercased())"
        }
        
        if spell.canCastAsRitual {
            levelSchoolString += " (ritual)"
        }
        
        text.append(NSAttributedString(string: "\(levelSchoolString)\n", attributes: levelSchoolAttributes))
        
        
        text.append(NSAttributedString(string: "Casting Time: ", attributes: statsLabelAttributes))
        
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
        
        text.append(markupParser.parseText(castingTimeString, attributes: statsValueAttributes, features: .All, appendNewline: true))
        
        
        text.append(NSAttributedString(string: "Range: ", attributes: statsLabelAttributes))
        
        var rangeString = ""
        switch spell.range {
        case .distance:
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
        case .centeredOnSelf:
            rangeString = "Self"
            if let distance = spell.rangeDistance, let shape = spell.rangeShape {
                if distance >= 5280 {
                    rangeString += " (\(distance / 5280)-mile"
                } else {
                    rangeString += " (\(distance)-foot"
                }
                
                switch shape {
                case .radius:
                    rangeString += " radius)"
                case .sphere:
                    rangeString += "-radius sphere)"
                case .hemisphere:
                    rangeString += "-radius hemisphere)"
                case .cube:
                    rangeString += " cube)"
                case .cone:
                    rangeString += " cone)"
                case .line:
                    rangeString += " line)"
                }
            }
        case .touch:
            rangeString = "Touch"
        case .sight:
            rangeString = "Sight"
        case .special:
            rangeString = "Special"
        case .unlimited:
            rangeString = "Unlimited"
        }
        
        text.append(NSAttributedString(string: "\(rangeString)\n", attributes: statsValueAttributes))
        
        
        text.append(NSAttributedString(string: "Components: ", attributes: statsLabelAttributes))
        
        var componentsStrings: [String] = []
        if spell.hasVerbalComponent {
            componentsStrings.append("V")
        }
        if spell.hasSomaticComponent {
            componentsStrings.append("S")
        }
        if spell.hasMaterialComponent {
            componentsStrings.append("M (\(spell.materialComponent!))")
        }
        
        text.append(markupParser.parseText(componentsStrings.joined(separator: ", "), attributes: statsValueAttributes, features: .All, appendNewline: true))
    
        
        text.append(NSAttributedString(string: "Duration: ", attributes: statsLabelAttributes))
        
        var durationString = ""
        switch spell.duration {
        case .instantaneous:
            durationString = "Instantaneous"
        case .maxTime:
            if spell.requiresConcentration {
                durationString = "Concentration, up to "
            } else {
                durationString = "Up to "
            }
            fallthrough
        case .time:
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
        case .maxRounds:
            if spell.requiresConcentration {
                durationString = "Concentration, up to "
            } else {
                durationString = "Up to "
            }
            fallthrough
        case .rounds:
            if let durationTime = spell.durationTime {
                if durationTime > 1 {
                    durationString += "\(durationTime) rounds"
                } else {
                    durationString += "\(durationTime) round"
                }
            }
        case .untilDispelled:
            durationString = "Until dispelled"
        case .untilDispelledOrTriggered:
            durationString = "Until dispelled or triggered"
        case .special:
            durationString = "Special"
        }
        
        text.append(NSAttributedString(string: "\(durationString)\n", attributes: statsValueAttributes))
        
        
        markupParser.parse(spell.text)
        text.append(markupParser.text)
        
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
            let fetchRequest = NSFetchRequest<Spell>(entity: Model.Spell)
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
