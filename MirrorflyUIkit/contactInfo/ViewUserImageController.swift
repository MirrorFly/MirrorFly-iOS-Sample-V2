//
//  ViewUserImamgeController.swift
//  MirrorflyUIkit
//
//  Created by John on 31/01/22.
//

import UIKit
import MirrorFlySDK
import SDWebImage

class ViewUserImageController: ViewController {
   
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var closeButton: UIButton?
    @IBOutlet weak var userImage: UIImageView?
    var profileDetails : ProfileDetails?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        setInformation()
        // Do any additional setup after loading the view.
    }
    
    private func setUpUI() {
        setUpStatusBar()
    }
    
    private func setInformation() {
        let name = getUserName(jid: profileDetails?.jid ?? "",name: profileDetails?.name ?? "", nickName: profileDetails?.nickName ?? "", contactType : profileDetails?.contactType ?? .unknown)
        let placeholder = ChatUtils.getPlaceholder(name: profileDetails?.name ?? "", userColor: ChatUtils.getColorForUser(userName: name), userImage: userImage ?? UIImageView())
        let imageUrl = profileDetails?.image  ?? ""
        userImage?.loadFlyImage(imageURL: imageUrl, name: name, chatType: profileDetails?.profileChatType ?? .singleChat, jid: profileDetails?.jid ?? "")
        
        titleLabel?.text = name
    }
    
    @IBAction func onClose(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    

}
