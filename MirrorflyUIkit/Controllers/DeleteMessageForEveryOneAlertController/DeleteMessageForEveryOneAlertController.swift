//
//  DeleteMessageForEveryOneAlertController.swift
//  MirrorflyUIkit
//
//  Created by sowmiya on 30/09/22.
//

import UIKit
import MirrorFlySDK

class DeleteMessageForEveryOneAlertController : UIViewController {
    
    @IBOutlet weak var cancelButton: UIButton?
    @IBOutlet weak var deleteForEveryOneStack: UIStackView?
    @IBOutlet weak var checkBoxButton: UIButton?
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var contentView: UIView?
    @IBOutlet weak var checkBoxImage: UIImageView?
    @IBOutlet weak var deleteForMeButton: UIButton?
    @IBOutlet weak var deleteForEveryOneButton: UIButton?
    @IBOutlet weak var secondTitleLabel: UILabel?
    @IBOutlet weak var firstTitleLabel: UILabel?
    
    var delegate: DeleteMessageButtonAction? = nil
    var deleteMessages: [SelectedMessages]? = []
    var isClearAllPopup: Bool? = false
    var isMessageStarred: Bool? = false
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView?.layer.cornerRadius = 10
        cancelButton?.addTarget(self, action: #selector(closeButtonTapped(sender:)), for: .touchUpInside)
        deleteForMeButton?.addTarget(self, action: #selector(deleteForMeTapped(sender:)), for: .touchUpInside)
        deleteForEveryOneButton?.addTarget(self, action: #selector(deleteForEveryOneButtonTapped(sender:)), for: .touchUpInside)
        checkBoxButton?.addTarget(self, action: #selector(deleteMediaAccess), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isClearAllPopup == true {
            deleteForEveryOneStack?.isHidden = true
            firstTitleLabel?.text = clearAll
            secondTitleLabel?.text = clearExceptStarred
            titleLabel?.text = "Are you sure you want to clear the chat?"
        } else {
            firstTitleLabel?.text = deleteforMe
            secondTitleLabel?.text = deleteforEveryone
            if (deleteMessages?.filter({($0.chatMessage.mediaChatMessage?.mediaDownloadStatus == .downloaded && $0.chatMessage.isMessageSentByMe == false && $0.chatMessage.isMessageRecalled == false) || ($0.chatMessage.mediaChatMessage != nil && $0.chatMessage.isMessageSentByMe == true && $0.chatMessage.isMessageRecalled == false)}).count ?? 0) > 0 {
                deleteForEveryOneStack?.isHidden = false
            } else {
                deleteForEveryOneStack?.isHidden = true
            }
            titleLabel?.text = deleteMessages?.count == 1 ? "Are you sure you want to delete selected Message?" : "Are you sure you want to delete selected messages?"
            checkBoxImage?.image = Utility.getBoolFromPreference(key: revokeMediaAccess) ? UIImage(named: ImageConstant.ic_checked) : UIImage(named: ImageConstant.ic_check_box)
        }
    }
    
    @objc private func deleteMediaAccess() {
        if !Utility.getBoolFromPreference(key: revokeMediaAccess) {
            checkBoxImage?.image = UIImage(named: ImageConstant.ic_checked)
            Utility.saveInPreference(key: revokeMediaAccess, value: true)
        } else {
            checkBoxImage?.image = UIImage(named: ImageConstant.ic_check_box)
            Utility.saveInPreference(key: revokeMediaAccess, value: false)
        }
    }
    
    @objc func deleteForMeTapped(sender: UIButton) {
        dismiss(animated: true) { [weak self] in
            if self?.isClearAllPopup == true {
                self?.delegate?.clearAllWithStarred()
            } else {
                self?.delegate?.deleteForMeButtonTapped()
            }
        }
    }
    
    @objc func closeButtonTapped(sender: UIButton) {
        dismiss(animated: true) { [weak self] in
            self?.delegate?.closeButtonTapped()
        }
    }
    
    @objc func deleteForEveryOneButtonTapped(sender: UIButton) {
        dismiss(animated: true) { [weak self] in
            if self?.isClearAllPopup == true {
                self?.delegate?.clearAllWithOutStarred()
            } else {
                self?.delegate?.deleteForEveryOneButtonTapped()
            }
        }
    }
}
