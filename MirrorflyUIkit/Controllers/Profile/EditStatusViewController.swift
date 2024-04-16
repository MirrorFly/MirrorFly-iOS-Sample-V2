//
//  EditStatusViewController.swift
//  MirrorflyUIkit
//
//  Created by User on 17/08/21.
//

import Foundation
import UIKit
import MirrorFlySDK

protocol StatusDelegate: class {
    func userSelectedStatus(selectedStatus: String)
}

class EditStatusViewController: UIViewController {

    @IBOutlet weak var mainHeaderLabel: UILabel! {
        didSet {
            mainHeaderLabel.text = isUserBusyStatus ? "User Busy Status" : "Status"
        }
    }

    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var topStatusView: UIView!
    @IBOutlet weak var editStatusScrollView: UIScrollView!
    @IBOutlet weak var typeHereLabel: UILabel!
    @IBOutlet weak var statusTextview: UITextView!
    @IBOutlet weak var editStatusTableView: UITableView!
    @IBOutlet weak var editTextButton: UIButton!
    @IBOutlet weak var okButtonView: UIView!
    @IBOutlet weak var textCountLabel: UILabel!
    @IBOutlet weak var editStatusViewBottom: NSLayoutConstraint!
    @IBOutlet weak var selectionHeaderView: UIView!

    @IBOutlet weak var busyStatusLabel: UILabel!
    @IBOutlet weak var busyStatusTextView: UITextView!
    @IBOutlet weak var busyStatusCountLabel: UILabel!
    @IBOutlet weak var busyStatusEditTextButton: UIButton!
    @IBOutlet weak var busyStatusOkButton: UIView!

    @IBOutlet weak var busyStatusViewHeight: NSLayoutConstraint!
    @IBOutlet weak var statusViewHeight: NSLayoutConstraint!

    @IBOutlet weak var busyStatusMainView: UIView!
    @IBOutlet weak var profileStatusMainView: UIView!

    var isUserBusyStatus = false
    
    var defaultStatus: String!
    var setstatusArray = [StatusModel]()
    weak var delegate: StatusDelegate? = nil
    var statusArray: [ProfileStatus] = []
    var busyStatusArray: [BusyStatus] = []
    var isStatusChanged: Bool = false

    var isLongPress = false
    var deleteIndexPath: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if isUserBusyStatus {
            statusViewHeight.constant = 0
            profileStatusMainView.isHidden = true
            busyStatusMainView.isHidden = false
        } else {
            busyStatusViewHeight.constant = 0
            profileStatusMainView.isHidden = false
            busyStatusMainView.isHidden = true
        }

        statusArray =   getStatus()
        busyStatusArray = getBusyStatus()
        setupUI()
        if( statusArray.count > 0) {
            scrolltoRow()
        }
        else {
            saveStatus()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        editStatusTableView.rowHeight = UITableView.automaticDimension
        editStatusTableView.estimatedRowHeight = UITableView.automaticDimension
    }
    
    func setupUI() {

        if isUserBusyStatus {
            defaultStatus = ChatManager.shared.getMyBusyStatus().status
        }

        backgroundView.isHidden = true
        typeHereLabel.isHidden = true
        busyStatusLabel.isHidden = true
        okButtonView.isHidden = true
        busyStatusOkButton.isHidden = true
        textCountLabel.isHidden = true
        busyStatusCountLabel.isHidden = true
        statusTextview.delegate = self
        busyStatusTextView.delegate = self
        statusTextview.text =   defaultStatus
        busyStatusTextView.text = defaultStatus
        statusTextview.inputAccessoryView = UIView()
        busyStatusTextView.inputAccessoryView = UIView()
        statusTextview.textInputMode?.primaryLanguage == emoji
        statusTextview.keyboardType = .default
        busyStatusTextView.keyboardType = .default
    }
    
    func saveStatus() {
        setstatusArray = [
            StatusModel(userStatus: atTheMovies.localized, isSelected: false),
            StatusModel(userStatus: urgentCalls.localized, isSelected: false),
            StatusModel(userStatus: available.localized, isSelected: false),
            StatusModel(userStatus: sleeping.localized, isSelected: false),
            StatusModel(userStatus: inMirrorfly.localized, isSelected: true)
        ]
        for status in   setstatusArray {
            ChatManager.saveProfileStatus(statusText: status.userStatus,currentStatus: status.isSelected)
        }
        
        statusArray =   getStatus()
        scrolltoRow()
    }

    func scrolltoRow() {
        editStatusTableView.reloadData()
        //        executeOnMainThread { [weak self] in
        //            self?.
        //            if self?.isUserBusyStatus ?? false {
        //                self?.busyStatusArray.enumerated().forEach { (index, value) in
        //                    if value.status == self?.defaultStatus {
        //                        self?.editStatusTableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .top, animated: false)
        //                    }
        //                }
        //            } else {
        //                self?.statusArray.enumerated().forEach { (index, value) in
        //                    if value.status == self?.defaultStatus {
        //                        self?.editStatusTableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .top, animated: false)
        //                    }
        //                }
        //            }
        //        }
    }
    
    func getStatus() -> [ProfileStatus] {
        let profileStatus = ChatManager.getAllStatus()
        print("Get Status Started profileList Count \(profileStatus.count)")
        return profileStatus
    }

    func getBusyStatus() -> [BusyStatus] {
        let profileStatus = ChatManager.shared.getBusyStatusList()
        print("Get Status Started profileList Count \(profileStatus.count)")
        return profileStatus
    }
    
    @objc private func keyboardDidShow(notification: Notification) {
        let keyboardInfo = notification.userInfo
        let keyboardFrameBegin = keyboardInfo?[UIResponder.keyboardFrameEndUserInfoKey]
        let keyboardFrameBeginRect = (keyboardFrameBegin as! NSValue).cgRectValue
        self.editStatusViewBottom.constant = keyboardFrameBeginRect.size.height
        let contentInset:UIEdgeInsets = UIEdgeInsets.zero
        self.editStatusScrollView.contentInset = contentInset
        self.editStatusScrollView.isScrollEnabled = false
        self.view.layoutIfNeeded()
    }
    
    @objc private func keyboardDidHide(notification: Notification) {
        self.editStatusViewBottom.constant = 0
        let contentInset:UIEdgeInsets = UIEdgeInsets.zero
        self.editStatusScrollView.contentInset = contentInset
        self.editStatusScrollView.isScrollEnabled = true
        self.view.layoutIfNeeded()
    }

    func newStatusView() {
        if !isUserBusyStatus {
            backgroundView.isHidden = false
            backgroundView.backgroundColor = Color.primaryTextColor
            backgroundView.alpha = 0.5
            topStatusView.backgroundColor = Color.primaryTextColor
            topStatusView.alpha = 0.5
            view.bringSubviewToFront(backgroundView)
        }
        if isUserBusyStatus {
            busyStatusTextView.becomeFirstResponder()
        } else {
            statusTextview.becomeFirstResponder()
        }
        editTextButton.isHidden = true
        busyStatusEditTextButton.isHidden = true
        typeHereLabel.isHidden = false
        busyStatusLabel.isHidden = false
        okButtonView.isHidden = false
        busyStatusOkButton.isHidden = false
        textCountLabel.isHidden = false
        busyStatusCountLabel.isHidden = false
    }

    func hideNewStatusView() {
        backgroundView.isHidden = true
        topStatusView.backgroundColor = Color.navigationColor
        view.sendSubviewToBack(  backgroundView)
        typeHereLabel.isHidden = true
        busyStatusLabel.isHidden = true
        okButtonView.isHidden = true
        busyStatusOkButton.isHidden = true
        textCountLabel.isHidden = true
        busyStatusCountLabel.isHidden = true
        editTextButton.isHidden = false
        busyStatusEditTextButton.isHidden = false
        view.endEditing(true)
    }
}

//MARK: Button Action
extension EditStatusViewController {
    @IBAction func onEditButton(_ sender: Any) {
        newStatusView()
    }
    
    @IBAction func onBackButton(_ sender: Any) {
        navigationController?.popViewController(animated: false)
    }

    @IBAction func onDeleteBackButton(_ sender: Any) {
        updateDeleteHeaderView()
    }

    @IBAction func onDeleteButton(_ sender: Any) {
        if let indexPath = deleteIndexPath {
            showDelete(indexPath: indexPath)
        }
        updateDeleteHeaderView()
    }

    func updateDeleteHeaderView() {
        selectionHeaderView.isHidden = true
        deleteIndexPath = nil
        editStatusTableView.reloadData()
        isLongPress = false
    }
    
    @IBAction func onOkButton(_ sender: Any) {
        if isUserBusyStatus {
            if busyStatusTextView.text.isBlank {
                view.endEditing(true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    AppAlert.shared.showToast(message: busyEmptyStatus.localized)
                }
            } else {
                if NetworkReachability.shared.isConnected {
                    self.hideNewStatusView()
                    self.defaultStatus = self.busyStatusTextView.text
                    self.busyStatusArray = self.getBusyStatus()
                    self.scrolltoRow()
                    //                FlyDatabaseController.shared.userBusyStatusManager.saveStatus(busyStatus: BusyStatus(statusText: busyStatusTextView.text))
                    startLoading(withText: "", color: .clear)
                    ChatManager.shared.setMyBusyStatus(busyStatusTextView.text) {isSuccess,error,data in
                        executeOnMainThread { [weak self] in
                            guard let self else {return}
                            self.stopLoading()
                            self.busyStatusArray = self.getBusyStatus()
                            self.editStatusTableView.reloadData()
                            
                        }
                    }
                } else {
                    AppAlert.shared.showToast(message: ErrorMessage.noInternet)
                }
                //navigationController?.popViewController(animated: true)
            }
        } else {
            if NetworkReachability.shared.isConnected {
                if statusTextview.text.isBlank {
                    view.endEditing(true)
                    AppAlert.shared.showToast(message: emptyStatus.localized)
                } else {
                    let trimmedStatus = statusTextview.text.trimmingCharacters(in: .whitespacesAndNewlines)

                    if(isStatusChanged) {
                        ChatManager.saveProfileStatus(statusText: trimmedStatus, currentStatus: true)
                    }

                    navigationController?.popViewController(animated: true)
                }
            }
            else {
                AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            }
        }
    }
}

//MARK: Tableview
extension EditStatusViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let label = StatusHeaderLabel()
        label.text = isUserBusyStatus ? editBusyStatusSectionTitle.localized : editStatusSectionTitle.localized
        
        let containerView = UIView()
        containerView.addSubview(label)
        label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 17).isActive = true
        return containerView
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(statusHeader)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  isUserBusyStatus ? busyStatusArray.count : statusArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: EditStatusTableViewCell!
        
        cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.statusCell, for: indexPath as IndexPath) as? EditStatusTableViewCell
        cell.selectionStyle = .none

        cell.selectImage.image = UIImage(named: "ic_tickmark")

        if isUserBusyStatus {
            cell.statusLabel.text = busyStatusArray[indexPath.row].status
            if(busyStatusArray[indexPath.row].isCurrentStatus) {
                cell.selectImage.isHidden = false
                cell.statusLabel.textColor = .black
            }
            else {
                cell.statusLabel.textColor = Color.userStatusUnselectColor
                cell.selectImage.isHidden = true
            }
        } else {
            cell.statusLabel.text = statusArray[indexPath.row].status
            if(statusArray[indexPath.row].isCurrentStatus) {
                cell.selectImage.isHidden = false
                cell.statusLabel.textColor = .black
            }
            else {
                cell.statusLabel.textColor = Color.userStatusUnselectColor
                cell.selectImage.isHidden = true
            }
        }

        if let index = deleteIndexPath, index == indexPath {
            cell.contentView.backgroundColor = Color.recentChatSelectionColor
            selectionHeaderView.isHidden = false
        } else {
            cell.contentView.backgroundColor = .clear
        }

        cell.selectButton.tag = indexPath.row
        cell.selectButton.addTarget(self, action: #selector(  onSelectStatus(sender:)), for: .touchUpInside)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))
        tableView.addGestureRecognizer(longPress)
        
        return cell
    }

}
//MARK: Tableview action
extension EditStatusViewController {
    @objc private func handleLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began && !isLongPress {
            let touchPoint = sender.location(in: editStatusTableView)
            if let indexPath = editStatusTableView.indexPathForRow(at: touchPoint) {
                if self.busyStatusArray[indexPath.row].isCurrentStatus == false {
                    isLongPress = true
                    deleteIndexPath = indexPath
                    editStatusTableView.reloadRows(at: [indexPath], with: .none)
                }
            }
        }
    }

    @objc private func onDeleteStatus(sender: UITapGestureRecognizer) {
        if let indexPath = deleteIndexPath {
            showDelete(indexPath: indexPath)
        }
    }
    
    func showDelete(indexPath: IndexPath) {

        if self.isUserBusyStatus == true {
            if self.busyStatusArray[indexPath.row].isCurrentStatus == true {
                return
            }
        }

        AppAlert.shared.showAlert(view: self, title: nil, message: deleteStatusAlert, buttonOneTitle: noButton, buttonTwoTitle: yesButton)
        AppAlert.shared.onAlertAction = { [weak self] (result)  ->
            Void in
            if result == 1 {
                if let status = self?.isUserBusyStatus, status == true {
                    self?.deleteBusyStatus(status: (self?.busyStatusArray[indexPath.row])!)
                    self?.busyStatusArray = self?.getBusyStatus() ?? []
                    self?.editStatusTableView.reloadData()
                } else {
                    self?.deleteStatus(statusId: (self?.statusArray[indexPath.row].id)!)
                    self?.statusArray = self?.getStatus() ?? []
                    self?.editStatusTableView.reloadData()
                }
            }else {
                self?.deleteIndexPath = nil
                self?.editStatusTableView.reloadData()
            }
        }
    }

    func deleteStatus(statusId: String) {
        ChatManager.deleteStatus(statusId: statusId)
    }

    func deleteBusyStatus(status: BusyStatus) {
        ChatManager.shared.deleteBusyStatus(statusId:status.id)
    }
    
    @objc func alertControllerBackgroundTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func onSelectStatus(sender : UIButton) {

        if isLongPress {
            deleteIndexPath = IndexPath(row: sender.tag, section: 0)
            if self.busyStatusArray[deleteIndexPath?.row ?? 0].isCurrentStatus == true {
                updateDeleteHeaderView()
                return
            }
            editStatusTableView.reloadData()
        } else {
            if isUserBusyStatus {
                if NetworkReachability.shared.isConnected {
                    let indexRow = sender.tag
                    busyStatusTextView.text =   busyStatusArray[indexRow].status
                    for i in 0 ..< busyStatusArray.count {
                        busyStatusArray[i].isCurrentStatus = false
                    }
                    busyStatusArray[indexRow].isCurrentStatus = true
                    ChatManager.shared.setMyBusyStatus(busyStatusTextView.text) {isSuccess,error,data in
                        executeOnMainThread { [weak self] in
                            guard let self else {return}
                            self.editStatusTableView.reloadData()
                        }
                    }
                } else {
                    AppAlert.shared.showToast(message: ErrorMessage.noInternet)
                }
            } else {
                if NetworkReachability.shared.isConnected {
                    let indexRow = sender.tag
                    for i in 0..<statusArray.count {
                        statusArray[i].isCurrentStatus = false
                    }
                    statusArray[indexRow].isCurrentStatus = true
                    editStatusTableView.reloadData()
                    statusTextview.text = statusArray[indexRow].status

                    var getAllStatus: [ProfileStatus] = []
                    getAllStatus = getStatus()
                    for getAllStatus in  statusArray {
                        if(getAllStatus.id == statusArray[indexRow].id) {
                            ChatManager.updateStatus(statusId: statusArray[indexRow].id ,statusText: statusArray[indexRow].status,currentStatus: true)
                        }
                        else{
                            ChatManager.updateStatus(statusId: getAllStatus.id, statusText: getAllStatus.status, currentStatus: false)
                        }
                    }
                }
                else {
                    AppAlert.shared.showToast(message: ErrorMessage.noInternet)
                }
            }
        }
    }
}

//MARK: TextViewDelegate
extension EditStatusViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        textCountLabel.text = "\(editStatusTextMaxLength - textView.text.count)"
        busyStatusCountLabel.text = "\(editStatusTextMaxLength - textView.text.count)"
        newStatusView()
        typeHereLabel.text = ""
        busyStatusLabel.text = ""
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        hideNewStatusView()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        isStatusChanged = true
        textCountLabel.text = "\(editStatusTextMaxLength - textView.text.count)"
        busyStatusCountLabel.text = "\(editStatusTextMaxLength - textView.text.count)"
        //        if textView.text.last == "\n" {
        //            textView.resignFirstResponder()
        //        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
            return true
        }
        if text.count > 1 {
            let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
            return newText.count <= editStatusTextMaxLength;
        } else {
            return textView.text.count + (text.count - range.length) <= editStatusTextMaxLength
        }
    }
}

