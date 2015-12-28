//
//  MarkupParser.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/27/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

class MarkupParser {
    
    let linkAttributeName = "DungeonMaster.MarkupParser.LinkAttribute"
    
    var paragraphIndent: CGFloat = 20.0
    
    var paragraphSpacing: CGFloat = 10.0
    
    var tableWidth: CGFloat?
 
    var tableSpacing: CGFloat = 10.0
    
    private let whitespace: NSCharacterSet
    private let operators: NSCharacterSet
    
    private let bodyFontDescriptor: UIFontDescriptor
    private let emphasisedFontDescriptor: [UIFontDescriptor]
    private let tableFontDescriptor: UIFontDescriptor
    private let tableHeadingFontDescriptor: UIFontDescriptor
    
    private let textParagraphStyle: NSParagraphStyle
    private let bulletParagraphStyle: NSParagraphStyle
    
    init() {
        whitespace = NSCharacterSet.whitespaceCharacterSet()
        operators = NSCharacterSet(charactersInString: "*[\"")
        
        bodyFontDescriptor = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleBody)
        emphasisedFontDescriptor = [
            bodyFontDescriptor,
            bodyFontDescriptor.fontDescriptorWithSymbolicTraits(.TraitItalic),
            bodyFontDescriptor.fontDescriptorWithSymbolicTraits([ .TraitBold, .TraitItalic ]),
            UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleHeadline),
        ]
        tableFontDescriptor = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleCaption1)
        tableHeadingFontDescriptor = tableFontDescriptor.fontDescriptorWithSymbolicTraits(.TraitBold)
        
        let textParagraphStyle = NSMutableParagraphStyle()
        textParagraphStyle.alignment = .Natural
        textParagraphStyle.lineBreakMode = .ByWordWrapping
        self.textParagraphStyle = textParagraphStyle
        
        let bulletParagraphStyle = NSMutableParagraphStyle()
        bulletParagraphStyle.setParagraphStyle(textParagraphStyle)
        bulletParagraphStyle.headIndent = paragraphIndent
        bulletParagraphStyle.tabStops = [
            NSTextTab(textAlignment: .Left, location: paragraphIndent, options: [String: AnyObject]())
        ]
        self.bulletParagraphStyle = bulletParagraphStyle
    }

    func parse(lines: [String]) -> NSAttributedString {
        let text = NSMutableAttributedString()
        var firstBlock = true, lastWasParagraph = false
        var tableIndex: Int?, tableWidths = [CGFloat](), tableAlignments = [NSTextAlignment]()
        for line in lines {
            if line.containsString("|") {
                // Tables are rendered as a series of tabbed data, with the stop distances adjusted each line to match.
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineBreakMode = .ByClipping
                paragraphStyle.tabStops = []
                if lastWasParagraph {
                    paragraphStyle.paragraphSpacingBefore = paragraphSpacing
                }

                // First row has a bold heading font, resets the save table information, and has its alignment ignored.
                var ignoreAlignment = false
                let fontDescriptor: UIFontDescriptor
                if tableIndex == nil {
                    fontDescriptor = tableHeadingFontDescriptor
                    
                    tableIndex = text.length
                    tableWidths.removeAll()
                    tableAlignments.removeAll()
                    
                    ignoreAlignment = true
                } else {
                    fontDescriptor = tableFontDescriptor
                }
                let font = UIFont(descriptor: fontDescriptor, size: 0.0)

                // Split the line into columns, and recompose as a tab-separated string.
                var string = ""
                let columns = line.componentsSeparatedByString("|")
                for (index, column) in columns.enumerate() {
                    let column = column.stringByTrimmingCharactersInSet(whitespace)
                    
                    // Calculate the column width, and save if it's larger than the previous width.
                    var width = ceil((column as NSString).sizeWithAttributes([ NSFontAttributeName: font ]).width)
                    if index < tableWidths.count {
                        width = max(width, tableWidths[index])
                        tableWidths[index] = width
                    } else {
                        tableWidths.append(width)
                    }
                    
                    // Figure out the alignment, and revert to .Left if .Center wouldn't apply to any one row.
                    var alignment = ignoreAlignment ? .Center : alignmentForColumn(column)
                    if index < tableAlignments.count {
                        alignment = alignment == tableAlignments[index] ? alignment : .Left
                        tableAlignments[index] = alignment
                    } else {
                        tableAlignments.append(alignment)
                    }
                    
                    string += "\t\(column)"
                    
                }
                
                // Lay out the tab stops at the appropriate places for the columns.
                let expectedColumnWidths = tableWidths.reduce(0.0, combine: +)
                let availableColumnWidths = tableWidth != nil ? (tableWidth! - CGFloat(tableWidths.count + 1) * tableSpacing) : 0.0

                var location = tableSpacing
                for (alignment, width) in zip(tableAlignments, tableWidths) {
                    var expandedWidth = width
                    if expectedColumnWidths < availableColumnWidths {
                        expandedWidth = round(width / expectedColumnWidths * availableColumnWidths)
                    }
                    
                    var columnLocation = location
                    if alignment == .Center {
                        columnLocation += expandedWidth / 2.0
                    }
                    
                    paragraphStyle.tabStops.append(NSTextTab(textAlignment: alignment, location: columnLocation, options: [String:AnyObject]()))
                    location += expandedWidth + tableSpacing
                }

                // Reset the tab stops in the existing rendered portion of the table.
                var index = tableIndex!
                while index < text.length {
                    var range = NSRange()
                    if let priorStyle = text.attribute(NSParagraphStyleAttributeName, atIndex: index, effectiveRange: &range) as? NSParagraphStyle {
                        if priorStyle.paragraphSpacingBefore != 0.0 {
                            let newStyle = NSMutableParagraphStyle()
                            newStyle.setParagraphStyle(priorStyle)
                            newStyle.tabStops = paragraphStyle.tabStops

                            text.addAttribute(NSParagraphStyleAttributeName, value: newStyle, range: range)
                        } else {
                            text.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: range)
                        }
                    }
                    
                    index = range.location + range.length
                }
                
                // Append the new row.
                text.appendAttributedString(NSAttributedString(string: "\(string)\n", attributes: [
                    NSFontAttributeName: font,
                    NSParagraphStyleAttributeName: paragraphStyle
                    ]))

                lastWasParagraph = false
            } else if line.hasPrefix("•") {
                // Bulleted list are rendered as paragraph blocks with special intents.
                let line = line.substringFromIndex(line.startIndex.advancedBy(1))
                
                // If the bullet list follows a paragraph, preceed it with paragraph spacing.
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.setParagraphStyle(bulletParagraphStyle)
                if lastWasParagraph {
                    paragraphStyle.paragraphSpacingBefore = paragraphSpacing
                }
                
                // Append the bullet and a tab stop to move the following text to the right point.
                text.appendAttributedString(NSAttributedString(string: "•\t", attributes: [
                    NSFontAttributeName: UIFont(descriptor: bodyFontDescriptor, size: 0.0),
                    NSParagraphStyleAttributeName: paragraphStyle,
                    ]))
                text.appendAttributedString(parseText(line, paragraphStyle: paragraphStyle, appendNewline: true))
                
                lastWasParagraph = false
                tableIndex = nil
            } else {
                // Indent all except the first paragraphs in a block.
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.setParagraphStyle(textParagraphStyle)
                if lastWasParagraph {
                    paragraphStyle.firstLineHeadIndent = paragraphIndent
                } else if !firstBlock {
                    paragraphStyle.paragraphSpacingBefore = paragraphSpacing
                }
                
                text.appendAttributedString(parseText(line, paragraphStyle: paragraphStyle, appendNewline: true))

                lastWasParagraph = true
                tableIndex = nil
            }
            
            firstBlock = false
        }

        return text
    }

    private func parseText(line: String, paragraphStyle: NSParagraphStyle, appendNewline: Bool) -> NSAttributedString {
        let line = line.stringByTrimmingCharactersInSet(whitespace)
        var range = line.startIndex..<line.endIndex
        
        let text = NSMutableAttributedString()
        loop: while true {
            if let operatorRange = line.rangeOfCharacterFromSet(operators, options: [], range: range) {
                // Might be an initial piece of text before the first operator in the line.
                if range.startIndex != operatorRange.startIndex {
                    text.appendAttributedString(NSAttributedString(string: line.substringWithRange(range.startIndex..<operatorRange.startIndex), attributes: [
                        NSFontAttributeName: UIFont(descriptor: bodyFontDescriptor, size: 0.0),
                        NSParagraphStyleAttributeName: paragraphStyle,
                        ]))
                }
                
                switch line[operatorRange.startIndex] {
                case "*":
                    // Increased numbers of * indicate increased emphasis.
                    var index = operatorRange.startIndex
                    while index != range.endIndex && line[index] == "*" {
                        index = index.advancedBy(1)
                    }
                    
                    // Locate the end of the emphasised range.
                    if let endOperatorRange = line.rangeOfString("*", options: [], range: index..<range.endIndex, locale: nil) {
                        // Find the end of the end operator.
                        var endIndex = endOperatorRange.startIndex
                        while endIndex != range.endIndex && line[endIndex] == "*" {
                            endIndex = endIndex.advancedBy(1)
                        }

                        // If the start operator is too long, treat it as initial *s followed by the right operator.
                        var emphasisness = operatorRange.startIndex.distanceTo(index)
                        if emphasisness > emphasisedFontDescriptor.count || emphasisness > endOperatorRange.startIndex.distanceTo(endIndex) {
                            emphasisness = min(emphasisedFontDescriptor.count, endOperatorRange.startIndex.distanceTo(endIndex))
                            
                            let overlength = operatorRange.startIndex.distanceTo(index) - emphasisness
                            let string = line.substringWithRange(operatorRange.startIndex..<operatorRange.startIndex.advancedBy(overlength))
                            text.appendAttributedString(NSAttributedString(string: string, attributes: [
                                NSFontAttributeName: UIFont(descriptor: bodyFontDescriptor, size: 0.0),
                                NSParagraphStyleAttributeName: paragraphStyle,
                                ]))
                        }
                        
                        // Emphasised text. We special-case the situation where the entire line is emphasised, and include the newline in the emphasis.
                        var string = line.substringWithRange(index..<endOperatorRange.startIndex)
                        if appendNewline && operatorRange.startIndex == line.startIndex && endIndex == line.endIndex {
                            string += "\n"
                        }
                        
                        text.appendAttributedString(NSAttributedString(string: string, attributes: [
                            NSFontAttributeName: UIFont(descriptor: emphasisedFontDescriptor[emphasisness], size: 0.0),
                            NSParagraphStyleAttributeName: paragraphStyle,
                            ]))
                        
                        // If the end operator is too long, treat it as the right operator followed by *s.
                        if endOperatorRange.startIndex.distanceTo(endIndex) > emphasisness {
                            let overlength = endOperatorRange.startIndex.distanceTo(endIndex) - emphasisness
                            let string = line.substringWithRange(endOperatorRange.startIndex.advancedBy(overlength)..<endIndex)
                            text.appendAttributedString(NSAttributedString(string: string, attributes: [
                                NSFontAttributeName: UIFont(descriptor: bodyFontDescriptor, size: 0.0),
                                NSParagraphStyleAttributeName: paragraphStyle,
                                ]))
                        }

                        range = endIndex..<range.endIndex
                        
                        // Don't double-add a newline.
                        if string.hasSuffix("\n") {
                            break loop
                        }
                        
                    } else {
                        // Didn't find the end emphasis; add the entire emphasis operator range to the output and continue from after it.
                        text.appendAttributedString(NSAttributedString(string: line.substringWithRange(operatorRange.startIndex..<index), attributes: [
                            NSFontAttributeName: UIFont(descriptor: bodyFontDescriptor, size: 0.0),
                            NSParagraphStyleAttributeName: paragraphStyle,
                            ]))
                        
                        range = index..<range.endIndex
                    }
                case "[":
                    // Locate the end of the link.
                    if let endOperatorRange = line.rangeOfString("]", options: [], range: operatorRange.endIndex..<range.endIndex, locale: nil) {
                        let linkName = line.substringWithRange(operatorRange.endIndex..<endOperatorRange.startIndex)
                        var linkText = linkName
                        
                        range = endOperatorRange.endIndex..<range.endIndex

                        // The link can optionally be immediately followed by an alternate text to add.
                        if line.substringFromIndex(endOperatorRange.endIndex).hasPrefix("(") {
                            if let endAlternateRange = line.rangeOfString(")", options: [], range:endOperatorRange.endIndex..<range.endIndex, locale: nil) {
                                linkText = line.substringWithRange(endOperatorRange.endIndex.advancedBy(1)..<endAlternateRange.startIndex)
                                range = endAlternateRange.endIndex..<range.endIndex
                            }
                            
                        }
                        
                        // Add the text in the link to the output.
                        text.appendAttributedString(NSAttributedString(string: linkText, attributes: [
                            NSFontAttributeName: UIFont(descriptor: bodyFontDescriptor, size: 0.0),
                            NSParagraphStyleAttributeName: paragraphStyle,
                            NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue,
                            linkAttributeName: linkName
                            ]))
                        
                    } else {
                        // Didn't find an end to the link; just add the start operator to the output.
                        text.appendAttributedString(NSAttributedString(string: line.substringWithRange(operatorRange), attributes: [
                            NSFontAttributeName: UIFont(descriptor: bodyFontDescriptor, size: 0.0),
                            NSParagraphStyleAttributeName: paragraphStyle,
                            ]))
                        
                        range = operatorRange.endIndex..<range.endIndex
                    }
                case "\"":
                    // Locate the end of the quoted string.
                    if let endOperatorRange = line.rangeOfString("\"", options: [], range: operatorRange.endIndex..<range.endIndex, locale: nil) {
                        // Replace the quotes with smart quotes.
                        let string = "“\(line.substringWithRange(operatorRange.endIndex..<endOperatorRange.startIndex))”"
                        text.appendAttributedString(parseText(string, paragraphStyle: paragraphStyle, appendNewline: false))

                        range = endOperatorRange.endIndex..<range.endIndex
                    } else {
                        // Didn't find an end to the quote; just add the start quote to the output as a non-smart quote.
                        text.appendAttributedString(NSAttributedString(string: line.substringWithRange(operatorRange), attributes: [
                            NSFontAttributeName: UIFont(descriptor: bodyFontDescriptor, size: 0.0),
                            NSParagraphStyleAttributeName: paragraphStyle,
                            ]))
                        
                        range = operatorRange.endIndex..<range.endIndex
                    }
                default:
                    abort()
                }
                
            } else {
                // Remaining part of line after last operator, or entire line when there is no operator.
                var trailing = line.substringWithRange(range)
                if appendNewline {
                   trailing += "\n"
                }
                
                if trailing != "" {
                    text.appendAttributedString(NSAttributedString(string: trailing, attributes: [
                        NSFontAttributeName: UIFont(descriptor: bodyFontDescriptor, size: 0.0),
                        NSParagraphStyleAttributeName: paragraphStyle,
                        ]))
                }
                
                break loop
            }
        }
        
        return text
    }
    
    func alignmentForColumn(column: String) -> NSTextAlignment {
        for character in column.characters {
            switch character {
            case "0"..."9", "+", "-", "–", "—":
                continue
            default:
                return .Left
            }
        }
        
        return .Center
    }
    
}
