//
//  InteractiveCollectionViewCell.swift
//  InteractiveCollectionViewCell
//
//  Created by Howard Lee on 7/2/16.
//  Copyright © 2016 Howard Lee. All rights reserved.
//

import UIKit

@IBDesignable
class InteractiveCollectionViewCell: UICollectionViewCell {
    
    /**
     The color of the overlay that covers the cell when it is selected.  Defaults to white
    */
    @IBInspectable
    var coverColor: UIColor = UIColor.whiteColor()
    
    /**
     The alpha of the overlay that covers the cell when it is selected.  Defaults to 0.3
    */
    @IBInspectable
    var coverAlpha: CGFloat = 0.3
    
    /**
     The image shown within the collection view cell
    */
    @IBInspectable
    var image: UIImage? {
        didSet {
            imageView.image = image
            setNeedsDisplay()
        }
    }
    
    /**
     The duration of the selected/unselected animations.  Defaults to 0.5
    */
    @IBInspectable
    var animationDuration: CFTimeInterval = 0.5
    
    /**
     The amount to scale the image when it is selected.  Defaults to 1.1
    */
    @IBInspectable
    var selectedImageScale: CGFloat = 1.1
    
    private var coverLayer: CAShapeLayer = CAShapeLayer()
    private var touchPoint: CGPoint? = nil
    private var imageView: UIImageView = UIImageView()
    
    private var selectedImageTransform: CGAffineTransform {
        return CGAffineTransformScale(CGAffineTransformIdentity, selectedImageScale, selectedImageScale)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        layer.addSublayer(coverLayer)
        coverLayer.path = UIBezierPath(ovalInRect: CGRectZero).CGPath
        coverLayer.fillColor = coverColor.colorWithAlphaComponent(coverAlpha).CGColor
        coverLayer.frame = bounds
        
        imageView.contentMode = .ScaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        let views = [ "imageView": imageView ]
        contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|[imageView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
        contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[imageView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
    }

    override var selected: Bool {
        didSet {
            if selected {
                if let touchPoint = touchPoint {
                    
                    let radius = bounds.width + bounds.height
                    let fromPath = UIBezierPath(ovalInRect: CGRect(x: touchPoint.x, y: touchPoint.y, width: 0, height: 0)).CGPath
                    let toPath = UIBezierPath(ovalInRect: CGRect(x: touchPoint.x - radius, y: touchPoint.y - radius, width: 2 * radius, height: 2 * radius)).CGPath
                    let coverAnimation = CABasicAnimation(keyPath: "path")
                    
                    CATransaction.begin()
                    CATransaction.setCompletionBlock({ [unowned self] in
                        self.coverLayer.path = toPath
                    })
                    coverAnimation.fromValue = fromPath
                    coverAnimation.toValue = toPath
                    coverAnimation.duration = animationDuration
                    coverLayer.addAnimation(coverAnimation, forKey: "coverAnimation")
                    
                    CATransaction.commit()
                    
                    UIView.animateWithDuration(animationDuration, animations: { [unowned self] in
                        self.imageView.transform = self.selectedImageTransform
                        }, completion: nil)
                    self.touchPoint = nil
                } else {
                    // this is called when a selected cell is shown again after it has been scrolled out
                    let midX = bounds.width / 2
                    let midY = bounds.height / 2
                    let radius = bounds.width + bounds.height
                    // this path must be circular otherwise the hide animation will look weird
                    coverLayer.path = UIBezierPath(ovalInRect: CGRect(x: midX - radius, y: midY - radius, width: 2 * radius, height: 2 * radius)).CGPath
                    imageView.transform = selectedImageTransform
                }
            } else {
                if let touchPoint = touchPoint {
                    let toPath = UIBezierPath(ovalInRect: CGRect(x: touchPoint.x, y: touchPoint.y, width: 0, height: 0)).CGPath
                    let coverHideAnimation = CABasicAnimation(keyPath: "path")
                    CATransaction.begin()
                    CATransaction.setCompletionBlock({ 
                        self.coverLayer.path = UIBezierPath(ovalInRect: CGRectZero).CGPath
                    })
                    coverHideAnimation.toValue = toPath
                    coverHideAnimation.duration = animationDuration
                    coverLayer.addAnimation(coverHideAnimation, forKey: "coverHideAnimation")
                    CATransaction.commit()
                } else {
                    coverLayer.path = UIBezierPath(ovalInRect: CGRectZero).CGPath
                }
                UIView.animateWithDuration(animationDuration, animations: { [unowned self] in
                    self.imageView.transform = CGAffineTransformIdentity
                })
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        coverLayer.frame = bounds
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        // Saves the touch point so we know where to animation in selected.
        // The animation cannot happen here because just because the cell is tapped
        // doesn't mean it's actually selected by the collection view.
        if touches.count > 0 {
            touchPoint = touches.first?.locationInView(self)
        }
    }
}
