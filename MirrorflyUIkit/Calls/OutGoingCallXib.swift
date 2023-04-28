//
//  ReceivingVideoCallViewController.swift
//  GroupCallUI
//
//  Created by Vasanth Kumar on 25/05/21.
//

import UIKit
import WebRTC

class OutGoingCallXib: UIView {
    @IBOutlet var OutGoingPersonLabel: UILabel!
    @IBOutlet var OutgoingRingingStatusLabel: UILabel!
    @IBOutlet var OutGoingCallBG: UIImageView!
    @IBOutlet var outGoingAudioCallImageView: UIImageView!
    @IBOutlet var stackView: UIStackView!
    @IBOutlet var contentView: UIView!
    @IBOutlet var speakerButton: UIButton!
    @IBOutlet var videoButton: UIButton!
    @IBOutlet var cameraButton: UIButton!
    @IBOutlet var AttendingBottomView: UIView!
    @IBOutlet var audioButton: UIButton!
    @IBOutlet var callAgainView: UIView!
    @IBOutlet var CallAgainButton: UIButton!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet weak var callActionsViewHeight: NSLayoutConstraint!
    @IBOutlet weak var timerLable: UILabel!
    @IBOutlet weak var audioMuteStackView: UIStackView!
    @IBOutlet weak var audioMutedLable: UILabel!
    @IBOutlet weak var audioMutedIcon: UIImageView!
    @IBOutlet weak var localUserVideoView: UIView!
    @IBOutlet weak var remoteUserVideoView: UIView!
    @IBOutlet weak var localVideoViewBottom: NSLayoutConstraint!
    @IBOutlet weak var localVideoViewTrailing: NSLayoutConstraint!
    @IBOutlet weak var localVideoViewWidth: NSLayoutConstraint!
    @IBOutlet weak var localVideoViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var nameTop: NSLayoutConstraint!
    @IBOutlet weak var imageViewHeight: NSLayoutConstraint!
    @IBOutlet weak var timerTop: NSLayoutConstraint!
    @IBOutlet weak var imageTop: NSLayoutConstraint!
    @IBOutlet weak var imageHeight: NSLayoutConstraint!
    @IBOutlet weak var viewHeight: NSLayoutConstraint!
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var addParticipantBtn: UIButton!
    @IBOutlet weak var callEndBtn: UIButton!
    
    @IBOutlet weak var statusLble: NSLayoutConstraint!
    @IBOutlet weak var remoteImageView: UIImageView!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    private func commonInit() {
        Bundle.main.loadNibNamed("OutGoingCallXib", owner: self, options: nil)
        outGoingAudioCallImageView.layer.cornerRadius = outGoingAudioCallImageView.frame.width/2
        outGoingAudioCallImageView.layer.masksToBounds = true
        outGoingAudioCallImageView.image = UIImage(named: "default_avatar")
        callAgainView.backgroundColor = .clear
        callAgainView.isHidden = true
        addSubview(contentView)
        contentView.backgroundColor = .clear
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        localUserVideoView.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        remoteImageView.layer.cornerRadius = remoteImageView.bounds.height/2
        remoteImageView.image = UIImage(named: "default_avatar")
    }
}
