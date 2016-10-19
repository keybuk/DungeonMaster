//
//  AdjustableImageView.swift
//  DungeonMaster
//
//  Created by Scott James Remnant on 1/4/16.
//  Copyright © 2016 Scott James Remnant. All rights reserved.
//

import UIKit

/// Delegate protocol used by `AdjustableImageView` to report changes to the image during editing.
@objc protocol AdjustableImageViewDelegate {
    
    /// Reports that the user has tapped on the image. The delegate should respond by displaying a picker and allowing the user to set a new image.
    func adjustableImageViewShouldChangeImage(_ adjustableImageView: AdjustableImageView)
    
    /// Reports that the user has changed the area of the image that is to be used.
    func adjustableImageViewDidChangeArea(_ adjustableImageView: AdjustableImageView)
    
}

/// AdjustableImageView provides a square view that displays a `UIImage` or fraction thereof.
///
/// The fraction of the image displayed is based on the `fraction` and `origin` properties, providing a smaller area of the image.
///
/// When the view is placed into `editing` mode, the user can tap the view to select (via a delegate method) a new image, and can use pinch and pan gestures to change the `fraction` and `origin` properties of the view.
@IBDesignable class AdjustableImageView: UIView, UIGestureRecognizerDelegate {

    @IBOutlet weak var delegate: AdjustableImageViewDelegate?
    
    /// Alternate view that gesture recognizers should be installed to.
    @IBOutlet weak var gestureView: UIView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        configureView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        configureView()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        configureView()
    }

    var imageLayer: CALayer!
    var tapGestureRecognizer: UITapGestureRecognizer!
    var pinchGestureRecognizer: UIPinchGestureRecognizer!
    var panGestureRecognizer: UIPanGestureRecognizer!
    
    func configureView() {
        isOpaque = true
        clearsContextBeforeDrawing = false
        
        imageLayer = CALayer()
        imageLayer.frame = layer.bounds
        imageLayer.isOpaque = true
        imageLayer.backgroundColor = UIColor.darkGray.cgColor
        layer.addSublayer(imageLayer)
        
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapGestureRecognizer.delegate = self
        
        pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        pinchGestureRecognizer.delegate = self
        
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGestureRecognizer.delegate = self
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        // Restrict to square aspect ratios.
        let axis = min(size.width, size.height)
        return CGSize(width: axis, height: axis)
    }
    
    /// Switches the view between editing and non-editing mode.
    ///
    /// In non-editing mode, the view functions much like a `UIImageView` except that it only renders the portion of the `image` specified by `fraction` and `origin`.
    /// In editing mode, the view allows the user to select a new image by tapping on the view, and adjust the portion displayed by using pinch and pan gestures.
    var editing = false {
        didSet {
            guard editing != oldValue else { return }
            if editing {
                addGestureRecognizer(tapGestureRecognizer)
                (gestureView ?? self).addGestureRecognizer(pinchGestureRecognizer)
                (gestureView ?? self).addGestureRecognizer(panGestureRecognizer)
            } else {
                removeGestureRecognizer(tapGestureRecognizer)
                (gestureView ?? self).removeGestureRecognizer(pinchGestureRecognizer)
                (gestureView ?? self).removeGestureRecognizer(panGestureRecognizer)
            }
            
            updateLayer()
            updateInstructionView()
        }
    }
    
    /// View overlaying the image to provide basic instructions during editing.
    var instructionView: UIView?
    
    /// Updates, removes, or installs the instruction view over the image.
    func updateInstructionView() {
        if let instructionView = instructionView {
            instructionView.removeFromSuperview()
            self.instructionView = nil
        }
        
        guard editing else { return }
        
        // The top of the instruction view hierarchy is a dark blur effect, horizontally centered, and about 80% vertically down the image.
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(blurView)
        
        blurView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        addConstraint(NSLayoutConstraint(item: blurView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 0.8, constant: 0.0))

        // Packed within it is a vibrancy view.
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
        let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
        vibrancyView.translatesAutoresizingMaskIntoConstraints = false

        blurView.contentView.addSubview(vibrancyView)

        vibrancyView.topAnchor.constraint(equalTo: blurView.topAnchor).isActive = true
        vibrancyView.leftAnchor.constraint(equalTo: blurView.leftAnchor).isActive = true
        vibrancyView.rightAnchor.constraint(equalTo: blurView.rightAnchor).isActive = true
        vibrancyView.bottomAnchor.constraint(equalTo: blurView.bottomAnchor).isActive = true
        
        // And within that is the actual label.
        let label = UILabel()
        if let _ = image {
            label.text = "Pan or Pinch to adjust image"
        } else {
            label.text = "Tap to select image"
        }
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.font = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: UIFontTextStyle.caption1).withSymbolicTraits(.traitBold)!, size: 0.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        
        label.heightAnchor.constraint(equalToConstant: label.bounds.size.height).isActive = true
        label.widthAnchor.constraint(equalToConstant: label.bounds.size.width).isActive = true

        vibrancyView.contentView.addSubview(label)
        
        label.topAnchor.constraint(equalTo: vibrancyView.layoutMarginsGuide.topAnchor).isActive = true
        label.leftAnchor.constraint(equalTo: vibrancyView.layoutMarginsGuide.leftAnchor).isActive = true
        label.rightAnchor.constraint(equalTo: vibrancyView.layoutMarginsGuide.rightAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: vibrancyView.layoutMarginsGuide.bottomAnchor).isActive = true

        // Layout the subviews to avoid an animation as everything moves into place.
        instructionView = blurView
        layoutSubviews()
    }
    
    //// When false, setting the `image`, `fraction`, or `origin` properties do not update the view.
    var updateLayerOnChange = true
    
    /// The image to be displayed in the view.
    @IBInspectable var image: UIImage? {
        didSet {
            didChangeImage()
            if updateLayerOnChange {
                updateLayer(changeImage: true)
            }
            if editing {
                updateInstructionView()
            }
        }
    }

    /// Image to be displayed in the view when `image` is set to `nil`.
    @IBInspectable var placeholderImage: UIImage? {
        didSet {
            guard image == nil else { return }
            if updateLayerOnChange {
                updateLayer(changeImage: true)
            }
        }
    }

    /// Fraction of image to be displayed.
    ///
    /// A value of 1.0 indicates a square rectangle equal in size to the shortest dimension of the underlying image (width or height). Smaller values "zoom" the image based on a unit portion of that same dimension.
    @IBInspectable var fraction: CGFloat = 1.0 {
        didSet {
            if updateLayerOnChange {
                updateLayer()
            }
        }
    }
    
    /// Origin of the image fraction to be displayed.
    ///
    /// A value of (0.0, 0.0) is anchored to the top-left corner of the image. For an image twice as wide as it is high, that would be the left half; (1.0, 0.0) would represent the right half of the image; and (0.5, 0.0) would be the middle section of the image.
    @IBInspectable var origin = CGPoint.zero {
        didSet {
            if updateLayerOnChange {
                updateLayer()
            }
        }
    }
    
    /// Called when the image is changed to update the fraction and origin to the center of the new image.
    ///
    /// Does not cause a layer update.
    func didChangeImage() {
        let oldUpdateLayerOnChange = updateLayerOnChange
        updateLayerOnChange = false
        if let _ = image {
            let divisor = divisorForImage()
            fraction = 1.0
            origin = CGPoint(x: 0.5 - fraction / (2 * divisor.x), y: 0.5 - fraction / (2 * divisor.y))
        } else {
            fraction = 1.0
            origin = CGPoint.zero
        }
        updateLayerOnChange = oldUpdateLayerOnChange
    }

    /// Update the image, fraction, and origin in one setting.
    ///
    /// Causes only a single layer update, while setting the three properties will change them individually.
    func setImage(_ image: UIImage?, fraction: CGFloat = 1.0, origin: CGPoint = CGPoint.zero) {
        let oldUpdateLayerOnChange = updateLayerOnChange
        updateLayerOnChange = false
        
        let oldImage = self.image
        self.image = image
        self.fraction = fraction
        self.origin = origin
        
        updateLayer(changeImage: image != oldImage)
        updateLayerOnChange = oldUpdateLayerOnChange
    }
    
    /// Returns unit divisors to use for the image.
    ///
    /// For perfectly square images, this wouldn't be needed since 1.0 would represent 100% of the images in both directions. Since images are rarely square, this instead returns a `CGPoint` where either the `x` or `y` is 1.0, and the other member is a number greater than 1.0 to divide by to get the equivalent scale.
    func divisorForImage() -> CGPoint {
        guard let image = image ?? placeholderImage else { return CGPoint.zero }
        
        let aspectRatio = image.size.width / image.size.height
        let divisor: CGPoint
        if aspectRatio > 1.0 {
            divisor = CGPoint(x: aspectRatio, y: 1.0)
        } else {
            divisor = CGPoint(x: 1.0, y: 1.0 / aspectRatio)
        }
        
        return divisor
    }
    
    /// Updates the image layer based on the current state.
    func updateLayer(changeImage: Bool = false) {
        let contents: CGImage?, opacity: Float
        if let image = image {
            contents = image.cgImage
            opacity = 1.0
        } else if let image = placeholderImage {
            contents = image.cgImage
            opacity = editing ? 0.5 : 1.0
        } else {
            contents = nil
            opacity = editing ? 0.5 : 1.0
        }
        
        let divisor = divisorForImage()

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        if changeImage {
            imageLayer.contents = contents
        }
        imageLayer.contentsRect = CGRect(x: origin.x, y: origin.y, width: fraction / divisor.x, height: fraction / divisor.y)
        CATransaction.commit()
        
        // Okay to animate this.
        if opacity != imageLayer.opacity {
            imageLayer.opacity = opacity
        }
    }
    
    
    // MARK: Gesture handling
    
    func handleTapGesture(_ recognizer: UITapGestureRecognizer) {
        if recognizer.state == .ended {
            delegate?.adjustableImageViewShouldChangeImage(self)
        }
    }

    func handlePinchGesture(_ recognizer: UIPinchGestureRecognizer) {
        guard let _ = image else { return }

        switch recognizer.state {
        case .began, .changed:
            // Adjust the zoom by the gesture scale factor, without allowing it to go above 1.0.
            let newFraction = min(fraction / recognizer.scale, 1.0)

            // That alone would always scale the image from the top-left of the visible area; a better experience is if the image appears to expand from the position centered between the user's two fingers.
            // To make that work, we first calculate the difference in scale; we already know that an origin of 0,0 is the top-left, and it makes sense that for a bottom-right effect, when going from 1.0 to 0.2, we would want to shift the box right and down by 0.8.
            // We then need to know how much of a unit between 0 and that we actually want to apply, this is the relative position of the touch location within the view. Multiplying the two together gives us the amount of the scale difference we want to use as an offset.
            // Finally since the image isn't actually square, and this is a square translation, we divide by the divisor.
            let location = recognizer.location(in: self)
            let divisor = divisorForImage()

            var newOrigin = origin
            newOrigin.x += ((fraction - newFraction) * (location.x / bounds.size.width)) / divisor.x
            newOrigin.y += ((fraction - newFraction) * (location.y / bounds.size.height)) / divisor.y
            
            // Clamp the origin to a valid range for the image at this scale.
            newOrigin.x = min(max(0.0, newOrigin.x), 1.0 - fraction / divisor.x)
            newOrigin.y = min(max(0.0, newOrigin.y), 1.0 - fraction / divisor.y)

            setImage(image, fraction: newFraction, origin: newOrigin)
            
            // Reset the gesture scale so that the next call is relative to this one.
            pinchGestureRecognizer.scale = 1.0
        case .ended:
            delegate?.adjustableImageViewDidChangeArea(self)
        default:
            break
        }
    }
    
    func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        guard let image = image else { return }

        switch recognizer.state {
        case .began, .changed:
            let translation = panGestureRecognizer.translation(in: self)
            
            // Modify the pan translation by the image fraction and UI contents scale to match the portion of the image currently displayed. The conversion here is UI points, to image pixels, to fraction-relative pixels, and then to unit value.
            var newOrigin = origin
            newOrigin.x -= (translation.x * window!.screen.scale * fraction) / image.size.width
            newOrigin.y -= (translation.y * window!.screen.scale * fraction) / image.size.height
            
            // Clamp the offset to a valid range for the image at this scale.
            let divisor = divisorForImage()
            newOrigin.x = min(max(0.0, newOrigin.x), 1.0 - fraction / divisor.x)
            newOrigin.y = min(max(0.0, newOrigin.y), 1.0 - fraction / divisor.y)
            origin = newOrigin
            
            // Reset the gesture translation so that the next call is relative to this one.
            panGestureRecognizer.setTranslation(CGPoint.zero, in: self)
        case .ended:
            delegate?.adjustableImageViewDidChangeArea(self)
        default:
            break
        }
    }

   // MARK: UIGestureRecognizerDelegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

}
