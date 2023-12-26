//
//  CallUIXib.swift
//  MirrorflyUIkit
//
//  Created by MohanRaj on 18/08/23.
//

import UIKit

class CallUIXib: UIView {
    
    @IBOutlet weak var tileCollectionView: UICollectionView!
    
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
    
    @IBOutlet weak var audioCallMutedIcon: UIImageView!
    
    @IBOutlet weak var remoteUserVideoView: UIView!
    
    @IBOutlet weak var nameTop: NSLayoutConstraint!
    
    @IBOutlet weak var timerTop: NSLayoutConstraint! 
    
    @IBOutlet weak var imageTop: NSLayoutConstraint!  
    
    @IBOutlet weak var imageHeight: NSLayoutConstraint!  
    
    @IBOutlet weak var viewHeight: NSLayoutConstraint!  
    
    @IBOutlet weak var backBtn: UIButton!
    
    @IBOutlet weak var addParticipantBtn: UIButton!
    
    @IBOutlet weak var callEndBtn: UIButton!
    
//    @IBOutlet weak var statusLble: NSLayoutConstraint! //
    
    @IBOutlet weak var remoteImageView: UIImageView!
    
    @IBOutlet weak var tileCollectionWidth: NSLayoutConstraint!
    
    @IBOutlet weak var tileCollectionHeight: NSLayoutConstraint!
    
    @IBOutlet weak var tileCollectionTop: NSLayoutConstraint!
    
    @IBOutlet weak var tileCollectionBottom: NSLayoutConstraint!
    
    @IBOutlet weak var tileCollectionLeading: NSLayoutConstraint!
    
    
    @IBOutlet weak var tileCollectionTrailing: NSLayoutConstraint!
    
    @IBOutlet weak var reconnectingLable: UILabel!
    
    @IBOutlet weak var audioWaveView: UIView!
    
    @IBOutlet weak var menuButton: UIButton!
    
    @IBOutlet var profileImage: [UIImageView]!
    
    @IBOutlet weak var countLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    private func commonInit() {
        Bundle.main.loadNibNamed("CallUIXib", owner: self, options: nil)
        outGoingAudioCallImageView.layer.cornerRadius = outGoingAudioCallImageView.frame.width/2
        outGoingAudioCallImageView.layer.masksToBounds = true
        outGoingAudioCallImageView.image = UIImage(named: "default_avatar")
        callAgainView.backgroundColor = .clear
        callAgainView.isHidden = true
        addSubview(contentView)
        contentView.backgroundColor = .clear
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        
        countLabel.layer.cornerRadius = 25
        countLabel.layer.masksToBounds = true
    }
}
