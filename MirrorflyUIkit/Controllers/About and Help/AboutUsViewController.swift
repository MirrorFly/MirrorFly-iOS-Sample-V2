//
//  AboutUsViewController.swift
//  MirrorflyUIkit
//
//  Created by user on 01/03/22.
//

import UIKit

class AboutUsViewController: UIViewController {

    @IBOutlet weak var btnContuctus: UIButton!
    @IBOutlet weak var lblaboutContent: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.lblaboutContent.font = AppFont.Regular.size(14)
        
        self.lblaboutContent.text = """
We Must Meet is an internationally available instant messaging (IM) and voice-over-IP (VoIP) service backed by Fintech Power Corp.

We Must Meet allows users to send text messages and voice messages, make voice and video calls, and share images, documents, user locations, and other content.

We Must Meet client application runs on mobile devices. The service requires a cellular mobile telephone number to sign up.

We Must Meet Calling lets you speak privately to your friends and family, even if they're in another country.

All your messages are end-to-end encrypted in We Must Meet.
"""
        
        self.btnContuctus.setTitle("Business@wemustmeet.app", for: .normal)
        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    @IBAction func onTapBack(_ sender: UIButton){
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func btncontuctus(_ sender: UIButton) {
        
        if let titleString = btnContuctus.currentTitle {
            if self.ValidEmail(email: titleString){
                if let url = URL(string: "mailto:\(titleString)") {
                  if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url)
                  } else {
                    UIApplication.shared.openURL(url)
                  }
                }
            }else if titleString.isURL {
                if let url = URL(string:titleString) {
                  if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url)
                  } else {
                    UIApplication.shared.openURL(url)
                  }
                }
            }
        }
    }
    
    func ValidEmail(email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
