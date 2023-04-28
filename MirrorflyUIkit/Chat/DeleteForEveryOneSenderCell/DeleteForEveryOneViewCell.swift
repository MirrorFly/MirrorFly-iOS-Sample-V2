//
//  DeleteForEveryOneViewCell.swift
//  UiKitQa
//
//  Created by sowmiya on 29/09/22.
//

import UIKit
import MirrorFlySDK

class DeleteForEveryOneViewCell: UITableViewCell {
    @IBOutlet weak var statusImageView: UIImageView?
    @IBOutlet weak var timeLabel: UILabel?
    @IBOutlet weak var deleteView: UIView?
    @IBOutlet weak var forwardCheckBoxImage: UIImageView?
    @IBOutlet weak var deleteForEveryOneLabel: UILabel?
    @IBOutlet weak var forwardBubbleView: UIView?
    @IBOutlet weak var forwardLeadingCons: NSLayoutConstraint?
    @IBOutlet weak var forwardButton: UIButton?
    var refreshDelegate: RefreshBubbleImageViewDelegate? = nil
    var selectedForwardMessage: [SelectedMessages]? = []
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func setDeleteForMeMessage(message: ChatMessage,isShowForwardMessage: Bool,isDeleteSelected: Bool) {
        ChatUtils.setBubbleBackground(view: deleteView)
        if selectedForwardMessage?.filter({$0.chatMessage.messageId == message.messageId}).first?.isSelected == true {
            forwardCheckBoxImage?.image = UIImage(named: "forwardSelected")
            forwardCheckBoxImage?.isHidden = false
            forwardBubbleView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 0.0)
        } else {
            forwardCheckBoxImage?.isHidden = true
            forwardBubbleView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 1.5)
        }
        
        if !(isShowForwardMessage) || (isDeleteSelected == false && message.isMessageRecalled == true) {
            forwardBubbleView?.isHidden = true
            forwardButton?.isHidden = true
            forwardLeadingCons?.constant = 0
        } else {
            forwardBubbleView?.isHidden = false
            forwardButton?.isHidden = false
            forwardLeadingCons?.constant = 20
        }
        
        timeLabel?.text = DateFormatterUtility.shared.convertMillisecondsToDateTime(milliSeconds: message.messageSentTime).reduceToMonthDayYear().description
        timeLabel?.isAccessibilityElement =  true
        timeLabel?.accessibilityLabel = Utility.currentMillisecondsToTime(milliSec: message.messageSentTime)
        timeLabel?.text = Utility.currentMillisecondsToTime(milliSec: message.messageSentTime)
        timeLabel?.text = DateFormatterUtility.shared.currentMillisecondsToLocalTime(milliSec: message.messageSentTime)
        deleteForEveryOneLabel?.text = "You deleted this message"
        statusImageView?.isHidden = true
    }
}
