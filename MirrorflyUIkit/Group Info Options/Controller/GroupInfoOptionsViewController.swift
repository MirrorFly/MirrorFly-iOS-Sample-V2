//
//  GroupInfoOptionsViewController.swift
//  MirrorflyUIkit
//
//  Created by Prabakaran M on 10/03/22.
//

import UIKit
import MirrorFlySDK

class GroupInfoOptions {
    
    var title: String?
    
    init(title: String?) {
        self.title = title
    }
}

protocol GroupInfoOptionsDelegate: AnyObject {
    func makeGroupAdmin(groupID: String, userJid: String, userName: String)
    func removeGroupAdmin(groupID: String, userJid: String, userName: String)
    func removeParticipant(groupID: String, removeGroupMemberJid: String, userName: String)
    func navigateToUserProfile(userJid: String)
    func navigateToChat(userJid: String)
}

class GroupInfoOptionsViewController: UIViewController {
    
    // MARK: - Properties
    
    @IBOutlet weak var baseView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var baseViewHeightConstraint: NSLayoutConstraint!
    
    var groupInfoViewController: GroupInfoViewController!
    
    let groupInfoViewModel = GroupInfoViewModel()
    var groupMembers = [GroupParticipantDetail]()
    var profileDetails : ProfileDetails?
    weak var delegate: GroupInfoOptionsDelegate? = nil
    
    var groupID = ""
    var userJid = ""
    var userName = ""
    var isAdminMember: Bool = false
    var participantIsAdminMember: Bool = false
    
    var groupInfoOptionsArray = [GroupInfoOptions(title: startChat),
                                 GroupInfoOptions(title: viewInfo),
                                 GroupInfoOptions(title: removeFromGroup),
                                 GroupInfoOptions(title: makeAdminText)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isAdminMemberGroup()
        setUpUI()
        hideViewWhenTappedAround()
    }
    
    private func setUpUI() {
        setUpStatusBar()
        navigationController?.navigationBar.isHidden = true
        baseView.layer.cornerRadius = 8
        baseView.layer.masksToBounds =  false
        baseView.clipsToBounds = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = false
        
        tableView?.register(UINib(nibName: Identifiers.groupInfoOptionsTableViewCell, bundle: .main),
                            forCellReuseIdentifier: Identifiers.groupInfoOptionsTableViewCell)
        
        if isAdminMember == true && participantIsAdminMember == true {
            baseViewHeightConstraint.constant = 140
        } else if isAdminMember == true {
            baseViewHeightConstraint.constant = 180
        } else {
            baseViewHeightConstraint.constant = 100
        }
    }
    
    // MARK: - User Interactions
    
    func hideViewWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(GroupInfoOptionsViewController.dismissView))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc
    func dismissView() {
        view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Public Method
    
    private func refreshData() {
        tableView?.reloadData()
    }
    
    func isAdminMemberGroup() {
        
        let isAdminMember = self.groupInfoViewModel.isGroupAdminMember(participantJid: userJid,
                                                                       groupJid: groupID)
        
        self.participantIsAdminMember = isAdminMember.isAdmin
        
    }
}

extension GroupInfoOptionsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupInfoOptionsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.groupInfoOptionsTableViewCell, for: indexPath) as? GroupInfoOptionsTableViewCell)!
        cell.titleLabel.text = groupInfoOptionsArray[indexPath.row].title
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if userJid != AppUtils.getMyJid() {
            if indexPath.row == 0 {
                self.delegate?.navigateToChat(userJid: userJid)
                dismiss(animated: true, completion: nil)
                
            } else if indexPath.row == 1 {
                self.delegate?.navigateToUserProfile(userJid: userJid)
                dismiss(animated: true, completion: nil)
                
            } else if indexPath.row == 2 {
                self.delegate?.removeParticipant(groupID: groupID,
                                                 removeGroupMemberJid: userJid,
                                                 userName: userName )

                
            } else if indexPath.row == 3 {
                self.delegate?.makeGroupAdmin(groupID: groupID, userJid: userJid, userName: userName)
            }
        }
    }
}
