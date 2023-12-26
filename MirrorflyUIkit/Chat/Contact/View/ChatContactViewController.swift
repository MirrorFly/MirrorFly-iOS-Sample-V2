//
//  ChatContactViewController.swift
//  MirrorflyUIkit
//
//  Created by User on 04/09/21.
//

import UIKit
import Contacts

protocol ContactDelegate : NSObjectProtocol {
    func didSendPressed(contactDetails: ContactDetails,jid: String?)
}

class ChatContactViewController: UIViewController {
    
    @IBOutlet weak var contactTableView: UITableView!
    weak var contactDelegate: ContactDelegate?
    var getContactDetails: [ContactDetails]?
    @IBOutlet weak var contactName: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var contactImage: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        setContactInfo()
        contactTableView.backgroundColor = .white
    }
    
    func setContactInfo(){
        if let name = getContactDetails?[0].contactName {
            contactName.text = name
        }
        
        if let image = getContactDetails?[0].imageData {
            contactImage.makeRounded()
            contactImage.image = UIImage(data: image)
            print("setContactInfo image \(image)")
        }
        
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        sendButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    }
    
    @IBAction func onCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onSend(_ sender: Any) {
        var selectedContactNumber = [String]()
        for i in 0..<(getContactDetails?[0].status.count)!
        {
            let getStatus = getContactDetails?[0].status[i]
            if getStatus == contactSelect{
                selectedContactNumber.append((getContactDetails?[0].contactNumber[i])!)
            }
        }
        print(selectedContactNumber)
        
        if(selectedContactNumber.count > 0) {
            getContactDetails?[0].contactNumber = selectedContactNumber
            contactDelegate?.didSendPressed(contactDetails: (getContactDetails?[0])!, jid: "")
            self.dismiss(animated: true, completion: nil)
        }
        else {
            AppAlert.shared.showToast(message: emptyContact.localized)
        }
        
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

extension ChatContactViewController : UITableViewDataSource ,UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
       return getContactDetails?.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getContactDetails?[section].contactNumber.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell : ChatContactCell
        
        cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.chatContactCell, for: indexPath) as! ChatContactCell
        cell.selectionStyle = .none
        cell.contactNumber.text = getContactDetails?[indexPath.section].contactNumber[indexPath.row]
        if (getContactDetails?[indexPath.section].status[indexPath.row] == contactSelect){
            cell.selectButton.setImage(UIImage.init(named: ImageConstant.ic_checked), for: .normal)
        }else{
            cell.selectButton.setImage(UIImage.init(named: ImageConstant.ic_check_box), for: .normal)
        }
        let contactlabel = getContactDetails?[indexPath.section].contactLabel[indexPath.row]
        cell.contactLabel.text = contactlabel
        cell.contactLabel.isHidden = (contactlabel?.isNotEmpty ?? false) ? false : true
        cell.selectButton.addTarget(self, action: #selector(onContactSelectButton(_:)), for: .touchUpInside)
        cell.selectButton.tag = indexPath.row
        return cell
    }

    @objc func onContactSelectButton(_ sender: UIButton) {
       if getContactDetails?[0].status[sender.tag] == contactSelect{
         getContactDetails?[0].status[sender.tag] = contactUnselect
        }else{
            getContactDetails?[0].status[sender.tag] = contactSelect
        }
        contactTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45
    }
}
