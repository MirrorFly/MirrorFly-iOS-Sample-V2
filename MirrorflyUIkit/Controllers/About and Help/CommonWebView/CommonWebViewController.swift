//
//  CommonWebViewController.swift
//  MirrorflyUIkit
//
//  Created by user on 28/02/22.
//

import UIKit
import WebKit

class CommonWebViewController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var lblHeader: UILabel!
    
    var titleString = ""
    var urlString = ""
    var isTypeUrl : Bool = true
    override func viewDidLoad() {
        super.viewDidLoad()
        self.lblHeader.text = titleString
        if isTypeUrl{
            if let url = URL(string: urlString){
                self.webView.navigationDelegate = self
                let request = URLRequest(url: url)
                DispatchQueue.main.async {
                    self.startLoading(withText: "")
                    self.webView.load(request)
                }
                
            }
        }else {
            self.webView.loadHTMLString(urlString, baseURL: nil)
        }
    }
    
    @IBAction func onTapBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
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

extension CommonWebViewController : WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.stopLoading()
        }
    }
}
