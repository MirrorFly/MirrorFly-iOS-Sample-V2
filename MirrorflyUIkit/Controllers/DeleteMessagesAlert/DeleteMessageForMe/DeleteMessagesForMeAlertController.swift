//
//  DeleteMessageForMeAlertController.swift
//  MirrorflyUIkit
//
//  Created by sowmiya on 30/09/22.
//

import Foundation
import MirrorFlySDK
import UIKit



protocol DeleteMessageButtonAction {
    func closeButtonTapped()
    func deleteForMeButtonTapped()
    func deleteForEveryOneButtonTapped()
    func clearAllWithStarred()
    func clearAllWithOutStarred()
}

class DeleteMessagesForMeAlertController : UIViewController {
    @IBOutlet weak var forMeStackView: UIStackView?
    @IBOutlet weak var revokeMediaStackView: UIStackView?
    @IBOutlet weak var checkBoxImage: UIImageView?
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var cancelButton: UIButton?
    @IBOutlet weak var deleteForMeButton: UIButton?
    @IBOutlet weak var checkBoxButton: UIButton?
    @IBOutlet weak var contentView: UIView?
    var isRevokeMediaAccess: Bool? = false
    var delegate: DeleteMessageButtonAction? = nil
    var deleteMessages: [SelectedMessages]? = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView?.layer.cornerRadius = 10
        cancelButton?.addTarget(self, action: #selector(closeButtonTapped(sender:)), for: .touchUpInside)
        deleteForMeButton?.addTarget(self, action: #selector(deleteForMeTapped(sender:)), for: .touchUpInside)
        checkBoxButton?.addTarget(self, action: #selector(deleteMediaAccess), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if (deleteMessages?.filter({($0.chatMessage.mediaChatMessage?.mediaDownloadStatus == .downloaded && $0.chatMessage.isMessageSentByMe == false && $0.chatMessage.isMessageRecalled == false) || ($0.chatMessage.mediaChatMessage != nil && $0.chatMessage.isMessageSentByMe == true && $0.chatMessage.isMessageRecalled == false)}).count ?? 0) > 0 {
                revokeMediaStackView?.isHidden = false
            } else {
                revokeMediaStackView?.isHidden = true
            }
        titleLabel?.text = deleteMessages?.count == 1 ? "Are you sure you want to delete selected Message?" : "Are you sure you want to delete selected messages?"
        checkBoxImage?.image = Utility.getBoolFromPreference(key: revokeMediaAccess) ? UIImage(named: ImageConstant.ic_checked) : UIImage(named: ImageConstant.ic_check_box)
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
            self?.delegate?.deleteForMeButtonTapped()
        }
    }
    
    @objc func closeButtonTapped(sender: UIButton) {
        dismiss(animated: true) { [weak self] in
            self?.delegate?.closeButtonTapped()
        }
    }
}


