//
//  ActivityIndicatorClass.swift
//  TabbarTest
//
//  Created by User on 16/08/21.
//

import Foundation
import UIKit
extension UIViewController {

    static let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()

    func startLoading(withText: String) {
        UIViewController.showUniversalLoadingView(true, loadingText: withText)
    }

    func stopLoading() {
        UIViewController.showUniversalLoadingView(false)
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
    
    class func showUniversalLoadingView(_ show: Bool, loadingText : String = "") {
        let existingView = UIApplication.shared.windows[0].viewWithTag(1200)
        if show {
            if existingView != nil {
                return
            }
            let loadingView = self.makeLoadingView(withFrame: UIScreen.main.bounds, loadingText: loadingText)
            loadingView?.tag = 1200
            UIApplication.shared.windows[0].addSubview(loadingView!)
        } else {
            existingView?.removeFromSuperview()
        }

    }

}
