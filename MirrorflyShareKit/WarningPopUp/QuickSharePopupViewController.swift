//
//  QuickShareWarningPopViewController.swift
//  MirrorflyShareKit
//
//  Created by Sowmiya on 06/03/23.
//

import UIKit
import MirrorFlySDK
import Photos
import Social
import CoreServices


class QuickSharePopupViewController : ShareKitBaseViewController {
    @IBOutlet weak var quickShareTableView: UITableView?
    @IBOutlet weak var contentView: UIView?
    var shareDelegate : ShareKitDelegate? = nil
    var mediaFiles : [ShareData] = [ShareData]()
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        contentView?.roundCorners(corners: [.topLeft,.topRight,.bottomLeft,.bottomRight], radius: 10.0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
    }
    
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: true,completion: nil)
    }
    
    @IBAction func removeButtonTapped(_ sender: Any) {
        dismiss(animated: true) { [weak self] in
            self?.shareDelegate?.removeData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        quickShareTableView?.reloadData()
    }
    
    private func setUpUI() {
        quickShareTableView?.register(UINib(nibName: Identifiers.warningCell, bundle: nil), forCellReuseIdentifier: Identifiers.warningCell)
        quickShareTableView?.delegate = self
        quickShareTableView?.dataSource = self
    }
    
    private func thumbnailForVideoAtURL(url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let assetImageGenerator = AVAssetImageGenerator(asset: asset)
        var time = asset.duration
        time.value = min(time.value, 2)
        do {
            let imageRef = try assetImageGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: imageRef)
        } catch {
            print("error")
            return nil
        }
    }
}

extension QuickSharePopupViewController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mediaFiles.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.warningCell,for: indexPath) as? WarningCell
        guard mediaFiles.count > 0 else {
            return UITableViewCell()
        }
        let attachment = mediaFiles[indexPath.row]
        //if let data = try? Data(contentsOf: attachment.url!) {

        guard let sharedURL = attachment.url else {

            guard let data = attachment.data else { return UITableViewCell() }
            //if let data = attachment.data {
                let size = Double(data.count / 1000)
                let fileSize = Double(Double(size / 1000) / 1000)


                var maxSize = Int()
                switch attachment.contentType {
                case .video:
                    cell?.mediaFile?.image = thumbnailForVideoAtURL(url: attachment.url ?? URL(fileURLWithPath: ""))
                    maxSize = 2048
                case .document:
                    maxSize = 2048
                    cell?.mediaFile?.contentMode = .scaleAspectFit
                    ShareKitUtility.shared.checkFileType(url: attachment.url?.absoluteString ?? "", typeImageView: cell?.mediaFile)
                case .audio:
                    maxSize = 2048
                    cell?.mediaFile?.image = UIImage(named: "audio")
                default:
                    maxSize = 40
                    cell?.mediaFile?.contentMode = .scaleAspectFill
                    cell?.mediaFile?.image = attachment.thumbImage
                }

                cell?.TitleLabel?.text = attachment.url?.lastPathComponent
                cell?.fileTypeLabel?.text = attachment.url?.pathExtension
                switch attachment.contentType {
                case .video:
                    let asset = AVAsset(url: ((attachment.url ?? URL(string: ""))!))
                    let duration = asset.duration
                    let durationSeconds = CMTimeGetSeconds(duration)
                    let durationMin = (Int(durationSeconds) / 60) % 60
                    let durationSec = Int(durationSeconds) % 60
                    cell?.durationLabel?.text = "\(durationMin)m \(durationSec)s"
                    cell?.durationLabel?.isHidden = false
                default:
                    cell?.durationLabel?.isHidden = true
                }
            let sizeString = attachment.contentType == .image ? "\(maxSize)MB" : "\(maxSize)GB"
                cell?.errorLabel?.text = attachment.invalidType == .size ? "File size is too large. Try uploading file size below \(sizeString)" : attachment.contentType == .document ? unSupportedFileFormate : unsupportedFile
                cell?.fileSizeLabel?.text = String(describing: "\(fileSize.roundTo2f())MB")
                cell?.backgroundColor = .white
                cell?.selectionStyle = .none
                return cell ?? UITableViewCell()
            //}

        }
        //if let data = try? Data(contentsOf: sharedURL) {
        //let data = Data()

        let resource = try? sharedURL.resourceValues(forKeys:[.fileSizeKey])
        let pathExtension = sharedURL.pathExtension
        let size = Double(resource?.fileSize ?? 0 / 1000)
        let fileSize = Double(Double(size / 1000) / 1000)
        
        var maxSize = Int()
        switch attachment.contentType {
        case .video:
            cell?.mediaFile?.image = thumbnailForVideoAtURL(url: attachment.url ?? URL(fileURLWithPath: ""))
            maxSize = 2048
        case .document:
            cell?.mediaFile?.contentMode = .scaleAspectFit
            ShareKitUtility.shared.checkFileType(url: attachment.url?.absoluteString ?? "", typeImageView: cell?.mediaFile)
            maxSize = 2048
        case .audio:
            cell?.mediaFile?.image = UIImage(named: "audio")
            maxSize = 2048
        default:
            cell?.mediaFile?.contentMode = .scaleAspectFill
            cell?.mediaFile?.image = ShareMediaUtils.downsample(imageAt: sharedURL, to: cell?.mediaFile?.bounds.size ?? CGSize(width: 70, height: 70))
            maxSize = 40
        }

        cell?.TitleLabel?.text = attachment.url?.lastPathComponent
        cell?.fileTypeLabel?.text = attachment.url?.pathExtension
        switch attachment.contentType {
        case .video:
            let asset = AVAsset(url: ((attachment.url ?? URL(string: ""))!))
            let duration = asset.duration
            let durationSeconds = CMTimeGetSeconds(duration)
            let durationMin = (Int(durationSeconds) / 60) % 60
            let durationSec = Int(durationSeconds) % 60
            cell?.durationLabel?.text = "\(durationMin)m \(durationSec)s"
            cell?.durationLabel?.isHidden = false
        default:
            cell?.durationLabel?.isHidden = true
        }
        let sizeString = attachment.contentType == .image ? "\(maxSize)MB" : "\(maxSize)GB"
        cell?.errorLabel?.text = attachment.invalidType == .size ? "File size is too large. Try uploading file size below \(sizeString)" : attachment.contentType == .document ? unSupportedFileFormate : unsupportedFile
        cell?.fileSizeLabel?.text = String(describing: "\(fileSize.roundTo2f())MB")
        cell?.backgroundColor = .white
        cell?.selectionStyle = .none
        return cell ?? UITableViewCell()
        //}
        //return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
