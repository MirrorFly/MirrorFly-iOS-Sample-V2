//
//  MFToast.swift
//  MirrorflyUIkit
//
//  Created by Gowtham on 16/05/23.
//

import Foundation
import UIKit

/*
 *  Infix overload method
 */
func /(lhs: CGFloat, rhs: Int) -> CGFloat {
    return lhs / CGFloat(rhs)
}

public enum MFToastPosition {
   case top, bottom, center
}

/*
 *  Toast Config
 */
public struct MFToastConfig {
    
    var MFToastDefaultDuration  =   2.0
    var MFToastFadeDuration     =   0.2
    var MFToastHorizontalMargin : CGFloat  =   5.0
    var MFToastVerticalMargin   : CGFloat  =   5.0
    
    var MFToastPositionVerticalOffset : CGFloat = 10.0
    var MFToastVerticalOffset : CGFloat = 40.0
    var MFToastPosition                         = MFToastPositionDefault
    var MFToastzPosition              : CGFloat = 2.0
    
    // activity
    var MFToastActivityWidth  :  CGFloat  = 100.0
    var MFToastActivityHeight :  CGFloat  = 100.0
    var MFToastActivityPositionDefault    = "center"
    
    // image size
    var MFToastImageViewWidth :  CGFloat  = 80.0
    var MFToastImageViewHeight:  CGFloat  = 80.0
    
    // label setting
    var MFToastMaxWidth       :  CGFloat  = 0.8;      // 80% of parent view width
    var MFToastMaxHeight      :  CGFloat  = 0.5;
    var MFToastFontSize       :  CGFloat  = 14.0
    var MFToastMaxTitleLines              = 0
    var MFToastMaxMessageLines            = 0
    
    // shadow appearance
    var MFToastShadowOpacity  : CGFloat   = 0.8
    var MFToastShadowRadius   : CGFloat   = 6.0
    var MFToastShadowOffset   : CGSize    = CGSize(width: CGFloat(4.0), height: CGFloat(4.0))
    
    var MFToastOpacity        : CGFloat   = 0.7
    var MFToastCornerRadius   : CGFloat   = 8.0
    
    /*
     *  Custom Config
     */
    var MFToastHidesOnTap       =   true
    var MFToastDisplayShadow    =   true
    
    public init() {}
}

let MFToastPositionDefault  =   "bottom"
let MFToastPositionTop      =   "top"
let MFToastPositionCenter   =   "center"

var MFToastActivityView: UnsafePointer<UIView>?    =   nil
var MFToastTimer: UnsafePointer<Timer>?          =   nil
var MFToastView: UnsafePointer<UIView>?            =   nil
var MFToastThemeColor : UnsafePointer<UIColor>?    =   nil
var MFToastTitleFontName: UnsafePointer<String>?   =   nil
var MFToastFontName: UnsafePointer<String>?        =   nil
var MFToastFontColor: UnsafePointer<UIColor>?      =   nil

let defaults = MFToastConfig()

public extension UIView {
    
    /*
     *  public methods
     */
    class func mf_setToastThemeColor(color: UIColor) {
        objc_setAssociatedObject(self, &MFToastThemeColor, color, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    class func mf_toastThemeColor() -> UIColor {
        var color = objc_getAssociatedObject(self, &MFToastThemeColor) as! UIColor?
        if color == nil {
            color = UIColor(white: 0, alpha: 0.7)
            UIView.mf_setToastThemeColor(color: color!)
        }
        return color!
    }
    
    class func mf_setToastTitleFontName(fontName: String) {
        objc_setAssociatedObject(self, &MFToastTitleFontName, fontName, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    class func mf_toastTitleFontName() -> String {
        var name = objc_getAssociatedObject(self, &MFToastTitleFontName) as! String?
        if name == nil {
            let font = AppFont.Medium.size(14)
            name = font.fontName
            UIView.mf_setToastTitleFontName(fontName: name!)
        }
        
        return name!
    }
    
    class func mf_setToastFontName(fontName: String) {
        objc_setAssociatedObject(self, &MFToastFontName, fontName, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    class func mf_toastFontName() -> String {
        var name = objc_getAssociatedObject(self, &MFToastFontName) as! String?
        if name == nil {
            let font = AppFont.Medium.size(14)
            name = font.fontName
            UIView.mf_setToastFontName(fontName: name!)
        }
        
        return name!
    }
    
    class func mf_setToastFontColor(color: UIColor) {
        objc_setAssociatedObject(self, &MFToastFontColor, color, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    class func mf_toastFontColor() -> UIColor {
        var color = objc_getAssociatedObject(self, &MFToastFontColor) as! UIColor?
        if color == nil {
            color = UIColor.white
            UIView.mf_setToastFontColor(color: color!)
        }
        
        return color!
    }
    
    func makeToast(message msg: String, withConfiguration config: MFToastConfig = MFToastConfig()) {
        makeToast(message: msg, duration: config.MFToastDefaultDuration, position: .bottom, withConfiguration: config)
    }
    
    func makeToast(message msg: String, duration: Double, position: MFToastPosition, withConfiguration config: MFToastConfig = MFToastConfig()) {
        let toast = self.viewForMessage(msg, title: nil, image: nil, withConfiguration: config)
        showToast(toast: toast!, duration: duration, position: position, withConfiguration: config, message: msg)
    }
    
    func makeToast(message msg: String, duration: Double, position: MFToastPosition, title: String, withConfiguration config: MFToastConfig = MFToastConfig()) {
        let toast = self.viewForMessage(msg, title: title, image: nil, withConfiguration: config)
        showToast(toast: toast!, duration: duration, position: position, withConfiguration: config, message: msg)
    }
    
    func makeToast(message msg: String, duration: Double, position: MFToastPosition, image: UIImage, withConfiguration config: MFToastConfig = MFToastConfig()) {
        let toast = self.viewForMessage(msg, title: nil, image: image, withConfiguration: config)
        showToast(toast: toast!, duration: duration, position: position, withConfiguration: config, message: msg)
    }
    
    func makeToast(message msg: String, duration: Double, position: MFToastPosition, title: String, image: UIImage, withConfiguration config: MFToastConfig = MFToastConfig()) {
        let toast = self.viewForMessage(msg, title: title, image: image, withConfiguration: config)
        showToast(toast: toast!, duration: duration, position: position, withConfiguration: config, message: msg)
    }
    
    func showToast(toast: UIView, withConfiguration config: MFToastConfig = MFToastConfig()) {
        showToast(toast: toast, duration: config.MFToastDefaultDuration, position: .bottom, withConfiguration: config, message: "")
    }
    
    fileprivate func showToast(toast: UIView, duration: Double, position: MFToastPosition, withConfiguration config: MFToastConfig, message msg: String) {
        let existToast = objc_getAssociatedObject(self, &MFToastView) as! UIView?
        if existToast != nil {
            if let timer: Timer = objc_getAssociatedObject(existToast as Any, &MFToastTimer) as? Timer {
                timer.invalidate()
            }
            hideToast(toast: existToast!, force: false, withConfiguration: config);
            print("hide exist!")
        }
        
        toast.alpha = 0.0
        
        if config.MFToastHidesOnTap {
            let tapRecognizer = UITapGestureRecognizer(target: toast, action: #selector(UIView.handleToastTapped(_:)))
            toast.addGestureRecognizer(tapRecognizer)
            toast.isUserInteractionEnabled = true;
            toast.isExclusiveTouch = true;
        }
        
        addSubview(toast)
        let sidePadding = self.bounds.width * (1 - config.MFToastMaxWidth) / 2
        let screenWidth = (UIScreen.main.bounds.width) - config.MFToastVerticalOffset
        let desiredWidth = toast.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).width + config.MFToastPositionVerticalOffset
        if desiredWidth > screenWidth {
            toast.leftAnchor.constraint(equalTo: self.leftAnchor, constant: sidePadding).isActive = true
            toast.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -sidePadding).isActive = true
        } else {
            toast.widthAnchor.constraint(equalToConstant: desiredWidth).isActive = true
            toast.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: 0).isActive = true
        }
        
        let desiredSize = toast.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        toast.heightAnchor.constraint(equalToConstant: desiredSize.height).isActive = true
        
        let yPosition = yPositionForToastPosition(KeyboardStateListener.shared.isVisible ? .center : position, toastSize: desiredSize, withConfiguration: config)
        toast.centerYAnchor.constraint(equalTo: self.topAnchor, constant: yPosition).isActive = true
        objc_setAssociatedObject(self, &MFToastView, toast, .OBJC_ASSOCIATION_RETAIN)
        
        UIView.animate(withDuration: config.MFToastFadeDuration,
                       delay: 0.0, options: ([.curveEaseOut, .allowUserInteraction]),
                       animations: {
                        toast.alpha = 1.0
        },
                       completion: { (finished: Bool) in
                        let timer = Timer.scheduledTimer(timeInterval: duration, target: self, selector: #selector(UIView.toastTimerDidFinish(_:)), userInfo: toast, repeats: false)
                        objc_setAssociatedObject(toast, &MFToastTimer, timer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        })
    }
    
    func makeToastActivity(withConfiguration config: MFToastConfig = MFToastConfig()) {
        makeToastActivity(position: config.MFToastActivityPositionDefault as AnyObject, withConfiguration: config)
    }
    
    func makeToastActivity(message msg: String, withConfiguration config: MFToastConfig = MFToastConfig()){
        makeToastActivity(position: config.MFToastActivityPositionDefault as AnyObject, message: msg, withConfiguration: config)
    }
    
    fileprivate func makeToastActivity(position pos: AnyObject, message msg: String = "", withConfiguration config: MFToastConfig) {
        let existingActivityView: UIView? = objc_getAssociatedObject(self, &MFToastActivityView) as? UIView
        if existingActivityView != nil { return }
        
        let activityView = UIView(frame: CGRect(x: 0, y: 0, width: config.MFToastActivityWidth, height: config.MFToastActivityHeight))
        activityView.layer.cornerRadius = config.MFToastCornerRadius
        
        activityView.center = self.centerPointForPosition(pos, toast: activityView, withConfiguration: config)
        activityView.backgroundColor = UIColor(white: 0, alpha: 0.7)
        activityView.alpha = 0.0
        activityView.autoresizingMask = ([.flexibleLeftMargin, .flexibleTopMargin, .flexibleRightMargin, .flexibleBottomMargin])
        
        if config.MFToastDisplayShadow {
            activityView.layer.shadowColor = UIView.mf_toastThemeColor().cgColor
            activityView.layer.shadowOpacity = Float(config.MFToastShadowOpacity)
            activityView.layer.shadowRadius = config.MFToastShadowRadius
            activityView.layer.shadowOffset = config.MFToastShadowOffset
        }
        
        let activityIndicatorView = UIActivityIndicatorView(style: .whiteLarge)
        activityIndicatorView.center = CGPoint(x: activityView.bounds.size.width / 2, y: activityView.bounds.size.height / 2)
        activityView.addSubview(activityIndicatorView)
        activityIndicatorView.startAnimating()
        
        if (!msg.isEmpty){
            activityIndicatorView.frame.origin.y -= 10
            let activityMessageLabel = UILabel(frame: CGRect(x: activityView.bounds.origin.x, y: (activityIndicatorView.frame.origin.y + activityIndicatorView.frame.size.height + 10), width: activityView.bounds.size.width, height: 20))
            activityMessageLabel.textColor = UIView.mf_toastFontColor()
            activityMessageLabel.font = (msg.utf16.count<=10) ? UIFont(name:UIView.mf_toastFontName(), size: 16) : UIFont(name:UIView.mf_toastFontName(), size: 13)
            activityMessageLabel.textAlignment = .center
            activityMessageLabel.text = msg
            activityView.addSubview(activityMessageLabel)
        }
        
        addSubview(activityView)
        
        // associate activity view with self
        objc_setAssociatedObject(self, &MFToastActivityView, activityView, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        UIView.animate(withDuration: config.MFToastFadeDuration,
                       delay: 0.0,
                       options: UIView.AnimationOptions.curveEaseOut,
                       animations: {
                        activityView.alpha = 1.0
        },
                       completion: nil)
    }
    
    func hideToastActivity(withConfiguration config: MFToastConfig = MFToastConfig()) {
        let existingActivityView = objc_getAssociatedObject(self, &MFToastActivityView) as! UIView?
        if existingActivityView == nil { return }
        UIView.animate(withDuration: config.MFToastFadeDuration,
                       delay: 0.0,
                       options: UIView.AnimationOptions.curveEaseOut,
                       animations: {
                        existingActivityView!.alpha = 0.0
        },
                       completion: { (finished: Bool) in
                        existingActivityView!.removeFromSuperview()
                        objc_setAssociatedObject(self, &MFToastActivityView, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        })
    }
    
    /*
     *  private methods (helper)
     */
    func hideToast(toast: UIView) {
        hideToast(toast: toast, force: false, withConfiguration: MFToastConfig());
    }
    
    func hideToast(toast: UIView, force: Bool, withConfiguration config: MFToastConfig) {
        let completeClosure = { (finish: Bool) -> () in
            toast.removeFromSuperview()
            objc_setAssociatedObject(self, &MFToastTimer, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        if force {
            completeClosure(true)
        } else {
            UIView.animate(withDuration: config.MFToastFadeDuration,
                           delay: 0.0,
                           options: ([.curveEaseIn, .beginFromCurrentState]),
                           animations: {
                            toast.alpha = 0.0
            },
                           completion:completeClosure)
        }
    }
    
    @objc func toastTimerDidFinish(_ timer: Timer) {
        hideToast(toast: timer.userInfo as! UIView)
    }
    
    @objc func handleToastTapped(_ recognizer: UITapGestureRecognizer) {
        let timer = objc_getAssociatedObject(self, &MFToastTimer) as? Timer
        
        if let timer = timer {
            timer.invalidate()
        }
        
        hideToast(toast: recognizer.view!)
    }
    
    fileprivate func yPositionForToastPosition(_ position: MFToastPosition, toastSize: CGSize, withConfiguration config: MFToastConfig) -> CGFloat {
        let viewSize  = self.bounds.size
        
        if position == .top {
            return toastSize.height/2 + config.MFToastPositionVerticalOffset - self.safeAreaInsets.top
        } else if position == .bottom {
            return viewSize.height - toastSize.height/2 - config.MFToastPositionVerticalOffset - self.safeAreaInsets.bottom
        } else if position == .center {
            return viewSize.height/2
        }
        
        print("[Toast-Swift]: Warning! Invalid position for toast.")
        return viewSize.height/2
    }
    
    fileprivate func centerPointForPosition(_ position: AnyObject, toast: UIView, withConfiguration config: MFToastConfig) -> CGPoint {
        if position is String {
            let toastSize = toast.bounds.size
            let viewSize  = self.bounds.size
            if position.lowercased == MFToastPositionTop {
                return CGPoint(x: viewSize.width/2, y: toastSize.height/2 + config.MFToastVerticalMargin)
            } else if position.lowercased == MFToastPositionDefault {
                return CGPoint(x: viewSize.width/2, y: viewSize.height - toastSize.height/2 - config.MFToastVerticalMargin)
            } else if position.lowercased == MFToastPositionCenter {
                return CGPoint(x: viewSize.width/2, y: viewSize.height/2)
            }
        } else if position is NSValue {
            return position.cgPointValue
        }
        
        print("[Toast-Swift]: Warning! Invalid position for toast.")
        return self.centerPointForPosition(config.MFToastPosition as AnyObject, toast: toast, withConfiguration: config)
    }
    
    fileprivate func viewForMessage(_ msg: String?, title: String?, image: UIImage?, withConfiguration config: MFToastConfig) -> UIView? {
        if msg == nil && title == nil && image == nil { return nil }
        
        let someTextBeingShown = (msg != nil || title != nil)
        let wrapperView = createInitialView(withConfiguration: config)
        let contentsStackView = addContentsStackView(toWrapperView: wrapperView, withConfiguration: config)
        
        if let image = image {
            addImage(image, toStackView: contentsStackView)
        }
        
        if someTextBeingShown {
            addMessage(msg, andTitle: title, toStackView: contentsStackView, withConfiguration: config)
        }
        
        return wrapperView
    }
    
    fileprivate func createInitialView(withConfiguration config: MFToastConfig) -> UIView {
        let initialView = UIView()
        initialView.translatesAutoresizingMaskIntoConstraints = false
        initialView.layer.cornerRadius = config.MFToastCornerRadius
        initialView.layer.zPosition = config.MFToastzPosition
        initialView.backgroundColor = UIColor(white: 0, alpha: 0.7)
        
        if config.MFToastDisplayShadow {
            initialView.layer.shadowColor = UIView.mf_toastThemeColor().cgColor
            initialView.layer.shadowOpacity = Float(config.MFToastShadowOpacity)
            initialView.layer.shadowRadius = config.MFToastShadowRadius
            initialView.layer.shadowOffset = config.MFToastShadowOffset
        }
        
        return initialView
    }
    
    fileprivate func addContentsStackView(toWrapperView wrapperView: UIView, withConfiguration config: MFToastConfig) -> UIStackView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.backgroundColor = UIColor.clear
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = config.MFToastVerticalMargin
        stackView.setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: .vertical)
        stackView.setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        
        wrapperView.addSubview(stackView)
        stackView.centerXAnchor.constraint(equalTo: wrapperView.centerXAnchor).isActive = true
        let leftSideConstraint = stackView.leftAnchor.constraint(greaterThanOrEqualTo: wrapperView.leftAnchor, constant: config.MFToastHorizontalMargin)
        leftSideConstraint.priority = UILayoutPriority(rawValue: 1000)
        leftSideConstraint.isActive = true
        let rightSideConstraint = stackView.rightAnchor.constraint(lessThanOrEqualTo: wrapperView.rightAnchor, constant: -config.MFToastHorizontalMargin)
        rightSideConstraint.priority = UILayoutPriority(rawValue: 1000)
        rightSideConstraint.isActive = true
        let leftSideEqualConstraint = stackView.leftAnchor.constraint(equalTo: wrapperView.leftAnchor, constant: config.MFToastHorizontalMargin)
        leftSideEqualConstraint.priority = UILayoutPriority(rawValue: 250)
        leftSideEqualConstraint.isActive = true
        let rightSideEqualConstraint = stackView.rightAnchor.constraint(equalTo: wrapperView.rightAnchor, constant: -config.MFToastHorizontalMargin)
        rightSideEqualConstraint.priority = UILayoutPriority(rawValue: 250)
        rightSideEqualConstraint.isActive = true
        stackView.topAnchor.constraint(equalTo: wrapperView.topAnchor, constant: config.MFToastVerticalMargin).isActive = true
        stackView.bottomAnchor.constraint(equalTo: wrapperView.bottomAnchor, constant: -config.MFToastVerticalMargin).isActive = true
        
        return stackView
    }
    
    fileprivate func addImage(_ image: UIImage, toStackView stackView: UIStackView) {
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        imageView.setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: .vertical)
        
        stackView.addArrangedSubview(imageView)
    }
    
    fileprivate func addMessage(_ msg: String?, andTitle title: String?, toStackView parentStackView: UIStackView, withConfiguration config: MFToastConfig) {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.backgroundColor = UIColor.clear
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = config.MFToastVerticalMargin
        parentStackView.addArrangedSubview(stackView)
        
        stackView.setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: .vertical)
        stackView.setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        
        if let title = title {
            let titleLabel = UILabel()
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.numberOfLines = config.MFToastMaxTitleLines
            titleLabel.font = UIFont(name: UIView.mf_toastFontName(), size: config.MFToastFontSize)
            titleLabel.textAlignment = .center
            titleLabel.lineBreakMode = .byWordWrapping
            titleLabel.textColor = UIView.mf_toastFontColor()
            titleLabel.backgroundColor = UIColor.clear
            titleLabel.alpha = 1.0
            titleLabel.text = title
            
            titleLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 751), for: .vertical)
            stackView.addArrangedSubview(titleLabel)
        }
        
        if let msg = msg {
            let msgLabel = UILabel()
            msgLabel.translatesAutoresizingMaskIntoConstraints = false
            msgLabel.numberOfLines = config.MFToastMaxMessageLines
            msgLabel.font = UIFont(name: UIView.mf_toastFontName(), size: config.MFToastFontSize)
            msgLabel.lineBreakMode = .byWordWrapping
            msgLabel.textAlignment = .center
            msgLabel.textColor = UIView.mf_toastFontColor()
            msgLabel.backgroundColor = UIColor.clear
            msgLabel.alpha = 1.0
            msgLabel.text = msg
            
            msgLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 751), for: .vertical)
            stackView.addArrangedSubview(msgLabel)
        }
    }
    
}
class KeyboardStateListener: NSObject {
    static let shared = KeyboardStateListener()
    var isVisible = false
    

    func start() {
        NotificationCenter.default.addObserver(self, selector: #selector(didShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func didShow() {
        isVisible = true
    }

    @objc func didHide() {
        isVisible = false
    }
}
