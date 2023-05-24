//
//  ViewExtension.swift
//  MirrorflyUIkit
//
//  Created by User on 21/09/21.
//

import Foundation
import UIKit
extension UIView {

    func addTopShadow(shadowColor : UIColor){
        self.layer.masksToBounds = false
        self.layer.shadowColor = shadowColor.cgColor
        self.layer.shadowOpacity = 0.5
        self.layer.shadowOffset = CGSize(width: -0.5, height: -4.0)
        self.layer.shadowRadius = 1
        self.layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = true ? UIScreen.main.scale : 1
    }
    
    func addBottomShawdow() {
        self.layer.shadowOffset = CGSize(width: 0, height: 1)
        self.layer.shadowColor = UIColor.lightGray.cgColor
        self.layer.shadowOpacity = 1
        self.layer.shadowRadius = 5
        self.layer.masksToBounds = false

    }
    func roundCorners(corners:UIRectCorner, radius: CGFloat) {

           DispatchQueue.main.async {
               let path = UIBezierPath(roundedRect: self.bounds,
                                       byRoundingCorners: corners,
                                       cornerRadii: CGSize(width: radius, height: radius))
               let maskLayer = CAShapeLayer()
               maskLayer.frame = self.bounds
               maskLayer.path = path.cgPath
               self.layer.mask = maskLayer
           }
       }

    func cornerRadius(radius: CGFloat, width: CGFloat, color: UIColor) {
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
        self.layer.borderColor = color.cgColor
        self.layer.borderWidth = width
    }
    
    // make view as circle view
    func makeCircleView(borderColor: CGColor,borderWidth: CGFloat) {
        self.layer.cornerRadius = (self.frame.size.width ) / 2
        self.clipsToBounds = true
        self.layer.borderWidth = borderWidth
        self.layer.borderColor = borderColor
    }
    
    public var viewWidth: CGFloat {
        return self.frame.size.width
    }
    
    func fixInView(_ container: UIView!) -> Void{
        self.translatesAutoresizingMaskIntoConstraints = false;
        self.frame = container.frame;
        container.addSubview(self);
        NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: container, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: container, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: container, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
    }
    
    enum ViewSide {
        case Top, Bottom, Left, Right
    }
    
    func addBorder(toSide side: ViewSide, withColor color: UIColor, andThickness thickness: CGFloat) {
        
        let border = CALayer()
        border.backgroundColor = color.cgColor
        
        switch side {
        case .Top:
            border.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: thickness)
        case .Bottom:
            border.frame = CGRect(x: 0, y: frame.size.height - thickness, width: frame.size.width, height: thickness)
        case .Left:
            border.frame = CGRect(x: 0, y: 0, width: thickness, height: frame.size.height)
        case .Right:
            border.frame = CGRect(x: frame.size.width - thickness, y: 0, width: thickness, height: frame.size.height)
        }
        
        layer.addSublayer(border)
    }
   
}

class CustomTabBar : UITabBar {

@IBInspectable var height: CGFloat = 65.0

override open func sizeThatFits(_ size: CGSize) -> CGSize {
    guard let window = UIApplication.shared.keyWindow else {
        return super.sizeThatFits(size)
    }
    var sizeThatFits = super.sizeThatFits(size)
    if height > 0.0 {

        if #available(iOS 11.0, *) {
            sizeThatFits.height = height + window.safeAreaInsets.bottom
        } else {
            sizeThatFits.height = height
        }
    }
    return sizeThatFits
}
}

extension UIWindow {
    func getTopViewController() -> UIViewController? {
        var top = self.rootViewController
        while true {
            if let presented = top?.presentedViewController {
                top = presented
            } else if let nav = top as? UINavigationController {
                top = nav.visibleViewController
            } else if let tab = top as? UITabBarController {
                top = tab.selectedViewController
            } else {
                break
            }
        }
      if let mainNC = top as? UINavigationController ,let mainVC = mainNC.visibleViewController {
            return mainVC
        }
        return top
    }
}

public func getCGSize(width: Int, height: Int) -> CGSize {
   return CGSize(width: 15, height: 15)
}
