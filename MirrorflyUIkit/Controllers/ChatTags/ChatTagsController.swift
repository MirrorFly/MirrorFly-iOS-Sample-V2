//
//  ChatTagsController.swift
//  MirrorflyUIkit
//
//  Created by MohanRaj on 09/02/23.
//

import UIKit
import MirrorFlySDK

class ChatTagsController: UIViewController {

    @IBOutlet weak var chatTagsTable: UITableView!
    
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var EditButton: UIButton!
    private var chatTagsArray = [ChatTagsModel]()

    var isEditEnabled: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Do any additional setup after loading the view.
        getAllChatTags()
        chatTagsTable.register(UINib(nibName: "ChatTagsHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "ChatTagsHeader")
        chatTagsTable.register(UINib(nibName: "ChatTagsFooterCell", bundle: nil), forHeaderFooterViewReuseIdentifier: "ChatTagsFooterCell")
        chatTagsTable.register(UINib(nibName: "ChatTagsCell", bundle: nil), forCellReuseIdentifier: "ChatTagsCell")
        chatTagsTable.register(UINib(nibName: "CustomChatTagsCell", bundle: nil), forCellReuseIdentifier: "CustomChatTagsCell")
        
        chatTagsTable.dataSource = self
        chatTagsTable.delegate = self
        chatTagsTable.dragDelegate = self
        saveButton.isHidden = true
        chatTagsTable.dragInteractionEnabled = false
        
    }
    
    func getAllChatTags() {
        
        ChatManager.getChatTagdata(completionHandler: { isSuccess, error, data in
            if isSuccess {
                var flyData = data
                if let chatTags = flyData.getData() as? [ChatTagsModel]{
                    self.chatTagsArray = chatTags
                }
                
                if self.chatTagsArray.count > 0 {
                    if self.chatTagsArray[0].isRecommentedTag {
                        self.EditButton.isHidden = true
                        self.saveButton.isHidden = true
                        self.isEditEnabled = false
                    }else {
                        if !self.isEditEnabled {
                            self.EditButton.isHidden = false
                            self.saveButton.isHidden = true
                            self.isEditEnabled = false
                        }
                       
                    }
                }
            }
        })
    }

    @IBAction func saveButtonAction(_ sender: Any) {
        
        EditButton.isHidden = false
        saveButton.isHidden = true
        isEditEnabled = false
        chatTagsTable.dragInteractionEnabled = false
        self.chatTagsTable.reloadData()

    }
    @IBAction func editButtonAction(_ sender: UIButton) {
        
        EditButton.isHidden = true
        saveButton.isHidden = false
        isEditEnabled = true
        chatTagsTable.dragInteractionEnabled = true
        chatTagsTable.reloadData()
       
    }
    @IBAction func backButtonAction(_ sender: UIButton) {
        
        if isEditEnabled {
            EditButton.isHidden = false
            saveButton.isHidden = true
            isEditEnabled = false
            chatTagsTable.dragInteractionEnabled = false
            self.chatTagsTable.reloadData()
        }else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc func pushToCreateTags(sender : Any) {
        
        if chatTagsArray.count < 10 {
            if let vc = UIStoryboard(name: "ChatTags", bundle: nil).instantiateViewController(withIdentifier: "CreateChatTagsController") as? CreateChatTagsController {
                vc.delegate = self
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }else {
            AppAlert.shared.showToast(message: "You have already created maximum number of chat tags")
        }
    }
    
    @objc func pushToDefaultTags(sender : UIButton) {
        if let vc = UIStoryboard(name: "ChatTags", bundle: nil).instantiateViewController(withIdentifier: "CreateChatTagsController") as? CreateChatTagsController {
            let chatTagTitle = chatTagsArray[sender.tag].tagname
            vc.tagName = chatTagTitle ?? ""
            vc.isFromDefaultTag = true
            vc.delegate = self
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
}

extension ChatTagsController: UITableViewDelegate, UITableViewDataSource, UITableViewDragDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 225
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "ChatTagsHeader")  as? ChatTagsHeader
        if chatTagsArray.count > 0 {
            let chatTag = chatTagsArray[0]
            if chatTag.isRecommentedTag {
                headerView?.tittleLabel.text = "Recommended Chat Tags"
            }else {
                headerView?.tittleLabel.text = "Chat Tags"
            }
        }
        return headerView
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatTagsArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let chatTag = chatTagsArray[indexPath.row]
        
        if chatTag.isRecommentedTag {
            return 110
        }else {
            return UITableView.automaticDimension
        }
       
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let chatTag = chatTagsArray[indexPath.row]
        
        if chatTag.isRecommentedTag {
            
            let cell : ChatTagsCell = tableView.dequeueReusableCell(withIdentifier: "ChatTagsCell", for: indexPath) as! ChatTagsCell
            cell.titleLable.text = chatTag.tagname
            cell.addButton.titleLabel?.font = UIFont.font14px_appSemibold()
            cell.addButton.setTitleColor(Color.color_3276E2, for: .normal)
            cell.addButton.tag = indexPath.row
            cell.addButton.addTarget(self, action: #selector(pushToDefaultTags(sender:)), for: .touchUpInside)
            tableView.separatorColor = .clear
            cell.selectionStyle = .none
            return cell
        } else {
            
            let cell : CustomChatTagsCell = tableView.dequeueReusableCell(withIdentifier: "CustomChatTagsCell", for: indexPath) as! CustomChatTagsCell
            cell.titleLabel.text = chatTag.tagname
            cell.subTitleLabel.text = chatTag.taginfo
            cell.deleteTagButton.isHidden = isEditEnabled ? false : true
            cell.deleteTagButton.tag = indexPath.row
            cell.deleteTagButton.addTarget(self, action: #selector(deleteTagAction(sender:)), for: .touchUpInside)
            cell.arrowImg.image = isEditEnabled ? UIImage(named:"reorder_tag") : UIImage(named:"gray_arrow")
            cell.arrowWidth.constant = isEditEnabled ? 25 : 15
            cell.arrowHeight.constant = isEditEnabled ? 25 : 15
            cell.removeTagView.isHidden = !isEditEnabled
            cell.selectionStyle = .none
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if !isEditEnabled {
            
            if let vc = UIStoryboard(name: "ChatTags", bundle: nil).instantiateViewController(withIdentifier: "CreateChatTagsController") as? CreateChatTagsController {
                let chatTag = chatTagsArray[indexPath.row]
                vc.currentTagDetails = chatTag
                vc.tagName = chatTag.tagname ?? ""
                vc.isFromUpdatTag = true
                vc.delegate = self
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "ChatTagsFooterCell" ) as! ChatTagsFooterCell
        let  tap = UITapGestureRecognizer(target: self, action: #selector(self.pushToCreateTags(sender:)))
        footerView.createTagsLabel.addGestureRecognizer(tap)
        
        footerView.createTagsLabel.textColor = isEditEnabled ? Color.borderColor : Color.color_3276E2
        footerView.createTagsLabel.isUserInteractionEnabled = isEditEnabled ? false : true
        
        if chatTagsArray.count > 0 {
            let chatTag = chatTagsArray[0]
            if chatTag.isRecommentedTag {
                footerView.viewSeprator.isHidden = true
                footerView.labelFooter.isHidden = true
            }else{
                footerView.viewSeprator.isHidden = false
                footerView.labelFooter.isHidden = false
            }
        }
        
        return footerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 90
    }
    
    //drag and drop delegate methodds
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
        dragItem.localObject = chatTagsArray[indexPath.row]
        return [ dragItem ]
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let mover = chatTagsArray.remove(at: sourceIndexPath.row)
        chatTagsArray.insert(mover, at: destinationIndexPath.row)
        reorderChatTags(chatTags: chatTagsArray)
        self.chatTagsTable.reloadData()
    }

    
    @objc func deleteTagAction(sender: UIButton) {
        
        let alertController = UIAlertController(title: "", message: "This will remove chat tag, your chats will not be deleted.", preferredStyle: .actionSheet)
            
               let removeAction = UIAlertAction(title: removeTitle, style: .destructive) { (action:UIAlertAction!) in
                   
                   let chatTag = self.chatTagsArray[sender.tag]
                   ChatManager.deleteChatTag(chatTag: chatTag) { isSuccess, error, data in
                       
//                       self.chatTagsArray.remove(at: sender.tag)
//                       let index = IndexPath(item: sender.tag, section: 0)
//                       self.chatTagsTable.deleteRows(at: [index], with: .fade)

                       self.getAllChatTags()
                       self.chatTagsTable.reloadData()
                   }
               }
               let cancelAction = UIAlertAction(title: cancelUppercase, style: .cancel) { (action:UIAlertAction!) in
                   print("Cancel button tapped");
               }
        
               alertController.addAction(removeAction)
               alertController.addAction(cancelAction)
               self.present(alertController, animated: true, completion:nil)
    }
    
    func reorderChatTags(chatTags:[ChatTagsModel]) {
        
        ChatManager.reorderChatTags(chatTags: chatTags) { isSuccess, error, data in
        }
        
    }
}

extension ChatTagsController: CreateChatTagsDelegate {
    
    func onChatTagCreated(chatTag: ChatTagsModel) {
        
        getAllChatTags()
        chatTagsTable.reloadData()
    }
}


