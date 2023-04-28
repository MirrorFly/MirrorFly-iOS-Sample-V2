//
//  ShareKitExtension.swift
//  MirrorflyUIkit
//
//  Created by John on 20/02/23.
//

import Foundation
import UIKit
import AVKit
import Photos
import MirrorFlySDK
import SDWebImage
import PhoneNumberKit

extension String{
    //Check string is empty
    static var Empty: String {
        return ""
    }
    
    // trim string
    func trim() -> String {
        return self.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
    }
    
    var isNotEmpty: Bool {
        return !(self.trim().isEmpty)
    }
    
}


class Helper {
    static func getLoaderViews(view: UIView)->(UIView,UIActivityIndicatorView,UILabel){
        let activityIndicatorView = UIActivityIndicatorView()
        let blurView = UIView(frame: CGRect(x: view.bounds.minX + 70, y: view.bounds.minY + 100, width: 100, height: 100))
        let label = UILabel(frame: CGRect(x: view.center.x, y: view.center.y, width: 250, height: 150))
        
        // create your components,customise and return
        return (blurView,activityIndicatorView,label)
    }
}

extension UIViewController {
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    func startLoading(view: UIViewController, withText: String) {
        UIViewController.showUniversalLoadingView(view: view, true, loadingText: withText)
    }

    func stopLoading(view: UIViewController = UIViewController()) {
        UIViewController.showUniversalLoadingView(view: view, false)
      }
    
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    class func makeLoadingView(withFrame frame: CGRect, loadingText text: String?) -> UIView? {
       let loadingView = UIView(frame: frame)
       loadingView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
       let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
       //activityIndicator.backgroundColor = UIColor(red:0.16, green:0.17, blue:0.21, alpha:1)
       activityIndicator.layer.cornerRadius = 6
       activityIndicator.center = loadingView.center
       activityIndicator.hidesWhenStopped = true
                if #available(iOS 13.0, *) {
                    activityIndicator.style = .large
                } else {
                    activityIndicator.style = .gray
                    // Fallback on earlier versions
                }
        activityIndicator.color = .black
       activityIndicator.startAnimating()
       activityIndicator.tag = 100 // 100 for example

       loadingView.addSubview(activityIndicator)
       if !text!.isEmpty {
        let lbl = UILabel(frame: CGRect(x: 0, y: activityIndicator.frame.origin.y +   120, width: 250, height: 150))
           let cpoint = CGPoint(x: activityIndicator.frame.origin.x + activityIndicator.frame.size.width / 2, y: activityIndicator.frame.origin.y + 110)
           lbl.center = cpoint
           lbl.textColor = UIColor.white
           lbl.textAlignment = .center
        lbl.numberOfLines = 0
           lbl.text = text
           loadingView.addSubview(lbl)
       }
       return loadingView
   }
    
    class func showUniversalLoadingView(view : UIViewController ,_ show: Bool, loadingText : String = "") {
        let existingView = UIView(frame: CGRectMake(100, 100, 100, 100)).viewWithTag(1200)
        if show {
            if existingView != nil {
                return
            }
            let loadingView = self.makeLoadingView(withFrame: UIScreen.main.bounds, loadingText: loadingText)
            loadingView?.tag = 1200
            view.view.addSubview(loadingView ?? UIView())
        } else {
            existingView?.removeFromSuperview()
        }

    }
    
    //New
    func startLoadingIndicator(view:UIView,blurView:UIView ,activityIndicatorView:UIActivityIndicatorView,label:UILabel,withText: String) {
        showUniversalLoadingIndictorView(view: view, blurView: blurView, activityIndicatorView: activityIndicatorView,label:label, show: true,loadingText: withText)
    }

    func stopLoadingIndicator(view:UIView,blurView:UIView ,activityIndicatorView:UIActivityIndicatorView,label:UILabel) {
        showUniversalLoadingIndictorView(view: view, blurView: blurView, activityIndicatorView: activityIndicatorView,label:label, show: false)
      }
    
    
    func makeLoadingIndicatorView(view:UIView,blurView:UIView ,activityIndicatorView:UIActivityIndicatorView,label: UILabel,loadingText text: String?,isShow: Bool) -> UIView? {
        let loadingView = blurView
        if isShow {
            loadingView.backgroundColor = .clear
            activityIndicatorView.layer.cornerRadius = 6
            activityIndicatorView.center = loadingView.center
            activityIndicatorView.hidesWhenStopped = true
            if #available(iOS 13.0, *) {
                activityIndicatorView.style = .large
            } else {
                activityIndicatorView.style = .gray
                // Fallback on earlier versions
            }
            activityIndicatorView.color = .gray
            activityIndicatorView.startAnimating()
            loadingView.addSubview(activityIndicatorView)
        }
        let cpoint = CGPoint(x: activityIndicatorView.frame.origin.x + activityIndicatorView.frame.size.width / 2, y: activityIndicatorView.frame.origin.y + 40)
        if !text!.isEmpty {
            label.center = cpoint
            label.textColor = UIColor.white
            label.textAlignment = .center
            label.numberOfLines = 0
            label.text = ""
            label.text = text
            loadingView.addSubview(label)
        } else {
            label.text = ""
            label.center = cpoint
            label.textColor = UIColor.white
            label.removeFromSuperview()
        }
        return loadingView
    }
    
    func showUniversalLoadingIndictorView(view: UIView,blurView:UIView ,activityIndicatorView:UIActivityIndicatorView,label:UILabel,show: Bool, loadingText:String = "") {
        
        if show {
            let loadingView = makeLoadingIndicatorView(view: view, blurView:blurView ,activityIndicatorView:activityIndicatorView, label: label,loadingText: loadingText, isShow: show)
            view.addSubview(loadingView ?? UIView())
        } else {
            let loadingView = makeLoadingIndicatorView(view: view, blurView:blurView ,activityIndicatorView:activityIndicatorView, label: label,loadingText: "", isShow: show)
            view.addSubview(loadingView ?? UIView())
            blurView.removeFromSuperview()
            activityIndicatorView.stopAnimating()
        }

    }
}




protocol CustomTextFieldDelegate: UITextFieldDelegate {
    func textField(_ textField: UITextField, didDeleteBackwardAnd wasEmpty: Bool)
}

class CustomTextField: UITextField {
    override func deleteBackward() {
        // see if text was empty
        let wasEmpty = text == nil || text! == ""

        // then perform normal behavior
        super.deleteBackward()

        // now, notify delegate (if existent)
        (delegate as? CustomTextFieldDelegate)?.textField(self, didDeleteBackwardAnd: wasEmpty)
    }
}

extension UILabel {
    func setImage(image: UIImage, with text: String) {
      let attachment = NSTextAttachment()
      attachment.image = image
      attachment.bounds = CGRect(x: 0, y: 0, width: 40, height: 30)
      let attachmentStr = NSAttributedString(attachment: attachment)

      let mutableAttributedString = NSMutableAttributedString()
      mutableAttributedString.append(attachmentStr)

      let textString = NSAttributedString(string: text, attributes: [.font: self.font])
      mutableAttributedString.append(textString)

      self.attributedText = mutableAttributedString
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

extension UIImageView {
    func makeRounded() {
        let radius = self.frame.width/2.0
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }

    func loadFlyImage(imageURL: String, name: String, chatType: ChatType = .singleChat, uniqueId: String = "", contactType : ContactType = .unknown,jid: String, isBlockedByAdmin: Bool = false, validateBlock: Bool = true){
        let urlString = FlyDefaults.baseURL + "media/" + imageURL + "?mf=" + FlyDefaults.authtoken
        var url = URL(string: urlString)
        var placeholder : UIImage?
        if validateBlock {
            switch chatType {
            case .groupChat:
                placeholder = UIImage(named: "smallGroupPlaceHolder")
            default:
                if uniqueId == FlyDefaults.myJid || contactType == .unknown || getIsBlockedByMe(jid: jid) || isBlockedByAdmin {
                    placeholder = UIImage(named: "ic_profile_placeholder")
                } else {
                    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    let ipimage = IPImage(text: trimmedName, radius: Double(self.frame.size.height), font: UIFont.font32px_appBold(),
                                          textColor: nil, color: Utility.getColorForUser(userName: name))
                    placeholder = ipimage.generateInitialImage()
                    self.backgroundColor = Utility.getColorForUser(userName: name)
                }
            }
        } else {
            switch chatType {
            case .groupChat:
                placeholder = UIImage(named: "smallGroupPlaceHolder")
            default:
                if uniqueId == FlyDefaults.myJid || getIsBlockedByMe(jid: jid) || isBlockedByAdmin {
                    placeholder = UIImage(named: "ic_profile_placeholder")
                } else {
                    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    let ipimage = IPImage(text: trimmedName, radius: Double(self.frame.size.height), font: UIFont.font32px_appBold(),
                                          textColor: nil, color: Utility.getColorForUser(userName: name))
                    placeholder = ipimage.generateInitialImage()
                    self.backgroundColor = Utility.getColorForUser(userName: name)
                }
            }
        }
        if contactType == .deleted || getIsBlockedByMe(jid: jid) {
            placeholder = UIImage(named: "ic_profile_placeholder")
        }

        if isBlockedByAdmin {
            url = URL(string: "")
        }

        self.sd_setImage(with: url, placeholderImage: placeholder, options: [.continueInBackground,.decodeFirstFrameOnly,.highPriority,.scaleDownLargeImages], progress: nil){ (image, responseError, isFromCache, imageUrl) in
            if let error =  responseError as? NSError{
                if let errorCode = error.userInfo[SDWebImageErrorDownloadStatusCodeKey] as? Int {
                    if errorCode == 401{
                        ChatManager.refreshToken { [weak self] isSuccess, error, data in
                            if isSuccess{
                                self?.loadFlyImage(imageURL: imageURL, name: name, chatType : chatType, jid: jid)
                            }else{
                                self?.image = placeholder
                            }
                        }
                    }else{
                        self.image = placeholder
                    }
                }
            }else{
                self.image = image
            }
        }
    }

    private func getIsBlockedByMe(jid: String) -> Bool {
        return ChatManager.getContact(jid: jid)?.isBlockedMe ?? false
    }
}

public class IPImage: NSObject {

    //MARK: - Properties
    /**
     Input text. The first letter from the first and last word (depending on number of words) will be text at the center of the image.
    */
    public var text:String = ""

    private var _radius:Double = 0
    private var _length:Double = 0

    /**
     Radius of the circular image
    */
    public var radius:Double {
        get {
            return _radius
        }
        set {
            _radius = newValue
            _length = _radius * 2
        }
    }

    /**
     Font for the text.

     If it is not initialized before `generateImage()`, it will be assigned with a value:

         UIFont.systemFont(ofSize: CGFloat(radius))
    */
    public var font:UIFont?

    /**
     Color for the text.

     If it is not initialized before `generateImage()`, it will default to `UIColor.white`
     */
    public var textColor:UIColor?

    /**
     Fill color of the circular image.

     If it is not initialized before `generateImage()`, it will default to `UIColor.gray`
     */
    public var backgroundColor:UIColor?

    //MARK: - Initailization
    /**
     Initialize an IPImage object. The default value of `radius` is 25. `text` is empty.
    */
    public convenience override init() {
        self.init(text: "", radius: 25)
    }

    /**
     Initialize an IPImage object.

     - Parameters:
         - text: Source of the initials
         - radius: Circular image radius
     */
    public convenience init(text: String, radius: Double) {
        self.init(text: text, radius: radius, font: nil)
    }

    /**
     Initialize an IPImage object.

     - Parameters:
         - text: Source of the initials
         - radius: Circular image radius
         - font: Font for the text at the center
     */
    public convenience init(text: String, radius: Double, font: UIFont?) {
        self.init(text: text, radius: radius, font: font, textColor: nil, randomBackgroundColor: false)
    }

    /**
     Initialize an IPImage object.

     - Parameters:
         - text: Source of the initials
         - radius: Circular image radius
         - textColor: Color of the text at the center
         - randomBackgroundColor: Randomized fill color
     */
    public init(text: String, radius: Double, font: UIFont?, textColor: UIColor?, randomBackgroundColor: Bool) {
        super.init()

        self.text = text
        self.radius = radius
        self.textColor = textColor ?? .white
        if randomBackgroundColor {
        self.backgroundColor = randomBackgroundColor ? self.randomColor() : .gray
        }else{
        self.backgroundColor = ShareKitColor.primaryAppColor
        }
        if let aFont = font {
            if aFont.pointSize > CGFloat(radius) {
                self.font = UIFont(name: aFont.fontName, size: CGFloat(radius))
            } else {
                self.font = font
            }
        } else {
            self.font = UIFont.systemFont(ofSize: CGFloat(radius))
        }

    }

    public init(text: String, radius: Double, font: UIFont?, textColor: UIColor?, color: UIColor) {
        super.init()

        self.text = text
        self.radius = radius
        self.textColor = textColor ?? .white
        self.backgroundColor = color
        if let aFont = font {
            if aFont.pointSize > CGFloat(radius) {
                self.font = UIFont(name: aFont.fontName, size: CGFloat(radius))
            } else {
                self.font = font
            }
        } else {
            self.font = UIFont.systemFont(ofSize: CGFloat(radius))
        }

    }

    /**
     Initialize an IPImage object.

     - Parameters:
         - text: Source of the initials
         - radius: Circular image radius
         - textColor: Color of the text at the center
         - backgroundColor: Randomized fill color
     */
    public init(text: String, radius: Double, font: UIFont?, textColor: UIColor?, backgroundColor: UIColor?) {
        super.init()

        self.text = text
        self.radius = radius
        self.textColor = textColor ?? .white
      //  self.backgroundColor = backgroundColor ?? .lightGray
        self.backgroundColor = ShareKitColor.primaryAppColor

        if let aFont = font {
            if aFont.pointSize > CGFloat(radius) {
                self.font = UIFont(name: aFont.fontName, size: CGFloat(radius))
            } else {
                self.font = font
            }
        } else {
            self.font = UIFont.systemFont(ofSize: CGFloat(radius))
        }

    }

    //MARK: - Private
    private func randomColor() -> UIColor {

        let red = CGFloat(arc4random_uniform(256))/255.0
        let green = CGFloat(arc4random_uniform(256))/255.0
        let blue = CGFloat(arc4random_uniform(256))/255.0

        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)

    }

    private func setupView() -> UIView {

        let view = UIView(frame: CGRect(x: 0, y: 0, width: _length, height: _length))
        view.backgroundColor = backgroundColor
        view.addSubview(setupLabel())
        rounded(view: view)

        return view
    }

    private func setupSquareView() -> UIView {

        let view = UIView(frame: CGRect(x: 0, y: 0, width: _length, height: _length))
        view.backgroundColor = backgroundColor
        view.addSubview(setupLabel())
        return view
    }

    private func setupLabel() -> UILabel {

        let label = UILabel(frame: CGRect(x: 0, y: 0, width: _length, height: _length))
        label.text = initials()
        label.font = font
        label.textColor = textColor
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.1
        label.allowsDefaultTighteningForTruncation = true
        return label

    }

    private func rounded(view: UIView) {

        let width = view.frame.width
        let mask = CAShapeLayer()
        mask.path = UIBezierPath(ovalIn: CGRect(x: view.bounds.midX - width / 2, y: view.bounds.midY - width / 2, width: width, height: width)).cgPath
        view.layer.mask = mask

//        //TESTING
//        view.layer.shouldRasterize = true
//        view.layer.rasterizationScale = UIScreen.main.scale

    }

    //MARK: - Text Generation

    /**
     Generates the initials from the value of `text`. For example:

         text = "Harry"

     the result will be: **H**. If:

         text = "Harry Potter"

     the result will be: **HP**. And, if:

         text = "Harry Potter Jr."

     the result will be **HJ**.


     - Returns: String which is one or two charaters long depending on the number of words in `text`.
    */
    public func initials() -> String {

        let names = text.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ")

        if names.count > 1 {

            let firstName = names[0]
            var lastName = names[1]

            if lastName.isEmpty {
                lastName = firstName
            }

            let firstNameInitial = firstName.substring(to: firstName.index(after: firstName.startIndex)).uppercased()
            var lastNameInitial: String? = ""
            if lastName.trim().count > 0 {
                lastNameInitial = lastName.substring(to: lastName.index(after: lastName.startIndex)).uppercased()
            }

            return (firstNameInitial + (lastNameInitial ?? ""))


        } else {

            if text == "" {
                return ""
            }

            let firstName = text
            let firstNameInitial = firstName.prefix(2).uppercased()
            print("letterone")
            print(firstNameInitial)
            return firstNameInitial
        }

    }

    //MARK: - Image Generation

    /**
     Call to generate the resulting image.

     - Returns: Circular image
    */
    public func generateImage() -> UIImage? {

        let view = setupView()

        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0.0)
      view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
//        print(image ?? "No image")
        return image
    }

    public func generateInitialImage() -> UIImage? {
        let view = setupView()
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0.0)
        if let graphicsContext = UIGraphicsGetCurrentContext(){
            view.layer.render(in: graphicsContext)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        }
        return nil

    }

    public func generateInitialSqareImage() -> UIImage? {
            let view = setupSquareView()
            UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0.0)
            view.layer.render(in: UIGraphicsGetCurrentContext()!)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
    }
}

extension UILabel {
    private struct AssociatedKeys {
        static var padding = UIEdgeInsets()
    }

    public var padding: UIEdgeInsets? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.padding) as? UIEdgeInsets
        }
        set {
            if let newValue = newValue {
                objc_setAssociatedObject(self, &AssociatedKeys.padding, newValue as UIEdgeInsets?, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }

    override open func draw(_ rect: CGRect) {
        if let insets = padding {
            self.drawText(in: rect.inset(by: insets))
        } else {
            self.drawText(in: rect)
        }
    }

    override open var intrinsicContentSize: CGSize {
        guard let text = self.text else { return super.intrinsicContentSize }

        var contentSize = super.intrinsicContentSize
        var textWidth: CGFloat = frame.size.width
        var insetsHeight: CGFloat = 0.0
        var insetsWidth: CGFloat = 0.0

        if let insets = padding {
            insetsWidth += insets.left + insets.right
            insetsHeight += insets.top + insets.bottom
            textWidth -= insetsWidth
        }

        let newSize = text.boundingRect(with: CGSize(width: textWidth, height: CGFloat.greatestFiniteMagnitude),
                                        options: NSStringDrawingOptions.usesLineFragmentOrigin,
                                        attributes: [NSAttributedString.Key.font: self.font], context: nil)

        contentSize.height = ceil(newSize.size.height) + insetsHeight
        contentSize.width = ceil(newSize.size.width) + insetsWidth

        return contentSize
    }
}

extension UIView {
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
}

extension Data {
    func getSizeInMB() -> Double {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useMB]
        bcf.countStyle = .file
        let string = bcf.string(fromByteCount: Int64(self.count)).replacingOccurrences(of: ",", with: ".")
        if let double = Double(string.replacingOccurrences(of: " MB", with: "")) {
            return double
        }
        return 0.0
    }
}
