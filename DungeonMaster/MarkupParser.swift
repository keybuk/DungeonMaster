//
//  MarkupParser.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 12/27/15.
//  Copyright © 2015 Scott James Remnant. All rights reserved.
//

import UIKit

/// MarkupParserFeature represents the markup features that can be parsed by calls to `parseText`.
struct MarkupParserFeatures: OptionSetType {
    let rawValue: UInt
    static let None = MarkupParserFeatures(rawValue: 0)
    static let Emphasis = MarkupParserFeatures(rawValue: 1)
    static let Links = MarkupParserFeatures(rawValue: 1 << 1)
    static let Quotes = MarkupParserFeatures(rawValue: 1 << 2)
    static let Apostrophes = MarkupParserFeatures(rawValue: 1 << 3)
    
    static let All: MarkupParserFeatures = [ .Emphasis, .Links, .Quotes, .Apostrophes ]
}

/// MarkupParser parses the markup format used by rules, and monster and spell lists into an `NSAttributedString` for display.
///
/// The markup format is extremely lightweight, and is similar to Markdown in someways.
///
/// The following inline markup is recognized in paragraphs and bulleted lists:
/// - \*text\* is output emphasised in *italics*.
/// - \*\*text\*\* is output emphasised in **bold**.
/// - \*\*\*text\*\*\* is output in a ***bold and italics***.
/// - [text] is recognized as a link to another monster or spell named "text".
/// - [text](alternate text) is also recognized as a link to "text", but displayed as "alternate text".
/// - "text" (double quotes) is rendered with smart quotes as “text”.
/// - single quotes in words like "can't" are also rendered with smart quotes as "can’t".
///
/// Headings can be created by beginning the line with "# ", e.g.:
///
///     # This is a heading
///
/// Paragraphs with an alternate indentation style can be created by beginning the lines with "} ", e.g.:
///
///     } **Title.** All but the first line will be indented.
///     } **Title.** Next paragraph has no first-line indent.
///
/// Bulleted lists can be created by beginning the line with "• ", e.g.:
///
///     • Bullet item.
///     • Second bullet item.
///
/// Tables can be constructed using "|" as the column separator, e.g.:
///
///     d100 | Result
///     00–49 | Nothing happens
///     50–99 | Something happens
///
/// Columns with numeric data are center-aligned, while other data is left-aligned.
class MarkupParser {
    
    /// Links in the text have the following attribute set to the link name.
    ///
    /// You can obtain the target of links, and their locations, using `markupParser.text.attribute(markupParser.linkAttributeName, atIndex: ..., effectiveRange: ...)`
    let linkAttributeName = "DungeonMaster.MarkupParser.LinkAttribute"
    
    /// Paragraph indent used on following paragraphs, and in bulleted lists.
    var paragraphIndent: CGFloat = 20.0
    
    /// Spacing between paragraphs, bulleted lists, and tables.
    var paragraphSpacing: CGFloat = 10.0
    
    /// Spacing before the first item generated by the parser.
    var paragraphSpacingBefore: CGFloat = 0.0
    
    /// Width to render tables.
    ///
    /// Tables are ordinarily set to be rendered only as wide as is necessary for the data within. By setting this value, non-numeric table columns will be proportionally stretched to fill the entire width.
    var tableWidth: CGFloat?
 
    /// Spacing between table columns.
    var tableSpacing: CGFloat = 10.0
    
    /// Color to apply to links.
    var linkColor: UIColor?
    
    /// Parsed text.
    var text: NSAttributedString {
        return mutableText
    }

    private let whitespace: NSCharacterSet
    
    private let bodyFontDescriptor: UIFontDescriptor
    private let tableFontDescriptor: UIFontDescriptor
    private let tableHeadingFontDescriptor: UIFontDescriptor
    private let headingFontDescriptor: UIFontDescriptor

    private let emphasisedTraits: [UIFontDescriptorSymbolicTraits]
    
    private var lastBlock: LastBlock
    private var mutableText: NSMutableAttributedString

    init() {
        whitespace = NSCharacterSet.whitespaceCharacterSet()
        
        bodyFontDescriptor = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleBody)
        tableFontDescriptor = bodyFontDescriptor.fontDescriptorWithSize(floor(bodyFontDescriptor.pointSize * 0.9))
        tableHeadingFontDescriptor = tableFontDescriptor.fontDescriptorWithSymbolicTraits(.TraitBold)
        headingFontDescriptor = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleHeadline)
        
        emphasisedTraits = [
            [],
            .TraitItalic,
            .TraitBold,
            [ .TraitBold, .TraitItalic ]
        ]
        
        lastBlock = LastBlock.None
        mutableText = NSMutableAttributedString()
    }
    
    enum LastBlock {
        case None
        case Table(Int, Int, [CGFloat], [NSTextAlignment])
        case FinishedTable
        case Bullet
        case Heading
        case IndentParagraph
        case Paragraph
        case LineBreak
    }
    
    /// Parse lines of text.
    ///
    /// Each line is treated as a complete paragraph, bulleted list item, or table row, and a newline automatically appended to the attributed stirng.
    ///
    /// Multiple calls to `parse` extend the attributed string.
    func parse(lines: [String]) {
        for line in lines {
            if line.containsString("|") {
                parseTableLine(line)
            } else {
                layoutTableIfNeeded()
                if line.hasPrefix("•") {
                    parseBulletLine(line)
                } else if line.hasPrefix("#") {
                    parseHeadingLine(line)
                } else if line.hasPrefix("}") {
                    parseIndentLine(line)
                } else if line != "" {
                    parseTextLine(line)
                } else {
                    lastBlock = .LineBreak
                }
            }
        }
        
        layoutTableIfNeeded()
    }
    
    /// Parse a block of text.
    ///
    /// The line begins a new complete paragraph, bulleted list item, or table row. Embedded newlines in the text result in the next line also being considered as a new complete paragraph, bulleted list item, or table row. A newline is automatically appended to the attributed string.
    ///
    /// Multiple calls to `parse` extend the attributed string.
    func parse(line: String) {
        parse(line.componentsSeparatedByString("\n"))
    }
    
    /// Reset the parser.
    ///
    /// After this call, the attribtued string is empty, and the parser treats a new call to `parse` as beginning new markup.
    func reset() {
        lastBlock = LastBlock.None
        mutableText = NSMutableAttributedString()
    }
    
    private func parseTableLine(line: String) {
        // Tables are rendered as a series of tabbed data.
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .ByClipping
        paragraphStyle.tabStops = []
        paragraphStyle.lineHeightMultiple = 1/0.9 * 1.2
        paragraphStyle.lineSpacing = tableFontDescriptor.pointSize * 0.5
        
        switch lastBlock {
        case .Table(_, _, _, _), .Heading:
            break
        case .None:
            paragraphStyle.paragraphSpacingBefore = paragraphSpacingBefore
        default:
            paragraphStyle.paragraphSpacingBefore = paragraphSpacing
        }
        
        // Build up the table row-per-row.
        let font: UIFont
        var tableIndex = mutableText.length
        var tableRows = 0
        var tableWidths = [CGFloat]()
        var tableAlignments = [NSTextAlignment]()
        
        if case .Table(let index, let rows, let widths, let alignments) = lastBlock {
            tableIndex = index
            tableRows = rows
            tableWidths = widths
            tableAlignments = alignments

            // Body rows use the standard font.
            font = UIFont(descriptor: tableFontDescriptor, size: 0.0)
        } else {
            // First row always has its font set to the heading font.
            font = UIFont(descriptor: tableHeadingFontDescriptor, size: 0.0)
        }
        
        // Get sexy with the coloring.
        var attributes = [
            NSFontAttributeName: font,
            NSParagraphStyleAttributeName: paragraphStyle,
        ]
        if tableRows % 2 == 1 {
            attributes[NSBackgroundColorAttributeName] = UIColor(white: 0.0, alpha: 0.05)
        }

        // Split the line into columns, and calculate the render widths and alignment.
        var columns = [NSAttributedString]()
        for (index, column) in line.componentsSeparatedByString("|").enumerate() {
            let column = parseText(column.stringByTrimmingCharactersInSet(whitespace), attributes: attributes, features: .All, appendNewline: false)
            
            // Calculate the column width, and save if it's larger than the previous width.
            var width = ceil(column.size().width)
            if index < tableWidths.count {
                width = max(width, tableWidths[index])
                tableWidths[index] = width
            } else {
                tableWidths.append(width)
            }
            
            // Figure out the alignment, and revert to .Left if .Center wouldn't apply to any one row.
            var alignment = tableRows == 0 ? .Center : alignmentForColumn(column.string)
            if index < tableAlignments.count {
                alignment = alignment == tableAlignments[index] ? alignment : .Left
                tableAlignments[index] = alignment
            } else {
                tableAlignments.append(alignment)
            }
            
            columns.append(column)
        }
        
        // Append the new row.
        for column in columns {
            mutableText.appendAttributedString(NSAttributedString(string: "\t", attributes: attributes))
            mutableText.appendAttributedString(column)
        }
        mutableText.appendAttributedString(NSAttributedString(string: "\n", attributes: attributes))

        lastBlock = .Table(tableIndex, tableRows + 1, tableWidths, tableAlignments)
    }
    
    private func alignmentForColumn(column: String) -> NSTextAlignment {
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

    private func layoutTableIfNeeded() {
        guard case .Table(let tableIndex, _, let tableWidths, let tableAlignments) = lastBlock else { return }
        
        // Calculate the combined column widths, and find the widest column.
        var flexibleColumnWidths: CGFloat = 0.0, fixedColumnWidths: CGFloat = 0.0
        var widestColumnWidth: CGFloat?, widestColumnIndex: Int?
        for (index, (alignment, width)) in zip(tableAlignments, tableWidths).enumerate() {
            if alignment == .Left {
                flexibleColumnWidths += width
                if width > (widestColumnWidth ?? 0.0) {
                    widestColumnWidth = width
                    widestColumnIndex = index
                }
            } else {
                fixedColumnWidths += width
            }
        }
        
        // If the parser has a fixed table width set, calculate how much space is available for the flexible columns. This dictates either how much we can expand the columns (when undersized), or how much we would need to shrink the widest column (when oversized).
        var availableColumnWidths: CGFloat?
        if let tableWidth = tableWidth {
            availableColumnWidths = (tableWidth - CGFloat(tableWidths.count + 1) * tableSpacing - fixedColumnWidths)
        }

        // Lay out the tab stops at the appropriate places for the columns.
        var location = tableSpacing
        var tabStops = [NSTextTab]()
        for (index, (alignment, width)) in zip(tableAlignments, tableWidths).enumerate() {
            var width = width, columnLocation = location
            if alignment == .Center {
                columnLocation += width / 2.0
            } else if let availableColumnWidths = availableColumnWidths {
                if flexibleColumnWidths < availableColumnWidths {
                    // Table needs expanding, scale the column up proportionally.
                    width = round(width / flexibleColumnWidths * availableColumnWidths)
                } else if let widestColumnIndex = widestColumnIndex where flexibleColumnWidths > availableColumnWidths && (flexibleColumnWidths - width) <= availableColumnWidths && index == widestColumnIndex {
                    // Table needs collapsing, this is the widest column, and removing it would get us under again.
                    width = availableColumnWidths - (flexibleColumnWidths - width)
                    
                    collapseTableColumn(index, to: width)
                }
            }
            
            tabStops.append(NSTextTab(textAlignment: alignment, location: columnLocation, options: [String:AnyObject]()))
            location += width + tableSpacing
        }
        
        // Apply the tab stops to the table by updating the previous paragraph styles
        var index = tableIndex
        while index < mutableText.length {
            var range = NSRange()
            if let priorStyle = mutableText.attribute(NSParagraphStyleAttributeName, atIndex: index, effectiveRange: &range) as? NSParagraphStyle {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.setParagraphStyle(priorStyle)
                paragraphStyle.tabStops = tabStops
                
                mutableText.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: range)
            }
            
            index = range.location + range.length
        }
        
        // Since the table has been laid out, we can't extend it any further. Make sure that the next parse() call starts a new table if it has one.
        lastBlock = .FinishedTable
    }
    
    private func collapseTableColumn(columnIndex: Int, to width: CGFloat) {
        guard case .Table(let tableIndex, _, _, _) = lastBlock else { return }
        let delimiterCharacterSet = NSCharacterSet(charactersInString: "\t\n")
        
        var column: Int?
        var fragment: String?
        var fragments = [String]()
        var fragmentWidth: CGFloat?
        var fragmentWidths = [CGFloat]()
        var savedTrailing: String?

        var index = mutableText.string.startIndex.advancedBy(tableIndex)
        while index != mutableText.string.endIndex {
            guard let delimiterRange = mutableText.string.rangeOfCharacterFromSet(delimiterCharacterSet, options: [], range: index..<mutableText.string.endIndex) else { break }
            let delimiter = mutableText.string[delimiterRange.startIndex]
            let delimiterLength = delimiterRange.startIndex.distanceTo(delimiterRange.endIndex)

            if let column = column where column == columnIndex {
                // Generate string fragments to fit within width.
                let font = mutableText.attribute(NSFontAttributeName, atIndex: mutableText.string.startIndex.distanceTo(index), effectiveRange: nil)!
                mutableText.string.enumerateSubstringsInRange(index..<delimiterRange.startIndex, options: .ByWords) { (substring, substringRange, enclosingRange, inout stop: Bool) in
                    let newFragment = (fragment ?? "") + (savedTrailing ?? "") + substring!
                    let newWidth = ceil((newFragment as NSString).sizeWithAttributes([ NSFontAttributeName: font ]).width)
                    
                    if newWidth > width {
                        if let fragment = fragment, fragmentWidth = fragmentWidth {
                            fragments.append(fragment)
                            fragmentWidths.append(fragmentWidth)
                        }
                        fragment = substring!
                        fragmentWidth = ceil((substring! as NSString).sizeWithAttributes([ NSFontAttributeName: font ]).width)
                    } else {
                        fragment = newFragment
                        fragmentWidth = newWidth
                    }
                    
                    savedTrailing = self.mutableText.string.substringWithRange(substringRange.endIndex..<enclosingRange.endIndex)
                }

                if let fragment = fragment, fragmentWidth = fragmentWidth {
                    fragments.append(fragment)
                    fragmentWidths.append(fragmentWidth)
                }
                
                // Replace the text in the column with the first fragment.
                let string = fragments.removeFirst()
                let range = NSRange(location: mutableText.string.startIndex.distanceTo(index), length: index.distanceTo(delimiterRange.startIndex))
                mutableText.replaceCharactersInRange(range, withString: string)
                
                // Since we've mutated the string, we have to recalculate the index; fortunately we know how many characters we inserted and the length of the delimiter already.
                index = mutableText.string.startIndex.advancedBy(range.location + string.characters.count + delimiterLength)
            } else {
                index = delimiterRange.endIndex
            }

            if delimiter == "\n" {
                if fragments.count > 0 {
                    // Replace the delimiter with itself, followed by a line for each of the fragments prefixed with the right numbers of indents.
                    let prefix = [String](count: columnIndex + 1, repeatedValue: "\t").joinWithSeparator("")
                    let string = fragments.map({ "\(prefix)\($0)\n" }).reduce("\(delimiter)", combine: +)
                    let range = NSRange(location: mutableText.string.startIndex.distanceTo(index) - delimiterLength, length: delimiterLength)
                    mutableText.replaceCharactersInRange(range, withString: string)
                    
                    // Since we've mutated the string, the index has to be recalculated once more; again this is easy because we know the range where we inserted characters, what we replaced, and that included the delimiter too this time.
                    index = mutableText.string.startIndex.advancedBy(range.location + string.characters.count)
                }
                
                column = nil
                fragment = nil
                fragments.removeAll()
                fragmentWidth = nil
                fragmentWidths.removeAll()
                savedTrailing = nil
            } else {
                column = column != nil ? column! + 1 : 0
            }
        }
    }
    
    private func parseBulletLine(line: String) {
        // Bulleted list are rendered as paragraph blocks with special intents.
        let line = line.substringFromIndex(line.startIndex.advancedBy(1))
        
        // If the bullet list follows a paragraph, preceed it with paragraph spacing.
        let paragraphStyle = NSMutableParagraphStyle()
        switch lastBlock {
        case .Bullet, .Heading:
            break
        case .None:
            paragraphStyle.paragraphSpacingBefore = paragraphSpacingBefore
        default:
            paragraphStyle.paragraphSpacingBefore = paragraphSpacing
        }
        
        paragraphStyle.headIndent = paragraphIndent
        paragraphStyle.tabStops = [
            NSTextTab(textAlignment: .Left, location: paragraphIndent, options: [String: AnyObject]())
        ]

        let attributes = [
            NSFontAttributeName: UIFont(descriptor: bodyFontDescriptor, size: 0.0),
            NSParagraphStyleAttributeName: paragraphStyle
        ]

        // Append the bullet and a tab stop to move the following text to the right point.
        mutableText.appendAttributedString(NSAttributedString(string: "•\t", attributes: attributes))
        mutableText.appendAttributedString(parseText(line, attributes: attributes, features: .All, appendNewline: true))
        
        lastBlock = .Bullet
    }
    
    private func parseHeadingLine(line: String) {
        // Improved font.
        let line = line.substringFromIndex(line.startIndex.advancedBy(1)).stringByTrimmingCharactersInSet(whitespace)

        let paragraphStyle = NSMutableParagraphStyle()
        switch lastBlock {
        case .None:
            paragraphStyle.paragraphSpacingBefore = paragraphSpacingBefore
        default:
            paragraphStyle.paragraphSpacingBefore = paragraphSpacing
        }

        let attributes = [
            NSFontAttributeName: UIFont(descriptor: headingFontDescriptor, size: 0.0),
            NSParagraphStyleAttributeName: paragraphStyle,
        ]

        mutableText.appendAttributedString(parseText(line, attributes: attributes, features: .All, appendNewline: true))
        
        lastBlock = .Heading
    }
    
    private func parseIndentLine(line: String) {
        // This differs from a standard paragraph only in style.
        let line = line.substringFromIndex(line.startIndex.advancedBy(1)).stringByTrimmingCharactersInSet(whitespace)

        let paragraphStyle = NSMutableParagraphStyle()
        switch lastBlock {
        case .IndentParagraph, .Heading:
            break
        case .None:
            paragraphStyle.paragraphSpacingBefore = paragraphSpacingBefore
        default:
            paragraphStyle.paragraphSpacingBefore = paragraphSpacing
        }
        
        paragraphStyle.headIndent = paragraphIndent
        
        let attributes = [
            NSFontAttributeName: UIFont(descriptor: bodyFontDescriptor, size: 0.0),
            NSParagraphStyleAttributeName: paragraphStyle
        ]
        
        mutableText.appendAttributedString(parseText(line, attributes: attributes, features: .All, appendNewline: true))
        
        lastBlock = .IndentParagraph
    }
    
    private func parseTextLine(line: String) {
        // Indent all except the first paragraphs in a block.
        let paragraphStyle = NSMutableParagraphStyle()
        switch lastBlock {
        case .Heading:
            break
        case .Paragraph:
            paragraphStyle.firstLineHeadIndent = paragraphIndent
        case .None:
            paragraphStyle.paragraphSpacingBefore = paragraphSpacingBefore
        default:
            paragraphStyle.paragraphSpacingBefore = paragraphSpacing
        }
        
        let attributes = [
            NSFontAttributeName: UIFont(descriptor: bodyFontDescriptor, size: 0.0),
            NSParagraphStyleAttributeName: paragraphStyle
        ]
        
        mutableText.appendAttributedString(parseText(line, attributes: attributes, features: .All, appendNewline: true))
        
        lastBlock = .Paragraph
    }

    /// Parse a section of text and return as an attributed string.
    ///
    /// Unlike the `parse` function, this only handles inline attributes specified in `features`, and does not modify the `text` member of the parser.
    ///
    /// - parameter line: the text to parse.
    /// - parameter attributes: attributes to apply to the resulting `NSAttributedString`.
    /// - parameter features: parser features to enable in the string.
    /// - parameter appendNewline: whether a newline should be appended to the returned string.
    ///
    /// - returns: NSAttributedString resulting from parsing `line`.
    func parseText(line: String, attributes: [String: AnyObject], features: MarkupParserFeatures, appendNewline: Bool) -> NSAttributedString {
        let line = line.stringByTrimmingCharactersInSet(whitespace)
        var range = line.startIndex..<line.endIndex

        var operatorString = ""
        if features.contains(.Emphasis) {
            operatorString += "*"
        }
        if features.contains(.Links) {
            operatorString += "["
        }
        if features.contains(.Quotes) {
            operatorString += "\""
        }
        if features.contains(.Apostrophes) {
            operatorString += "'"
        }
        let operators = NSCharacterSet(charactersInString: operatorString)

        
        let text = NSMutableAttributedString()
        loop: while true {
            if let operatorRange = line.rangeOfCharacterFromSet(operators, options: [], range: range) {
                // Might be an initial piece of text before the first operator in the line.
                if range.startIndex != operatorRange.startIndex {
                    let string = line.substringWithRange(range.startIndex..<operatorRange.startIndex)
                    text.appendAttributedString(NSAttributedString(string: string, attributes: attributes))
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
                        if emphasisness > emphasisedTraits.count || emphasisness > endOperatorRange.startIndex.distanceTo(endIndex) {
                            emphasisness = min(emphasisedTraits.count, endOperatorRange.startIndex.distanceTo(endIndex))
                            
                            let overlength = operatorRange.startIndex.distanceTo(index) - emphasisness
                            let string = line.substringWithRange(operatorRange.startIndex..<operatorRange.startIndex.advancedBy(overlength))
                            text.appendAttributedString(NSAttributedString(string: string, attributes: attributes))
                        }
                        
                        // Emphasised text. We special-case the situation where the entire line is emphasised, and include the newline in the emphasis.
                        var string = line.substringWithRange(index..<endOperatorRange.startIndex)
                        if appendNewline && operatorRange.startIndex == line.startIndex && endIndex == line.endIndex {
                            string += "\n"
                        }
                        
                        let fontDescriptor = (attributes[NSFontAttributeName] as? UIFont)?.fontDescriptor() ?? bodyFontDescriptor
                        let emphasisedFontDescriptor = fontDescriptor.fontDescriptorWithSymbolicTraits(emphasisedTraits[emphasisness])
                        
                        var emphasisAttributes = attributes
                        emphasisAttributes[NSFontAttributeName] = UIFont(descriptor: emphasisedFontDescriptor, size: 0.0)
                        
                        text.appendAttributedString(parseText(string, attributes: emphasisAttributes, features: features, appendNewline: false))
                        
                        // If the end operator is too long, treat it as the right operator followed by *s.
                        if endOperatorRange.startIndex.distanceTo(endIndex) > emphasisness {
                            let overlength = endOperatorRange.startIndex.distanceTo(endIndex) - emphasisness
                            let string = line.substringWithRange(endOperatorRange.startIndex.advancedBy(overlength)..<endIndex)
                            text.appendAttributedString(NSAttributedString(string: string, attributes: attributes))
                        }

                        range = endIndex..<range.endIndex
                        
                        // Don't double-add a newline.
                        if string.hasSuffix("\n") {
                            break loop
                        }
                        
                    } else {
                        // Didn't find the end emphasis; add the entire emphasis operator range to the output and continue from after it.
                        text.appendAttributedString(NSAttributedString(string: line.substringWithRange(operatorRange.startIndex..<index), attributes: attributes))
                        
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
                        
                        var linkAttributes = attributes
                        linkAttributes[linkAttributeName] = linkName
                        if let linkColor = linkColor {
                            linkAttributes[NSForegroundColorAttributeName] = linkColor
                        }
                        
                        // Add the text in the link to the output.
                        text.appendAttributedString(parseText(linkText, attributes: linkAttributes, features: features, appendNewline: false))
                        
                    } else {
                        // Didn't find an end to the link; just add the start operator to the output.
                        text.appendAttributedString(NSAttributedString(string: line.substringWithRange(operatorRange), attributes: attributes))
                        
                        range = operatorRange.endIndex..<range.endIndex
                    }
                case "\"":
                    // Locate the end of the quoted string.
                    if let endOperatorRange = line.rangeOfString("\"", options: [], range: operatorRange.endIndex..<range.endIndex, locale: nil) {
                        // Replace the quotes with smart quotes.
                        let string = "“\(line.substringWithRange(operatorRange.endIndex..<endOperatorRange.startIndex))”"
                        text.appendAttributedString(parseText(string, attributes: attributes, features: features, appendNewline: false))

                        range = endOperatorRange.endIndex..<range.endIndex
                    } else {
                        // Didn't find an end to the quote; just add the start quote to the output as a non-smart quote.
                        text.appendAttributedString(NSAttributedString(string: line.substringWithRange(operatorRange), attributes: attributes))
                        
                        range = operatorRange.endIndex..<range.endIndex
                    }
                case "'":
                    // No end operator here, just add the replacement quote to the string.
                    text.appendAttributedString(NSAttributedString(string: "’", attributes: attributes))
                    
                    range = operatorRange.endIndex..<range.endIndex
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
                    text.appendAttributedString(NSAttributedString(string: trailing, attributes: attributes))
                }
                
                break loop
            }
        }
        
        return text
    }
    
}
