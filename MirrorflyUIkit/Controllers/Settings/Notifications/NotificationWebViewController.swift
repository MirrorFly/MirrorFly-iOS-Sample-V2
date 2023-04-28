//
//  NotificationWebViewController.swift
//  UiKitQa
//
//  Created by Ramakrishnan on 19/10/22.
//

import UIKit
import WebKit

class NotificationWebViewController: UIViewController {

    @IBOutlet weak var WebView: WKWebView!
    override func viewDidLoad() {
        super.viewDidLoad()

        let url = URL (string: "https://app.mirrorfly.com/notifications/")
               let requestObj = URLRequest(url: url!)
               WebView.load(requestObj)
    }
    @IBAction func onTapBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}
