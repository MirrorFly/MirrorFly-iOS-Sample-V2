//
//  AboutandHelpViewController.swift
//  MirrorflyUIkit
//
//  Created by user on 28/02/22.
//

import UIKit

class AboutandHelpViewController: UIViewController{

    @IBOutlet weak var tblAboutAndHelp: UITableView!
    
    private var privacyArr = ["About us","Contact Us","Terms and Conditions","Privacy Policy"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tblAboutAndHelp.register(UINib(nibName: "PrivacyHelpTableViewCell", bundle: nil), forCellReuseIdentifier: "PrivacyHelpTableViewCell")
        self.tblAboutAndHelp.delegate = self
        self.tblAboutAndHelp.dataSource = self
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    @IBAction func onTapBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
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

extension AboutandHelpViewController : UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.privacyArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : PrivacyHelpTableViewCell = tableView.dequeueReusableCell(withIdentifier: "PrivacyHelpTableViewCell", for: indexPath) as! PrivacyHelpTableViewCell
        cell.lblTitle.text = self.privacyArr[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch self.privacyArr[indexPath.row] {
        case "About us":
            goToWebView(title: self.privacyArr[indexPath.row] , url: TermsAndConditionsUrl.aboutUs)
            break
        case "Contact Us":
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ContactUsController") as? ContactUsController {
                self.navigationController?.pushViewController(vc, animated: true)
            }
            
            break
        case "Terms and Conditions":
            goToWebView(title: self.privacyArr[indexPath.row] , url: TermsAndConditionsUrl.termsAndConditions)
            break
        case "Privacy Policy":
            goToWebView(title: self.privacyArr[indexPath.row] , url: TermsAndConditionsUrl.privacyPolicy)
            break
            
        default:
            break
        }

    }
    
    private func goToWebView(title : String, url : String) {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CommonWebViewController") as? CommonWebViewController {
            vc.titleString = title
            vc.urlString = url
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
