//
//  AutodownloadSelectionViewController.swift
//  MirrorflyUIkit
//
//  Created by Ramakrishnan on 01/11/22.
//

import UIKit
import SwiftUI
import MirrorFlySDK

struct  DownlaodList {
    var isopened = false
    var sectionTitle = [NetworkType]()
    var sectionValues = [MessageDownloadType]()
}

enum MessageDownloadType : String , CaseIterable{
    case Photos
    case Videos
    case Audios
    case Documents
}

enum NetworkType : String,CaseIterable{
    case mobileData = "When using Mobile Data"
    case wifi = "When connected on Wi-Fi"
}

class AutodownloadSelectionViewController: UIViewController {
    
    var sectionlist = NetworkType.allCases
    var downloadfiles = MessageDownloadType.allCases
    var sectionName = [DownlaodList]()
    
    @IBOutlet weak var autoDownloadTableview: UITableView!
    
    override func viewDidLoad() {        super.viewDidLoad()
        self.autoDownloadTableview.delegate = self

        self.autoDownloadTableview.dataSource = self
        sectionName = [DownlaodList(isopened: false, sectionTitle:sectionlist, sectionValues: downloadfiles),DownlaodList(isopened: false, sectionTitle:sectionlist, sectionValues: downloadfiles)]
        
        autoDownloadTableview.reloadData()
    }
    
    @IBAction func onTapBack(_ sender: UIButton) {
        
        self.navigationController?.popViewController(animated: true)
    }
}

extension AutodownloadSelectionViewController : UITableViewDelegate,UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionName.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let SectionTitleView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 30))
        SectionTitleView.backgroundColor = UIColor.clear
        let Label = UILabel(frame: CGRect(x: 20, y: 5, width: SectionTitleView.frame.width - 80, height: 30))
        let dropDown = UIButton(frame: CGRect(x: Label.frame.width + 30, y: 5, width: 40, height: 30))
        dropDown.setImage(UIImage(named: ImageConstant.down_arrow), for: .normal)
        dropDown.setImage(UIImage(named: ImageConstant.up_arrow), for: .selected)
        dropDown.isSelected =  sectionName[section].isopened ? true : false
        dropDown.backgroundColor = UIColor.clear
        dropDown.isUserInteractionEnabled = false
        Label.backgroundColor = UIColor.clear
        Label.text = sectionlist[section].rawValue
        SectionTitleView.isUserInteractionEnabled = true
        Label.textColor = Color.recentChatTextColor
        Label.font = AppFont.Regular.size(12)
        SectionTitleView.addSubview(Label)
        SectionTitleView.addSubview(dropDown)
        let tap = UITapGestureRecognizer(target: self, action: #selector(checkAction(_:)))
        SectionTitleView.addGestureRecognizer(tap)
        SectionTitleView.tag = section
        let SectionBorderView = UIView(frame: CGRect(x: 20, y: SectionTitleView.frame.height + 20, width: tableView.frame.width - 10, height: 0.5))
        SectionBorderView.backgroundColor = Color.recentChatSelectionColor
        SectionBorderView.isHidden = sectionName[section].isopened ? true : false
        SectionTitleView.addSubview(SectionBorderView)
        return SectionTitleView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if  sectionName[section].isopened {
            return sectionName[section].sectionValues.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AutodownloadsTableViewCell", for: indexPath) as! AutodownloadsTableViewCell
        
        if indexPath.section == 0 {
            let autoDownloadMobile = ChatManager.autoDownloadMobileConfig()
            cell.labeltitle.text = sectionName[indexPath.section].sectionValues[indexPath.row].rawValue
            
            switch sectionName[0].sectionValues[indexPath.row] {
            case .Photos:
                cell.selectedImageoutlet.image = getSelectedImage(isselected: autoDownloadMobile[AutoDownloadType.photo.rawValue] ?? false)
            case .Videos:
                cell.selectedImageoutlet.image =   getSelectedImage(isselected: autoDownloadMobile[AutoDownloadType.videos.rawValue] ?? false)
            case .Audios:
                cell.selectedImageoutlet.image =  getSelectedImage(isselected: autoDownloadMobile[AutoDownloadType.audio.rawValue] ?? false)
            case .Documents:
                cell.selectedImageoutlet.image =  getSelectedImage(isselected: autoDownloadMobile[AutoDownloadType.documents.rawValue] ?? false)
         
                break
            }
            
        }
        else{
            let autoDownloadWiFi = ChatManager.autoDownloadWiFiConfig()
            cell.labeltitle.text = sectionName[indexPath.section].sectionValues[indexPath.row].rawValue
            switch sectionName[1].sectionValues[indexPath.row] {
            case .Photos:
                cell.selectedImageoutlet.image = getSelectedImage(isselected: autoDownloadWiFi[AutoDownloadType.photo.rawValue] ?? false )
            case .Videos:
                cell.selectedImageoutlet.image = getSelectedImage(isselected: autoDownloadWiFi[AutoDownloadType.videos.rawValue] ?? false)
            case .Audios:
                cell.selectedImageoutlet.image = getSelectedImage(isselected: autoDownloadWiFi[AutoDownloadType.audio.rawValue] ?? false)
            case .Documents:
                cell.selectedImageoutlet.image = getSelectedImage(isselected: autoDownloadWiFi[AutoDownloadType.documents.rawValue] ?? false)
           
                break
            }
            
        }
        
        cell.viewoutlet.isHidden = (indexPath.row == sectionName[indexPath.section].sectionValues.count - 1) ? false : true
        return  cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.section {
        case 0:
            switch sectionName[0].sectionValues[indexPath.row] {
                
            case .Photos:
                let status = ChatManager.autoDownloadMobileConfig()[AutoDownloadType.photo.rawValue] ?? false
                ChatManager.updateAutoDownloadMobile(type: .photo, enable: !status)
            case .Videos:
                let status = ChatManager.autoDownloadMobileConfig()[AutoDownloadType.videos.rawValue] ?? false
                ChatManager.updateAutoDownloadMobile(type: .videos, enable: !status)
            case .Audios:
                let status = ChatManager.autoDownloadMobileConfig()[AutoDownloadType.audio.rawValue] ?? false
                ChatManager.updateAutoDownloadMobile(type: .audio, enable: !status)
            case .Documents:
                let status = ChatManager.autoDownloadMobileConfig()[AutoDownloadType.documents.rawValue] ?? false
                ChatManager.updateAutoDownloadMobile(type: .documents, enable: !status)
            }
        case 1:
            switch sectionName[1].sectionValues[indexPath.row] {
               
            case .Photos:
                let status = ChatManager.autoDownloadWiFiConfig()[AutoDownloadType.photo.rawValue] ?? false
                ChatManager.updateAutoDownloadWiFi(type: .photo, enable: !status)
            case .Videos:
                let status = ChatManager.autoDownloadWiFiConfig()[AutoDownloadType.videos.rawValue] ?? false
                ChatManager.updateAutoDownloadWiFi(type: .videos, enable: !status)
            case .Audios:
                let status = ChatManager.autoDownloadWiFiConfig()[AutoDownloadType.audio.rawValue] ?? false
                ChatManager.updateAutoDownloadWiFi(type: .audio, enable: !status)
            case .Documents:
                let status = ChatManager.autoDownloadWiFiConfig()[AutoDownloadType.documents.rawValue] ?? false
                ChatManager.updateAutoDownloadWiFi(type: .documents, enable: !status)
            }
        default:
            break
        }
        
        
        self.autoDownloadTableview.reloadData()
    }
    
    func getSelectedImage(isselected : Bool) -> UIImage? {
        return isselected ? UIImage(named: ImageConstant.ic_selected) : UIImage(named: ImageConstant.Translate_Unselected)
    }
    
    @objc func checkAction(_ sender : UITapGestureRecognizer) {
        sectionName[sender.view!.tag].isopened = !sectionName[sender.view!.tag].isopened
        self.autoDownloadTableview.reloadData()
    }
    
}
