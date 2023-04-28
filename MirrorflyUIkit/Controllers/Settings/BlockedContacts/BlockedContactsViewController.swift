//
//  BlockedContactsViewController.swift
//  UiKitQa
//
//  Created by Amose Vasanth on 24/11/22.
//

import UIKit
import MirrorFlySDK

class BlockedContactsViewController: UIViewController {


    @IBOutlet weak var blockedContactsTableView: UITableView! {
        didSet {
            blockedContactsTableView.register(UINib(nibName: "BlockedContactTableViewCell", bundle: nil), forCellReuseIdentifier: "BlockedContactTableViewCell")
        }
    }

    var blockedList = [ProfileDetails]()

    override func viewDidLoad() {
        super.viewDidLoad()
        getBLockedList()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ChatManager.shared.availableFeaturesDelegate = self
        ContactManager.shared.profileDelegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ChatManager.shared.availableFeaturesDelegate = nil
        ContactManager.shared.profileDelegate = nil
    }
    
    

    @IBAction func backAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }

    //MARK: UnBlockUser
    private func unblockUser(contact: ProfileDetails) {
        let name = FlyUtils.getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType)
        BlockUnblockViewModel.unblockUser(jid: contact.jid) { [weak self] isSuccess, error, data in
            if isSuccess {
                self?.blockedList.removeAll { detail in
                    detail.jid == contact.jid
                }
                self?.blockedContactsTableView.reloadData()
                AppAlert.shared.showToast(message: "\(name) has been Unblocked")
            }
        }
    }

    
    public func getBLockedList(){
        ContactManager.shared.getUsersIBlocked(fetchFromServer: false) { [weak self] isSuccess, error, data in
            
            if isSuccess{
                if let blocked = data["data"] as? [ProfileDetails] {
                    self?.blockedList = blocked
                }
                self?.blockedContactsTableView.reloadData()
            } else {
                let message = AppUtils.shared.getErrorMessage(description: error?.description ?? "")
                AppAlert.shared.showAlert(view: self!, title: "" , message: message, buttonTitle: "OK")
                return
            }
        }
    }
    
}

extension BlockedContactsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blockedList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "BlockedContactTableViewCell") as? BlockedContactTableViewCell {
            let contact = blockedList[indexPath.row]
            cell.setupCell(contact: contact)
            return cell
        } else {
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var actions: [(String, UIAlertAction.Style)] = [(ChatActions.unblock.rawValue, .default)]
        let contact = blockedList[indexPath.row]
        AppActionSheet.shared.showActionSeet(title : "", message: "\(ChatActions.unblock.rawValue) \(FlyUtils.getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType))?",actions: actions , sheetCallBack: { [weak self] didCancelTap, tappedTitle in
            if !didCancelTap {
                if let contact = self?.blockedList[indexPath.row] {
                    self?.unblockUser(contact: contact)
                }
            }
        })
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }


}

extension BlockedContactsViewController : AvailableFeaturesDelegate {
    
    func didUpdateAvailableFeatures(features: AvailableFeaturesModel) {
        
        let tabCount =  MainTabBarController.tabBarDelegagte?.currentTabCount()
        
        if (!(features.isGroupCallEnabled || features.isOneToOneCallEnabled) && tabCount == 5) {
            MainTabBarController.tabBarDelegagte?.removeTabAt(index: 2)
        }else {
            
            if ((features.isGroupCallEnabled || features.isOneToOneCallEnabled) && tabCount ?? 0 < 5){
                MainTabBarController.tabBarDelegagte?.resetTabs()
            }
        }
        
        if !features.isBlockEnabled {
            AppActionSheet.shared.dismissActionSeet(animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                AppAlert.shared.showAlert(view: self!, title: "" , message: FlyConstants.ErrorMessage.forbidden, buttonTitle: "OK")
            }
            self.navigationController?.popViewController(animated: true)
        }
    }

}

extension BlockedContactsViewController : ProfileEventsDelegate{
    func userCameOnline(for jid: String) {
        
    }
    
    func userWentOffline(for jid: String) {
        
    }
    
    func userProfileFetched(for jid: String, profileDetails: MirrorFlySDK.ProfileDetails?) {
        
    }
    
    func myProfileUpdated() {
        
    }
    
    func usersProfilesFetched() {
        
    }
    
    func blockedThisUser(jid: String) {
        getBLockedList()
    }
    
    func unblockedThisUser(jid: String) {
        getBLockedList()
    }
    
    func usersIBlockedListFetched(jidList: [String]) {
        getBLockedList()
    }
    
    func usersBlockedMeListFetched(jidList: [String]) {
        
    }
    
    func userUpdatedTheirProfile(for jid: String, profileDetails: MirrorFlySDK.ProfileDetails) {
        
    }
    
    func userBlockedMe(jid: String) {
        
    }
    
    func userUnBlockedMe(jid: String) {
       
    }
    
    func hideUserLastSeen() {
        
    }
    
    func getUserLastSeen() {
        
    }
    
    func userDeletedTheirProfile(for jid: String, profileDetails: MirrorFlySDK.ProfileDetails) {
        
    }
    
    
}
