//
//  DeleteForEveryOneReceiverCell.swift
//  UiKitQa
//
//  Created by sowmiya on 30/09/22.
//

import UIKit
import MirrorFlySDK

class DeleteForEveryOneReceiverCell: UITableViewCell {
    @IBOutlet weak var forwardCheckBoxImage: UIImageView?
    @IBOutlet weak var forwardBubbleView: UIView?
    @IBOutlet weak var timeLabel: UILabel?
    @IBOutlet weak var statusImageView: UIImageView?
    @IBOutlet weak var deleteForEveryOneLabel: UILabel?
    @IBOutlet weak var deleteView: UIView?
    
    @IBOutlet weak var groupNameTopCons: NSLayoutConstraint?
    @IBOutlet weak var groupNameBottomCons: NSLayoutConstraint?
    @IBOutlet weak var forwardLeadingCons: NSLayoutConstraint?
    @IBOutlet weak var deleteViewLeadingCons: NSLayoutConstraint?
    @IBOutlet weak var forwardButton: UIButton?
    @IBOutlet weak var groupChatNameLabel: GroupReceivedMessageHeader?
    @IBOutlet weak var groupNameView: UIView?
    @IBOutlet weak var bubbleImageView: UIImageView?
    @IBOutlet weak var groupNameViewHeightCons: NSLayoutConstraint?
    @IBOutlet weak var hideGroupNameViewCons: NSLayoutConstraint?
    
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
    
    func setDeleteForEveryOneMessage(message: ChatMessage,isShowForwardMessage: Bool,isDeleteSelected : Bool) {
        ChatUtils.setBubbleBackground(view: deleteView)
        deleteViewLeadingCons?.constant = (isShowForwardMessage == true) ? 10 : 0
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
        
        if message.messageChatType == .groupChat {
            if let nameLabel = groupChatNameLabel {
                ChatUtils.setReceiverBubbleBackground(imageView: bubbleImageView)
                nameLabel.text = ChatUtils.getGroupSenderName(messsage: message)
                groupChatNameLabel?.isHidden = false
                groupNameView?.isHidden = false
            }
        } else {
            groupChatNameLabel?.isHidden = true
            groupNameView?.isHidden = true
        }
        timeLabel?.text = DateFormatterUtility.shared.convertMillisecondsToDateTime(milliSeconds: message.messageSentTime).reduceToMonthDayYear().description
        timeLabel?.isAccessibilityElement =  true
        timeLabel?.accessibilityLabel = Utility.currentMillisecondsToTime(milliSec: message.messageSentTime)
        timeLabel?.text = Utility.currentMillisecondsToTime(milliSec: message.messageSentTime)
        timeLabel?.text = DateFormatterUtility.shared.currentMillisecondsToLocalTime(milliSec: message.messageSentTime)
        deleteForEveryOneLabel?.text = message.isMessageSentByMe ? senderDeletedMessage : receiverDeletedMessage
        // Message acknowledgement status
        statusImageView?.isAccessibilityElement = true
        if(message.isMessageSentByMe) {
            statusImageView?.isHidden = false
            switch message.messageStatus {
            case .sent:
                statusImageView?.image = UIImage.init(named: ImageConstant.ic_hour)
                statusImageView?.accessibilityLabel = sent.localized
                break
            case .acknowledged:
                statusImageView?.image = UIImage.init(named: ImageConstant.ic_sent)
                statusImageView?.accessibilityLabel = acknowledged.localized
                break
            case .delivered:
                statusImageView?.image = UIImage.init(named: ImageConstant.ic_delivered)
                statusImageView?.accessibilityLabel = delivered.localized
                break
            case .seen:
                statusImageView?.image = UIImage.init(named: ImageConstant.ic_seen)
                statusImageView?.accessibilityLabel = seen.localized
                break
            case .received:
                statusImageView?.image = UIImage.init(named: ImageConstant.ic_delivered)
                statusImageView?.accessibilityLabel = delivered.localized
                break
            default:
                statusImageView?.image = UIImage.init(named: ImageConstant.ic_hour)
                statusImageView?.accessibilityLabel = notAcknowledged.localized
                break
            }
        }
        else {
            statusImageView?.isHidden = true
         //   self.seperatorLine.isHidden = true
        }
    }
    
}
