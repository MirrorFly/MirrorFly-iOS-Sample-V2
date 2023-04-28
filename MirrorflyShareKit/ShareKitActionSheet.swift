//
//  ShareKitActionSheet.swift
//  MirrorflyUIkit
//
//  Created by John on 20/02/23.
//

//
//  AppActionSheet.swift
//  MirrorflyUIkit
//
//  Created by John on 22/11/21.
//

import Foundation
import UIKit


class ShareKitActionSheet : NSObject {
    
    public typealias SheetCallBack = (_ didCancelTap: Bool,_ tappedOption: String) -> Void
    
    var alertController: UIAlertController?
    
    public static let shared : ShareKitActionSheet =  {
        return ShareKitActionSheet()
    }()
    
    func showActionSeet(view : UIViewController, title : String, message : String, showCancel: Bool = true, actions: [(String, UIAlertAction.Style)], titleBold : Bool = false , style: UIAlertController.Style = .actionSheet, sheetCallBack : @escaping SheetCallBack) {
        
        let mTitle = title.isEmpty ? nil : title
        let mMessage = message.isEmpty ? nil : message
        
        if !actions.isEmpty {
            alertController = UIAlertController(title: mTitle, message: mMessage, preferredStyle: style)
            
            if let mTitle = mTitle, mTitle.isNotEmpty, titleBold {
                
                let attributedString = NSAttributedString(string: mTitle, attributes: [
                    NSAttributedString.Key.font : UIFont.font18px_appSemibold(), //your font here
                    NSAttributedString.Key.foregroundColor : UIColor.blue,
                ])
                alertController?.setValue(attributedString, forKey: "attributedTitle")
            }
            
            for (title, style) in actions {
                let alertAction = UIAlertAction(title: title, style: style) { (action) -> Void in
                    sheetCallBack(false, title)
                }
                if style != .destructive {
                    alertAction.setValue(ShareKitColor.color_3276E2!, forKey: "titleTextColor")
                }
                alertController?.addAction(alertAction)
            }
            if showCancel {
                let cancel = UIAlertAction(title: cancelUppercase, style: .cancel, handler: { (action) -> Void in
                    sheetCallBack(true, cancelUppercase)
                })
                cancel.setValue(ShareKitColor.color_3276E2!, forKey: "titleTextColor")
                alertController?.addAction(cancel)
            }
            view.present(alertController ?? UIAlertController(), animated: true, completion: nil)
        }
    }
    
    func dismissActionSeet(animated: Bool) {
        if let alert = alertController {
            alert.dismiss(animated: animated)
            alertController = nil
        }
    }
}

