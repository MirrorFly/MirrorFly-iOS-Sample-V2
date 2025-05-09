//
//  AddPeopleOrGroupController.swift
//  UiKitQa
//
//  Created by MohanRaj on 10/02/23.
//

import UIKit
import MirrorFlySDK

protocol AddPeopleOrGroupDelegate {
    func selectedPeopleOrGroup(people: [RecentChat])
}

class AddPeopleOrGroupController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var usersListCollectionView: UICollectionView!
    @IBOutlet weak var recentTable: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var addButton: UIButton!
    
    @IBOutlet weak var noResultLable: UILabel!
    private var recentChatViewModel: RecentChatViewModel?
    var getRecentChat: [RecentChat] = []
    var getAllRecentChat: [RecentChat] = []
    var getSelectedChat: [RecentChat] = []
    var randomColors = [UIColor?]()
    var isSearchEnabled: Bool = false
    public var delegate: AddPeopleOrGroupDelegate?
    public var isFromUpdateTag: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = (isFromUpdateTag) ? "Edit Tag" : "Create Tag"
        recentChatViewModel = RecentChatViewModel()
        usersListCollectionView.isHidden = (getSelectedChat.count > 0) ? false : true
        addButton.backgroundColor = (getSelectedChat.count > 0) ? Color.color_3276E2 : Color.resendButtonDisable
        addButton.isUserInteractionEnabled = (getSelectedChat.count > 0) ? true : false
        configTableView()
        getRecentChatList()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        GroupManager.shared.groupDelegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        GroupManager.shared.groupDelegate = nil
    }
    
    // MARK: ConfigTableView
    private func configTableView() {
        searchBar?.delegate = self
        recentTable?.rowHeight = UITableView.automaticDimension
        recentTable?.estimatedRowHeight = 130
        recentTable?.delegate = self
        recentTable?.dataSource = self
        recentTable.keyboardDismissMode = .onDrag
        recentTable?.separatorStyle = .none
        let nib = UINib(nibName: "UserListCell", bundle: .main)
        recentTable?.register(nib, forCellReuseIdentifier: "UserListCell")
        if let tv = recentTable{
            tv.contentSize = CGSize(width: tv.frame.size.width, height: tv.contentSize.height);
        }
        
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: 60, height: 60)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .horizontal
        usersListCollectionView?.collectionViewLayout = layout
        usersListCollectionView?.delegate = self
        usersListCollectionView?.dataSource = self
        usersListCollectionView.showsHorizontalScrollIndicator = false
        
    }

    @IBAction func backButtonAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func addButtonAction(_ sender: UIButton) {
        
        delegate?.selectedPeopleOrGroup(people: getSelectedChat)
        self.navigationController?.popViewController(animated: true)
    }
    
    func getRecentChatList() {
        
        recentChatViewModel?.getRecentChatList(isBackground: false, completionHandler: { [weak self] recentChatList in
            if let weakSelf = self {
                weakSelf.getRecentChat = recentChatList?.filter({$0.isBlockedByAdmin == false}).filter({$0.isDeletedUser == false}) ?? []
                weakSelf.getAllRecentChat = weakSelf.getRecentChat

                print(weakSelf.getAllRecentChat)
                
                
                weakSelf.getSelectedChat.enumerated().forEach({ (index,item) in
                    
                    weakSelf.getAllRecentChat.filter({$0.jid == item.jid}).first?.isSelected = true
                    weakSelf.getRecentChat.filter({$0.jid == item.jid}).first?.isSelected = true
                })
               
                
            }
        })
        
        randomColors = AppUtils.shared.setRandomColors(totalCount: getAllRecentChat.count)
        recentTable.reloadData()
    }
}

// TableViewDelegate
extension AddPeopleOrGroupController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rowCount = isSearchEnabled == true ? getRecentChat.count : getAllRecentChat.count
        tableView.isHidden = (rowCount == 0) ? true : false
        return rowCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let cell = (tableView.dequeueReusableCell(withIdentifier: "UserListCell", for: indexPath) as? UserListCell) {
            
            let recentChatDetails = isSearchEnabled == true ? getRecentChat[indexPath.row] : getAllRecentChat[indexPath.row]
            cell.contentView.alpha = getBlocked(jid: recentChatDetails.jid) ? 0.6 : 1.0
            
            let hashcode = recentChatDetails.profileName.hashValue
            let color = randomColors[abs(hashcode) % randomColors.count]
            cell.setUserListDetails(recentChat: recentChatDetails, color: color ?? .gray)
            cell.subTitleLabel.isHidden = true
            cell.contentView.backgroundColor = .white
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      
        let recentChatDetails = isSearchEnabled == true ? getRecentChat[indexPath.row] : getAllRecentChat[indexPath.row]
        
        if isSearchEnabled {
            
            if  getRecentChat[indexPath.row].isSelected {
                
                getRecentChat[indexPath.row].isSelected = false
                
                getAllRecentChat.filter({$0.jid == recentChatDetails.jid}).first?.isSelected = false
                
                getSelectedChat.enumerated().forEach({ (index,item) in
                    if item.jid == getRecentChat[indexPath.row].jid {
                        if index <= getSelectedChat.count {
                            getSelectedChat.remove(at: index)
                        }
                    }
                })
                
            } else{
                getRecentChat[indexPath.row].isSelected = true
                getAllRecentChat.filter({$0.jid == recentChatDetails.jid}).first?.isSelected = true
                getSelectedChat.append(getRecentChat[indexPath.row])
            }
            
        } else {
            
            if  getAllRecentChat[indexPath.row].isSelected {
                
                getAllRecentChat[indexPath.row].isSelected = false
                getRecentChat.filter({$0.jid == recentChatDetails.jid}).first?.isSelected = false
                
                getSelectedChat.enumerated().forEach({ (index,item) in
                    if item.jid == getAllRecentChat[indexPath.row].jid {
                        if index <= getSelectedChat.count {
                            getSelectedChat.remove(at: index)
                        }
                    }
                })
                
            } else{
                getAllRecentChat[indexPath.row].isSelected = true
                getRecentChat.filter({$0.jid == recentChatDetails.jid}).first?.isSelected = true
                getSelectedChat.append(getAllRecentChat[indexPath.row])
            }
        }
        
        recentTable?.reloadRows(at: [indexPath], with: .none)
        addButton.backgroundColor = (getSelectedChat.count > 0) ? Color.color_3276E2 : Color.resendButtonDisable
        addButton.isUserInteractionEnabled = (getSelectedChat.count > 0) ? true : false
        usersListCollectionView.isHidden = (getSelectedChat.count > 0) ? false : true
        usersListCollectionView.reloadData()
        
    }
    
    private func getBlocked(jid: String) -> Bool {
        return ChatManager.getContact(jid: jid)?.isBlocked ?? false
    }
}

// CollectionViewDelegate
extension AddPeopleOrGroupController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return getSelectedChat.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SelectedUserCollectionCell", for: indexPath) as! SelectedUserCollectionCell
        cell.profileImage.backgroundColor = .green
        
       let recentChat = getSelectedChat[indexPath.item]
        print(profile)

        let hashcode = recentChat.profileName.hashValue
        
        let name = getUserName(jid: recentChat.jid,name: recentChat.profileName , nickName: recentChat.nickName, contactType: (recentChat.isDeletedUser ? .deleted :  recentChat.isItSavedContact ? .live : .unknown))
        let color = randomColors[abs(hashcode) % randomColors.count]
        cell.setImage(imageURL: recentChat.profileImage ?? "", name: name, color: color ?? .gray , recentChat: recentChat)
       
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
            return CGSize(width: 60, height: 60)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    
        if  getSelectedChat[indexPath.item].isSelected {
            let selectedUser =  getSelectedChat[indexPath.item]

            getAllRecentChat.enumerated().forEach({ (index,item) in
                if item.jid == selectedUser.jid {
                    if index <= getAllRecentChat.count {
                        getAllRecentChat[index].isSelected = false
                        getSelectedChat.remove(at: indexPath.item)
                    }

                }
            })
            
            usersListCollectionView.isHidden = (getSelectedChat.count > 0) ? false : true
            addButton.backgroundColor = (getSelectedChat.count > 0) ? Color.color_3276E2 : Color.resendButtonDisable
            addButton.isUserInteractionEnabled = (getSelectedChat.count > 0) ? true : false
            usersListCollectionView?.reloadData()
            recentTable?.reloadData()

        }
    }
    
    func getUserName(jid : String, name : String , nickName : String, contactType : ContactType) -> String {
        FlyUtils.getUserName(jid: jid, name: name, nickName: nickName, contactType: contactType)
    }
    
}


// SearchBar Delegate Method
extension AddPeopleOrGroupController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        print("#Search \(searchText)")
        if searchText.trim().count > 0 {
            isSearchEnabled = true
            getRecentChat = searchText.isEmpty ? getAllRecentChat : getAllRecentChat.filter({ recentChat -> Bool in
                let name = getUserName(jid: recentChat.jid,name: recentChat.profileName , nickName: recentChat.nickName, contactType: (recentChat.isDeletedUser ? .deleted :  recentChat.isItSavedContact ? .live : .unknown))
                return (name.capitalized.range(of: searchText.trim().capitalized, options: [.caseInsensitive, .diacriticInsensitive]) != nil && recentChat.isDeletedUser == false) ||
                (recentChat.lastMessageContent.capitalized.range(of: searchText.trim().capitalized, options: [.caseInsensitive, .diacriticInsensitive]) != nil && recentChat.isDeletedUser == false)
            })
            
        }else {
            isSearchEnabled = false
        }
        recentTable?.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearchEnabled = false
        searchBar.text = ""
        recentTable?.reloadData()
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
}

extension AddPeopleOrGroupController : GroupEventsDelegate {
    func didAddNewMemeberToGroup(groupJid: String, newMemberJid: String, addedByMemberJid: String) {
        
    }
    
    func didRemoveMemberFromGroup(groupJid: String, removedMemberJid: String, removedByMemberJid: String) {
        
    }
    
    func didFetchGroupProfile(groupJid: String) {
        
    }
    
    func didUpdateGroupProfile(groupJid: String) {
        
    }
    
    func didMakeMemberAsAdmin(groupJid: String, newAdminMemberJid: String, madeByMemberJid: String) {
        
    }
    
    func didRevokedAdminAccess(groupJid: String, revokedAdminMemberJid: String, revokedByMemberJid: String) {
        
    }
    
    func didDeleteGroupLocally(groupJid: String) {
        
    }
    
    func didLeftFromGroup(groupJid: String, leftUserJid: String) {
        
    }
    
    func didCreateGroup(groupJid: String) {
        
    }
    
    func didFetchGroups(groups: [MirrorFlySDK.ProfileDetails]) {
        
    }
    
    func didFetchGroupMembers(groupJid: String) {
        
    }
    
    func didReceiveGroupNotificationMessage(message: MirrorFlySDK.ChatMessage) {
        
    }
    
    func didSuperAdminDeleteGroup(groupJid: String, groupName: String) {
        deleteGroupChat(groupJid)
    }
    
    
}

extension AddPeopleOrGroupController {
    func deleteGroupChat(_ groupJid: String) {
        DispatchQueue.main.async { [weak self] in
            self?.getRecentChat = self?.getRecentChat.filter({ $0.jid != groupJid}) ?? []
            self?.getAllRecentChat = self?.getAllRecentChat.filter({ $0.jid != groupJid}) ?? []
            self?.getSelectedChat = self?.getSelectedChat.filter({ $0.jid != groupJid}) ?? []
            self?.usersListCollectionView?.reloadData()
            self?.recentTable.reloadData()
        }
    }
}
