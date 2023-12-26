//  ImageCell.swift
//  MirrorflyUIkit
//  Created by User on 03/09/21.

import UIKit
import MirrorFlySDK

class ImageCell: UICollectionViewCell, UIScrollViewDelegate {
    
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var zoomScroll: UIScrollView?
    @IBOutlet weak var videoPlayButton: UIButton?
    @IBOutlet weak var audioButton: UIButton!
    @IBOutlet weak var audioImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupUI()
    }
    
    func setupUI() {
        zoomScroll?.maximumZoomScale = 5.0
        zoomScroll?.minimumZoomScale = 1.0
        zoomScroll?.clipsToBounds = false
        zoomScroll?.delegate = self
    }
    func getCellFor(_ message: ChatMessage?, at indexPath: IndexPath?) -> ImageCell? {
        switch message?.messageType {
        case .image,.video,.audio:
           setUIImage(message: message)
        default:
            break
        }
        cellImage.contentMode = .scaleAspectFit
        return self
    }
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if scrollView.zoomScale > 1 {
            if let image = cellImage.image {
                let ratioW = cellImage.frame.width / image.size.width
                let ratioH = cellImage.frame.height / image.size.height
                
                let ratio = ratioW < ratioH ? ratioW : ratioH
                let newWidth = image.size.width * ratio
                let newHeight = image.size.height * ratio
                let conditionLeft = newWidth*scrollView.zoomScale > cellImage.frame.width
                let left = 0.5 * (conditionLeft ? newWidth - cellImage.frame.width : (scrollView.frame.width - scrollView.contentSize.width))
                let conditioTop = newHeight*scrollView.zoomScale > cellImage.frame.height
                
                let top = 0.5 * (conditioTop ? newHeight - cellImage.frame.height : (scrollView.frame.height - scrollView.contentSize.height))
                
                scrollView.contentInset = UIEdgeInsets(top: top, left: left, bottom: top, right: left)
                
            }
        } else {
            scrollView.contentInset = .zero
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
           return cellImage
    }
    
    func setUIImage(message: ChatMessage?) {
        if message?.messageType == .audio {
            cellImage.image = nil
            cellImage.backgroundColor = Color.color_97A5C7
            if message?.mediaChatMessage?.audioType == AudioType.recording {
                audioImage.image = UIImage(named: "ic_white_mic")
            } else {
                audioImage.image = UIImage(named: "ic_white_headeset")
            }
        } else {
            cellImage.backgroundColor = .clear
            if let localPath = message?.mediaChatMessage?.mediaFileName {
                if let directoryURL: URL = FlyUtils.getGroupContainerIDPath() {
                    let folderPath: URL = directoryURL.appendingPathComponent("FlyMedia/Image", isDirectory: true)
                    let fileURL: URL = folderPath.appendingPathComponent(localPath)
                    if FileManager.default.fileExists(atPath:fileURL.relativePath) {
                        let data = NSData(contentsOf: fileURL)
                        let image = UIImage(data: data! as Data)
                        cellImage.image = image
                    }else {
                        if let thumImage = message?.mediaChatMessage?.mediaThumbImage {
                            let converter = ImageConverter()
                            let image =  converter.base64ToImage(thumImage)
                            cellImage.image = image
                        }
                    }
                }
            } else {
                if let thumImage = message?.mediaChatMessage?.mediaThumbImage {
                    let converter = ImageConverter()
                    let image =  converter.base64ToImage(thumImage)
                    cellImage.image = image
                }
            }
        }
        
    }
}
