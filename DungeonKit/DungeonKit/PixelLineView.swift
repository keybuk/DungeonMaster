//
//  PixelLineView.swift
//  DungeonKit
//
//  Created by Scott James Remnant on 2/16/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import UIKit

/// VerticalPixelLineView is a simple UIView that draws a pixel-width line along its left-most edge.
@IBDesignable open class VerticalPixelLineView: UIView {
    
    /// Width of the line in pixels, not points.
    ///
    /// The current content scale factor is taken into account, along with the relative offsets of pixel boundaries, to accurately draw a true pixel-width line.
    @IBInspectable open var widthInPixels: CGFloat = 1.0 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    /// Color of the line.
    @IBInspectable open var color: UIColor = UIColor.black {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        configureDefaults()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureDefaults()
    }
    
    func configureDefaults() {
        // Generally the view is going to be transparent, that means we have to take care of the background ourselves.
        isOpaque = false
        clearsContextBeforeDrawing = false
        
        contentMode = .scaleToFill
        autoresizingMask = .flexibleHeight
    }

    open override var intrinsicContentSize : CGSize {
        // The view always has an intrinsic width, based on the line itself, return that so we don't need a constraint for it.
        let lineWidth = ceil(widthInPixels / contentScaleFactor)
        
        return CGSize(width: lineWidth, height: UIViewNoIntrinsicMetric)
    }
    
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        let sizeThatFits = super.sizeThatFits(size)
        let lineWidth = ceil(widthInPixels / contentScaleFactor)
        
        return CGSize(width: lineWidth, height: sizeThatFits.height)
    }
    
    override open func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        // Clear the rectangle to be drawn.
        context?.setFillColor((backgroundColor ?? UIColor.clear).cgColor)
        context?.fill(rect)
        
        // Since we only draw a single line, it's almost certainly cheaper to just use the default clip than worry about it ourselves.
        let width = widthInPixels / contentScaleFactor
        let offset = width / 2.0
        
        context?.setStrokeColor(color.cgColor)
        context?.setLineWidth(width)
        
        context?.move(to: CGPoint(x: offset, y: 0.0))
        context?.addLine(to: CGPoint(x: offset, y: bounds.size.height))
        
        context?.drawPath(using: .stroke)
    }
    
}

/// HorizontalPixelLineView is a simple UIView that draws a pixel-width line along its top-most edge.
@IBDesignable open class HorizontalPixelLineView: UIView {
    
    /// Width of the line in pixels, not points.
    ///
    /// The current content scale factor is taken into account, along with the relative offsets of pixel boundaries, to accurately draw a true pixel-width line.
    @IBInspectable open var widthInPixels: CGFloat = 1.0 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    /// Color of the line.
    @IBInspectable open var color: UIColor = UIColor.black {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        configureDefaults()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureDefaults()
    }
    
    func configureDefaults() {
        // Generally the view is going to be transparent, that means we have to take care of the background ourselves.
        isOpaque = false
        clearsContextBeforeDrawing = false
        
        contentMode = .scaleToFill
        autoresizingMask = .flexibleWidth
    }
    
    open override var intrinsicContentSize : CGSize {
        // The view always has an intrinsic width, based on the line itself, return that so we don't need a constraint for it.
        let lineWidth = ceil(widthInPixels / contentScaleFactor)
        
        return CGSize(width: UIViewNoIntrinsicMetric, height: lineWidth)
    }
    
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        let sizeThatFits = super.sizeThatFits(size)
        let lineWidth = ceil(widthInPixels / contentScaleFactor)
        
        return CGSize(width: sizeThatFits.width, height: lineWidth)
    }
    
    override open func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        // Clear the rectangle to be drawn.
        context?.setFillColor((backgroundColor ?? UIColor.clear).cgColor)
        context?.fill(rect)
        
        // Since we only draw a single line, it's almost certainly cheaper to just use the default clip than worry about it ourselves.
        let width = widthInPixels / contentScaleFactor
        let offset = width / 2.0
        
        context?.setStrokeColor(color.cgColor)
        context?.setLineWidth(width)
        
        context?.move(to: CGPoint(x: 0.0, y: offset))
        context?.addLine(to: CGPoint(x: bounds.size.width, y: offset))
        
        context?.drawPath(using: .stroke)
    }
    
}
