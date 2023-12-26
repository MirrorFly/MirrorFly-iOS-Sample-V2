//
//  EditImageCell.swift
//  MirrorflyShareKit
//
//  Created by Sowmiya on 01/03/23.
//
import UIKit

class EditImageCell: UICollectionViewCell, UIScrollViewDelegate {
    @IBOutlet weak var zoomScroll: UIScrollView?
    @IBOutlet weak var cellImage: UIImageView?
    @IBOutlet weak var playButton: UIButton?
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
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if scrollView.zoomScale > 1 {
            if let image = cellImage?.image {
                let ratioW = cellImage?.frame.width ?? 0.0 / image.size.width
                let ratioH = cellImage?.frame.height ?? 0.0 / image.size.height
                
                let ratio = ratioW < ratioH ? ratioW : ratioH
                let newWidth = image.size.width * ratio
                let newHeight = image.size.height * ratio
                let conditionLeft = newWidth*scrollView.zoomScale > cellImage?.frame.width ?? 0.0
                let left = 0.5 * (conditionLeft ? newWidth - (cellImage?.frame.width ?? 0.0) : (scrollView.frame.width - scrollView.contentSize.width))
                let conditioTop = newHeight*scrollView.zoomScale > cellImage?.frame.height ?? 0.0
                
                let top = 0.5 * (conditioTop ? newHeight - (cellImage?.frame.height ?? 0.0) : (scrollView.frame.height - scrollView.contentSize.height))
                
                scrollView.contentInset = UIEdgeInsets(top: top, left: left, bottom: top, right: left)
                
            }
        } else {
            scrollView.contentInset = .zero
        }
    }
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
           return cellImage
    }
}
