//
//  HidingViewController.swift
//  Optimus
//
//  Created by Tristan Himmelman on 2015-03-17.
//  Copyright (c) 2015 Hearst TV. All rights reserved.
//

import UIKit

class HidingViewController {
	
	var child: HidingViewController?
	var navSubviews: [UIView]?
	var view: UIView
	
	var expandedCenter: ((UIView) -> CGPoint)?
	
	var alphaFadeEnabled = false
	var contractsUpwards = true
	
	init(view: UIView) {
		self.view = view
	}
	
	init() {
		view = UIView(frame: CGRectMake(0, 0, 0, 0))
		view.backgroundColor = UIColor.clearColor()
		view.autoresizingMask = .FlexibleWidth | .FlexibleBottomMargin
	}
	
	func expandedCenterValue() -> CGPoint {
		if let expandedCenter = expandedCenter {
			return expandedCenter(view)
		}
		return CGPointMake(0, 0)
	}
	
	func contractionAmountValue() -> CGFloat {
		return CGRectGetHeight(view.bounds)
	}
	
	func contractedCenterValue() -> CGPoint {
		if contractsUpwards {
			return CGPointMake(expandedCenterValue().x, expandedCenterValue().y - contractionAmountValue())
		} else {
			return CGPointMake(expandedCenterValue().x, expandedCenterValue().y + contractionAmountValue())
		}
	}
	
	func isContracted() -> Bool {
		return Float(fabs(view.center.y - contractedCenterValue().y)) < FLT_EPSILON
	}
	
	func isExpanded() -> Bool {
		return Float(fabs(view.center.y - expandedCenterValue().y)) < FLT_EPSILON
	}
	
	func totalHeight() -> CGFloat {
		let height = expandedCenterValue().y - contractedCenterValue().y
		if let child = child {
			return child.totalHeight() + height
		}
		return height
	}
	
	func setAlphaFadeEnabled(alphaFadeEnabled: Bool) {
		self.alphaFadeEnabled = alphaFadeEnabled
	
		if !alphaFadeEnabled {
			updateSubviewsToAlpha(1.0)
		}
	}
	
	func updateYOffset(delta: CGFloat) -> CGFloat {
		var deltaY = delta
		if child != nil && deltaY < 0 {
			deltaY = child!.updateYOffset(deltaY)
			child!.view.hidden = (deltaY) < 0;
		}
		
		var newYOffset = view.center.y + deltaY
		var newYCenter = max(min(expandedCenterValue().y, newYOffset), contractedCenterValue().y)
		if contractsUpwards == false {
			newYOffset = view.center.y - deltaY
			newYCenter = min(max(expandedCenterValue().y, newYOffset), contractedCenterValue().y)
		}

		view.center = CGPointMake(view.center.x, newYCenter)

		if alphaFadeEnabled {
			var newAlpha: CGFloat = 1.0 - (expandedCenterValue().y - view.center.y) * 2 / contractionAmountValue()
			newAlpha = CGFloat(min(max(FLT_EPSILON, Float(newAlpha)), 1.0))
			
			updateSubviewsToAlpha(newAlpha)
		}
	
		var residual = newYOffset - newYCenter
		
		if (child != nil && deltaY > 0 && residual > 0) {
			residual = child!.updateYOffset(residual)
			child!.view.hidden = residual - (newYOffset - newYCenter) > 0
		}
		
		return residual;
	}
	
	func snap(contract: Bool, completion:((Void) -> Void)!) -> CGFloat {
		var deltaY: CGFloat = 0
		
		UIView.animateWithDuration(0.2, delay: 0, options: UIViewAnimationOptions.allZeros, animations: {
			if let child = self.child {
				if contract && child.isContracted() {
					deltaY = self.contract()
				} else {
					deltaY = self.expand()
				}
			} else {
				if contract {
					deltaY = self.contract()
				} else {
					deltaY = self.expand()
				}
			}
		}) { (success: Bool) -> Void in
			if completion != nil{
				completion();
			}
		}
		
		return deltaY;
	}
	
	func expand() -> CGFloat {
		view.hidden = false
		
		if alphaFadeEnabled {
			updateSubviewsToAlpha(1)
			navSubviews = nil
		}
		
		var amountToMove = expandedCenterValue().y - view.center.y
		
		view.center = expandedCenterValue()
		if let child = child {
			amountToMove += child.expand()
		}
		
		return amountToMove;
	}
	
	func contract() -> CGFloat {
		if alphaFadeEnabled {
			updateSubviewsToAlpha(0)
		}
		
		var amountToMove = contractedCenterValue().y - view.center.y
		
		view.center = contractedCenterValue()
		
		return amountToMove;
	}
	
	// MARK: - Private methods
	
	private func updateSubviewsToAlpha(alpha: CGFloat) {
		if navSubviews == nil {
			navSubviews = []
			
			// loops through and subview and save the visible ones in navSubviews array
			for subView in view.subviews as! [UIView] {
				let isBackgroundView = subView === view.subviews[0]
				let isViewHidden = subView.hidden || Float(subView.alpha) < FLT_EPSILON
				
				if isBackgroundView == false && isViewHidden == false {
					navSubviews?.append(subView)
				}
			}
		}
		
		if let subViews = navSubviews {
			for subView in subViews {
				subView.alpha = alpha
			}
		}
	}
}
