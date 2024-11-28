//
//  TileCell.swift
//  MirrorflyUIkit
//
//  Created by MohanRaj on 19/08/23.
//

import UIKit
import MirrorFlySDK

class TileCell: UICollectionViewCell {
    
    static let identifier = "TileCell"
    
    @IBOutlet weak var contentVIew: UIView!
    @IBOutlet var profileName: UILabel!
    @IBOutlet var foreGroundView: UIView!
    @IBOutlet var statusLable: UILabel!
    @IBOutlet var audioIconImageView: UIImageView!
    @IBOutlet weak var callActionsView: UIView!
    @IBOutlet weak var qualityBars: UIImageView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var qualityView: UIView!
    @IBOutlet weak var videoBaseView: UIView!
    
    override func prepareForReuse() {
//        executeOnMainThread {
//            for view in self.videoBaseView.subviews {
//                view.removeFromSuperview()
//                self.videoBaseView.willRemoveSubview(view)
//            }
//        }
        super.prepareForReuse()
    }
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        executeOnMainThread {
            for view in self.videoBaseView.subviews {
                view.frame = CGRect(x: 0, y: 0, width: self.videoBaseView.bounds.width, height: self.videoBaseView.bounds.height)
            }
        }
    }
    
    func setImageHidden(_ hidden: Bool) {
        if CallManager.isOneToOneCall() {
            profileImageView.isHidden = hidden
        }else{
            profileImageView.isHidden = false
        }
    }
    
    func setupDataForTileCell(tileCell: TileCell, indexPath: IndexPath, members: [CallMember], member: CallMember, isBackCamera: Bool, showGridView: Bool, callStatus: CallStatus) {
        self.removeRenderView(tileCell: tileCell)
        var isLastRow = false
        print(" #STA= #callStatus onCallStatus ====  \(showGridView) showGridView")
        if showGridView{
            print(" #STA= #callStatus onCallStatus ====  \(indexPath.row) indexPath.row \(members.count) ")
            isLastRow = indexPath.row == (members.count - 1)
            if member.jid == AppUtils.getMyJid() {
                isLastRow = true
            }
        }else{
           // isLastRow = (CallManager.getCallMode() == .MEET && (members.count == 1 || members.count == 2) && !showGridView) ? true : (CallManager.isOneToOneCall() && !showGridView) ? true : members[members.count - 2].callStatus != .connected ? (indexPath.item == members.count - 2) : (indexPath.item == members.count - 1)
            
             isLastRow = (CallManager.getCallMode() == .MEET && (members.count == 1 || members.count == 2) && !showGridView) ? true : (CallManager.isOneToOneCall() && !showGridView) ? true : (indexPath.item == members.count - 1)
        }
        if isLastRow {
            if member.jid == AppUtils.getMyJid() {
                print("###### MY name YOU")
                tileCell.profileName.text = members.count == 1 ? "" : "You"
            }
            else
            {
                tileCell.profileName.text = member.name
            }
            tileCell.foreGroundView.isHidden = true
            tileCell.audioIconImageView.isHidden = false
            tileCell.audioIconImageView.image = member.isAudioMuted ? UIImage(systemName: "mic.slash.fill")?.withRenderingMode(.alwaysTemplate) : UIImage(named: "audio_lvl_one")?.withRenderingMode(.alwaysOriginal)
            tileCell.audioIconImageView.tintColor = .white
            if  CallManager.getCallType() == .Video ||  (member.videoTrack != nil && !member.isVideoMuted){
                if isBackCamera {
                    tileCell.videoBaseView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                }else {
                    // groupCell.videoBaseView.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
                }
            } else {
                // groupCell.profileImage.isHidden = false
                tileCell.videoBaseView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }
            tileCell.qualityView.isHidden = !((CallManager.getCallConnectionQuality() == .poor) && member.jid == AppUtils.getMyJid() && member.callStatus != .reconnecting) || CallUIViewController.isQualityToastShowing
        } else {
            tileCell.profileName.text = member.name
            tileCell.videoBaseView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            tileCell.audioIconImageView.image = member.isAudioMuted ? UIImage(systemName: "mic.slash.fill")?.withRenderingMode(.alwaysTemplate) : UIImage(named: "audio_lvl_one")?.withRenderingMode(.alwaysOriginal)
            tileCell.audioIconImageView.tintColor = .white
            tileCell.qualityView.isHidden = true
        }
        //print(" #STA= #callStatus onCallStatus ====  \(isLastRow)")
        if (isLastRow  && member.callStatus == .reconnecting) || (!isLastRow && member.callStatus != .connected) || member.callStatus == .onHold || (isLastRow && CallManager.isCallOnHold()) {
            tileCell.foreGroundView.isHidden = (CallManager.isOneToOneCall() && !showGridView) || (CallManager.getCallMode() == .MEET && (members.count == 1 || members.count == 2) && !showGridView) ? true : false
            tileCell.statusLable.text = (CallManager.isOneToOneCall() && !showGridView) || (CallManager.getCallMode() == .MEET && (members.count == 1 || members.count == 2) && !showGridView) ? "" : member.callStatus.rawValue.capitalized
            print(" #STA= #callStatus onCallStatus ====  \(String(describing: tileCell.statusLable.text)) text")
            if member.callStatus == .reconnecting || member.callStatus == .ringing || member.callStatus == .onHold || member.callStatus == .connecting || member.callStatus == .calling {
                tileCell.audioIconImageView.isHidden = true
            } else {
                tileCell.audioIconImageView.isHidden = false
            }
        }else{
            tileCell.foreGroundView.isHidden = true
            tileCell.statusLable.text = ""
            tileCell.audioIconImageView.isHidden = false
        }
       // if member.isVideoMuted  == true && member.videoTrack == nil{
            self.setupUserProfileImage(tileCell: tileCell, member: member, isLastRow: isLastRow)
       // }
        self.addVideoTrackToCell(tileCell: tileCell, member: member)
    }
    
    func setupUserProfileImage(tileCell: TileCell, member: CallMember, isLastRow: Bool) {
        
        if let profileDetail = ContactManager.shared.getUserProfileDetails(for: member.jid) {
            
            let profileImageStr = profileDetail.thumbImage.isEmpty ? profileDetail.image : profileDetail.thumbImage
            
            tileCell.profileImageView.loadFlyImage(imageURL: profileImageStr, name: getUserName(jid : profileDetail.jid ,name: profileDetail.name, nickName: profileDetail.nickName, contactType: profileDetail.contactType), chatType: profileDetail.profileChatType,contactType: profileDetail.contactType, jid: profileDetail.jid, isBlockedByAdmin: ContactManager.shared.getUserProfileDetails(for: profileDetail.jid)?.isBlockedByAdmin ?? false)
            
            if !profileImageStr.isEmpty {
                tileCell.profileImageView.contentMode = .scaleAspectFill
            }else{
                Utility.IntialLetter(name: profileDetail.nickName, imageView: tileCell.profileImageView, colorCode: member.color,frameSize: 128,fontSize: 32)
            }
            
            if member.jid == AppUtils.getMyJid() {
                tileCell.profileName.text = "You"
            }else{
                tileCell.profileName.text = profileDetail.nickName
            }
            
        }else {
            
            let (userName, profileImg) = CallManager.getUserNameAndImage(userId: member.jid)
            Utility.IntialLetter(name: member.name, imageView: tileCell.profileImageView, colorCode: member.color,frameSize: 128,fontSize: 64)
            Utility.download(token: profileImg, profileImage: tileCell.profileImageView, uniqueId: member.jid,name: userName,colorCode: member.color,frameSize: 128,fontSize: 32,notify: true, completion: {
            })
            
            try? ContactManager.shared.getUserProfile(for:  member.jid, fetchFromServer: true) { isSuccess, error, data in
                if isSuccess{
                    print("#profile is fetched")
                }
            }
            if member.jid == AppUtils.getMyJid() {
                tileCell.profileName.text = "You"
            }else{
                tileCell.profileName.text = userName
            }
        }
    }
    
    func removeRenderView(tileCell: TileCell) {
        
        if let videoView = tileCell.videoBaseView {
            for view in videoView.subviews {
                view.removeFromSuperview()
                videoView.willRemoveSubview(view)
            }
        }
    }
    
    func addVideoTrackToCell(tileCell: TileCell, member: CallMember) {
        print("member ==>\(String(describing: member.jid)) and video Status ==>\(member.isVideoMuted)")
        if (CallManager.getCallMode() == .ONE_TO_ONE && !member.isVideoMuted && CallManager.getCallType() == .Video) || (CallManager.getCallMode() == .ONE_TO_MANY && !member.isVideoMuted) || (CallManager.getCallType() == .Video && !member.isVideoMuted  && (member.callStatus == .connected)) {
            
            #if arch(arm64)
            let localRen = RTCMTLVideoView(frame: .zero)
            #else
            let localRen = RTCEAGLVideoView(frame: .zero)
            #endif
            if let baseView = tileCell.videoBaseView {
                print("#call addGroupTracks addVideoTrackToCell TileCell")
                if let videoView = tileCell.videoBaseView, let track = CallManager.getRemoteVideoTrack(jid: member.jid) {
                    
                    track.remove(member.videoTrackView)
                    member.videoTrackView.removeFromSuperview()
                    videoView.willRemoveSubview(member.videoTrackView)
                }
                
                member.videoTrackView = localRen
                member.videoTrackView.frame = CGRect(x: 0, y: 0, width: baseView.bounds.width, height: baseView.bounds.height)
                if member.jid == AppUtils.getMyJid() {
                    let track = CallManager.getRemoteVideoTrack(jid: member.jid)
                    member.videoTrack = track
                    track?.add(member.videoTrackView)
                    //member.videoTrack?.add(member.videoTrackView)
                } else {
                    let videoTrack = CallManager.getRemoteVideoTrack(jid: member.jid)
                    videoTrack?.add(member.videoTrackView)
                }
                baseView.addSubview(member.videoTrackView)
            }
        }
    }
}
