//
//  ImageViewerViewController.swift
//  MirrorflyUIkit
//
//  Created by User on 17/08/21.
//

import Foundation
import UIKit
import MirrorFlySDK

class ImageViewerViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    var getProfileImage: UIImage!
    var profileDetailsImage: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if getProfileImage != nil {
            imageView.image = getProfileImage
        } else {
            setImage(imageURL: profileDetailsImage ?? "")
        }
        scrollView.maximumZoomScale = 20
        scrollView.minimumZoomScale = 1
        scrollView.delegate = self
        
        
    }
    @IBAction func onBackButton(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        self.navigationController?.setNavigationBarHidden(true, animated: animated)
//    }
//    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        self.navigationController?.setNavigationBarHidden(false, animated: animated)
//    }
    
    func setImage(imageURL: String) {
        let urlString = ChatManager.getImageUrl(imageName: imageURL)
        let url = URL(string: urlString)
        imageView.sd_setImage(with: url, placeholderImage: #imageLiteral(resourceName: "ic_profile_placeholder"))
    }
    
}

extension ImageViewerViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
           return imageView
    }
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if scrollView.zoomScale > 1 {
            if let image = imageView.image {
                let ratioW = imageView.frame.width / image.size.width
                let ratioH = imageView.frame.height / image.size.height
                
                let ratio = ratioW < ratioH ? ratioW : ratioH
                let newWidth = image.size.width * ratio
                let newHeight = image.size.height * ratio
                let conditionLeft = newWidth*scrollView.zoomScale > imageView.frame.width
                let left = 0.5 * (conditionLeft ? newWidth - imageView.frame.width : (scrollView.frame.width - scrollView.contentSize.width))
                let conditioTop = newHeight*scrollView.zoomScale > imageView.frame.height
                
                let top = 0.5 * (conditioTop ? newHeight - imageView.frame.height : (scrollView.frame.height - scrollView.contentSize.height))
                
                scrollView.contentInset = UIEdgeInsets(top: top, left: left, bottom: top, right: left)
                
            }
        } else {
            scrollView.contentInset = .zero
        }
    }
    
}
