//
//  Menu.swift
//  contextMenus
//
//  Created by Amose Vasanth on 21/11/22.
//

import UIKit
import MirrorFlySDK

public protocol ContextMenuItem {
    var title : String {
        get
    }
    var image : UIImage? {
        get
    }
}

extension ContextMenuItem {
    public var image: UIImage? {
        get { return nil }
    }
}

extension String : ContextMenuItem {
    public var title: String {
        get {
            return "\(self)"
        }
    }
}
public struct ContextMenuItemWithImage: ContextMenuItem {
    public var title: String
    public var image: UIImage?

    public init(title: String, image: UIImage) {
        self.title = title
        self.image = image
    }
}

public protocol ContextMenuDelegate : AnyObject {
    func contextMenuDidSelect(_ contextMenu: ContextMenu, cell: ContextMenuCell, targetedView: UIView, didSelect item: ContextMenuItem, forRowAt index: Int) -> Bool
    func contextMenuDidDeselect(_ contextMenu: ContextMenu, cell: ContextMenuCell, targetedView: UIView, didSelect item: ContextMenuItem, forRowAt index: Int)
    func contextMenuDidAppear(_ contextMenu: ContextMenu)
    func contextMenuDidDisappear(_ contextMenu: ContextMenu)
    func contextMenuDidMentionSelect(_ contextMenu: ContextMenu, jid: String, profileDetail: ProfileDetails)

}
extension ContextMenuDelegate {
    func contextMenuDidAppear(_ contextMenu: ContextMenu){}
    func contextMenuDidDisappear(_ contextMenu: ContextMenu){}
}

public var CM : ContextMenu = ContextMenu()

public struct ContextMenuConstants {
    public var MaxZoom : CGFloat = 1.15
    public var MinZoom : CGFloat = 0.9
    public var MenuDefaultHeight : CGFloat = 120
    public var MenuWidth : CGFloat = 250
    public var MenuMarginSpace : CGFloat = 20
    public var TopMarginSpace : CGFloat = 40
    public var BottomMarginSpace : CGFloat = 24
    public var HorizontalMarginSpace : CGFloat = 20
    public var ItemDefaultHeight : CGFloat = 35

    public var LabelDefaultFont : UIFont = .systemFont(ofSize: 14)
    public var LabelDefaultColor : UIColor = UIColor.black.withAlphaComponent(0.95)
    public var ItemDefaultColor : UIColor = UIColor.white.withAlphaComponent(0.95)

    public var MenuCornerRadius : CGFloat = 12
    public var BlurEffectEnabled : Bool = true
    public var BlurEffectDefault : UIBlurEffect = UIBlurEffect(style: .dark)
    public var BackgroundViewColor : UIColor = UIColor.black.withAlphaComponent(0.6)

    public var DismissOnItemTap : Bool = false
}

open class ContextMenu: NSObject {

    // MARK:- open Variables
    open var MenuConstants = ContextMenuConstants()
    open var viewTargeted: UIView!
    open var placeHolderView : UIView?
    open var headerView : UIView?
    open var footerView : UIView?
    open var nibView = UINib(nibName: ContextMenuCell.identifier, bundle: Bundle(for: ContextMenuCell.self))
    open var closeAnimation = false

    open var onItemTap : ((_ index: Int, _ item: ContextMenuItem) -> Bool)?
    open var onViewAppear : ((UIView) -> Void)?
    open var onViewDismiss : ((UIView) -> Void)?

    open var items = [ContextMenuItem]()

    // MARK:- Private Variables
    private weak var delegate : ContextMenuDelegate?

    private var mainViewRect : CGRect
    private var customView = UIView()
    private var blurEffectView = UIVisualEffectView()
    private var closeButton = UIButton()
    private var targetedImageView = UIImageView()
    private var menuView = UIView()
    public var tableView = UITableView()
    private var tableViewConstraint : NSLayoutConstraint?
    private var zoomedTargetedSize = CGRect()

    private var menuHeight : CGFloat = 180
    private var isLandscape : Bool = false

    private var touchGesture : UITapGestureRecognizer?
    private var closeGesture : UITapGestureRecognizer?

    private var tvH : CGFloat = 0.0
    private var tvW : CGFloat = 0.0
    private var tvY : CGFloat = 0.0
    private var tvX : CGFloat = 0.0
    private var mH : CGFloat = 0.0
    private var mW : CGFloat = 0.0
    private var mY : CGFloat = 0.0
    private var mX : CGFloat = 0.0
    private var safeAreaTop : CGFloat = 0.0
    private var safeAreaBottom : CGFloat = 0.0
    public var mentionTableView: UITableView?
    public var scrollView = UIScrollView(frame: .zero)
    public var searchGroupMembers = [GroupParticipantDetail]()

    
    // MARK:- Init Functions
    public init(window: UIView? = nil) {
        let wind = window ?? UIApplication.shared.windows.first ?? UIApplication.shared.keyWindow
        self.customView = wind!
        self.mainViewRect = wind!.frame
        self.safeAreaTop = wind?.safeAreaInsets.top ?? 0
        self.safeAreaBottom = wind?.safeAreaInsets.bottom ?? 0
    }

    init?(viewTargeted: UIView, window: UIView? = nil) {
        if let wind = window ?? UIApplication.shared.windows.first ?? UIApplication.shared.keyWindow {
            self.customView = wind
            self.viewTargeted = viewTargeted
            self.mainViewRect = self.customView.frame
        }else{
            return nil
        }
    }

    init(viewTargeted: UIView, window: UIView) {
        self.viewTargeted = viewTargeted
        self.customView = window
        self.mainViewRect = window.frame
    }

    deinit {
        print("Deinit")
    }

    // MARK:- Show, Change, Update Menu Functions
    open func showMenu(viewTargeted: UIView, delegate: ContextMenuDelegate, animated: Bool = true, position:Int, _ view: UIView = UIView()){
        //DispatchQueue.main.async {
        self.delegate = delegate
        self.viewTargeted = viewTargeted
        if !self.items.isEmpty {
            self.menuHeight = (CGFloat(self.items.count) * self.MenuConstants.ItemDefaultHeight) + (self.headerView?.frame.height ?? 0) + (self.footerView?.frame.height ?? 0) // + CGFloat(self.items.count - 1)
        }else{
            self.menuHeight = self.MenuConstants.MenuDefaultHeight
        }
        self.addBlurEffectView()
        self.addMenuView()
        self.addTargetedImageView()
        self.openAllViews(position: position, view: view)
        //}
    }

    open func closeMenu(){
        self.closeAllViews()
    }
    
    open func closeOnlyMenu() {
        self.menuView.removeFromSuperview()
    }

    open func closeMenu(withAnimation animation: Bool) {
        closeAllViews(withAnimation: animation)
    }

    func addBlurEffectView(){

        if !customView.subviews.contains(blurEffectView) {
            customView.addSubview(blurEffectView)
        }
        if MenuConstants.BlurEffectEnabled {
            blurEffectView.effect = MenuConstants.BlurEffectDefault
            blurEffectView.backgroundColor = .clear
        }else{
            blurEffectView.effect = nil
            blurEffectView.backgroundColor = MenuConstants.BackgroundViewColor
        }

        blurEffectView.frame = CGRect(x: mainViewRect.origin.x, y: mainViewRect.origin.y, width: mainViewRect.width, height: mainViewRect.height)
        if closeGesture == nil {
            blurEffectView.isUserInteractionEnabled = true
            closeGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissViewAction(_:)))
            blurEffectView.addGestureRecognizer(closeGesture!)
        }
    }

    @objc func dismissViewAction(_ sender: UITapGestureRecognizer? = nil){
        self.closeAllViews()
    }

    func addCloseButton(){

        if !customView.subviews.contains(closeButton) {
            customView.addSubview(closeButton)
        }
        closeButton.frame = CGRect(x: mainViewRect.origin.x, y: mainViewRect.origin.y, width: mainViewRect.width, height: mainViewRect.height)
        closeButton.setTitle("", for: .normal)
        closeButton.actionHandler(controlEvents: .touchUpInside) { //[weak self] in
            self.closeAllViews()
        }
    }

    func addTargetedImageView(){

        if !customView.subviews.contains(targetedImageView) {
            customView.addSubview(targetedImageView)
        }

        let rect = viewTargeted.convert(mainViewRect.origin, to: nil)
        targetedImageView.contentMode = .scaleAspectFill
        targetedImageView.image = viewTargeted.image()
        targetedImageView.frame = CGRect(x: rect.x,
                                         y: rect.y,
                                         width: viewTargeted.frame.width,
                                         height: viewTargeted.frame.height)
        targetedImageView.layer.shadowColor = UIColor.black.cgColor
        targetedImageView.layer.shadowRadius = 16
        targetedImageView.layer.shadowOpacity = 0
        targetedImageView.isUserInteractionEnabled = true

        closeGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissViewAction(_:)))
        targetedImageView.addGestureRecognizer(closeGesture!)

    }

    func addMenuView(){

        if !customView.subviews.contains(menuView) {
            customView.addSubview(menuView)
            tableView = UITableView()
        }else{
            tableView.removeFromSuperview()
            tableView = UITableView()
        }

        let rect = viewTargeted.convert(mainViewRect.origin, to: nil)

        menuView.backgroundColor = MenuConstants.ItemDefaultColor
        menuView.layer.cornerRadius = MenuConstants.MenuCornerRadius
        menuView.clipsToBounds = true
        menuView.frame = CGRect(x: rect.x,
                                y: rect.y,
                                width: self.viewTargeted.frame.width, height: self.viewTargeted.frame.height)
        menuView.addSubview(tableView)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = menuView.bounds
        tableView.register(self.nibView, forCellReuseIdentifier: "ContextMenuCell")
        tableView.tableHeaderView = self.headerView
        tableView.tableFooterView = self.footerView
        tableView.clipsToBounds = true
        tableView.isScrollEnabled = false
        tableView.alwaysBounceVertical = false
        tableView.allowsMultipleSelection = false
        tableView.backgroundColor = .clear
        tableView.reloadData()

    }

    func openAllViews(animated: Bool = false, position: Int, view: UIView = UIView()){
        let rect = self.viewTargeted.convert(self.mainViewRect.origin, to: nil)
        viewTargeted.alpha  = 1
        //        customView.backgroundColor = .clear
        blurEffectView.alpha  = 1
        closeButton.isUserInteractionEnabled = true
        targetedImageView.alpha = 1
        targetedImageView.layer.shadowOpacity = 0.0
        targetedImageView.isUserInteractionEnabled = true
        targetedImageView.frame = CGRect(x: rect.x, y: rect.y, width: self.viewTargeted.frame.width, height: self.viewTargeted.frame.height)
        menuView.alpha  = 1
        menuView.isUserInteractionEnabled = true
        //        menuView.transform = CGAffineTransform.identity.scaledBy(x: 0, y: 0)
        menuView.frame = CGRect(x: rect.x, y: rect.y, width: self.viewTargeted.frame.width, height: self.viewTargeted.frame.height)

        if animated {
            UIView.animate(withDuration: 0.2) {
                self.blurEffectView.alpha = 1
                self.targetedImageView.layer.shadowOpacity = 0.2
            }
        }else{
            self.blurEffectView.alpha = 1
            self.targetedImageView.layer.shadowOpacity = 0.2
        }
        self.updateTargetedImageViewPosition(animated: animated, position: position, view)
        self.onViewAppear?(self.viewTargeted)
        self.customView.bringSubviewToFront(menuView)
        self.delegate?.contextMenuDidAppear(self)
    }

    func closeAllViews(){
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        self.targetedImageView.isUserInteractionEnabled = false
        self.menuView.isUserInteractionEnabled = false
        self.closeButton.isUserInteractionEnabled = false
        self.targetedImageView.translatesAutoresizingMaskIntoConstraints = true

        let rect = self.viewTargeted.convert(self.mainViewRect.origin, to: nil)
        if self.closeAnimation {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 6, options: [.layoutSubviews, .preferredFramesPerSecond60, .allowUserInteraction], animations: {
                self.prepareViewsForRemoveFromSuperView(with: rect)
            }) { (_) in
                self.removeAllViewsFromSuperView()
            }
        }else{
            self.prepareViewsForRemoveFromSuperView(with: rect)
            self.removeAllViewsFromSuperView()
        }
        self.onViewDismiss?(self.viewTargeted)
        self.delegate?.contextMenuDidDisappear(self)
    }

    func closeAllViews(withAnimation animation: Bool = false) {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        DispatchQueue.main.async {
            self.targetedImageView.isUserInteractionEnabled = false
            self.menuView.isUserInteractionEnabled = false
            self.closeButton.isUserInteractionEnabled = false

            let rect = self.viewTargeted.convert(self.mainViewRect.origin, to: nil)
            if animation {
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 6, options: [.layoutSubviews, .preferredFramesPerSecond60, .allowUserInteraction], animations: {
                    self.prepareViewsForRemoveFromSuperView(with: rect)
                }) { (_) in
                    DispatchQueue.main.async {
                        self.removeAllViewsFromSuperView()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.prepareViewsForRemoveFromSuperView(with: rect)
                    self.removeAllViewsFromSuperView()
                }
            }
            self.onViewDismiss?(self.viewTargeted)
            self.delegate?.contextMenuDidDisappear(self)
        }
    }

    func prepareViewsForRemoveFromSuperView(with rect: CGPoint) {
        self.blurEffectView.alpha  = 0
        self.targetedImageView.layer.shadowOpacity = 0
        self.targetedImageView.frame = CGRect(x: rect.x, y: rect.y, width: self.viewTargeted.frame.width, height: self.viewTargeted.frame.height)
        self.menuView.alpha  = 1
        self.menuView.frame = CGRect(x: rect.x, y: rect.y, width: self.viewTargeted.frame.width, height: self.viewTargeted.frame.height)
    }

    func removeAllViewsFromSuperView() {
        self.viewTargeted?.alpha = 1
        self.targetedImageView.alpha  = 1
        self.targetedImageView.removeFromSuperview()
        self.blurEffectView.removeFromSuperview()
        self.closeButton.removeFromSuperview()
        self.menuView.removeFromSuperview()
        self.tableView.removeFromSuperview()
        self.mentionTableView?.removeFromSuperview()
        self.scrollView.removeFromSuperview()
    }

    func getZoomedTargetedSize() -> CGRect{

        let rect = viewTargeted.convert(mainViewRect.origin, to: nil)
        let targetedImageFrame = viewTargeted.frame

        let backgroundWidth = mainViewRect.width - (2 * MenuConstants.HorizontalMarginSpace)
        let backgroundHeight = mainViewRect.height - MenuConstants.TopMarginSpace - MenuConstants.BottomMarginSpace

        var zoomFactor = MenuConstants.MaxZoom

        var updatedWidth = targetedImageFrame.width // * zoomFactor
        var updatedHeight = targetedImageFrame.height // * zoomFactor

        if backgroundWidth > backgroundHeight {

            let zoomFactorHorizontalWithMenu = (backgroundWidth - MenuConstants.MenuWidth - MenuConstants.MenuMarginSpace)/updatedWidth
            let zoomFactorVerticalWithMenu = backgroundHeight/updatedHeight

            if zoomFactorHorizontalWithMenu < zoomFactorVerticalWithMenu {
                zoomFactor = zoomFactorHorizontalWithMenu
            }else{
                zoomFactor = zoomFactorVerticalWithMenu
            }
            if zoomFactor > MenuConstants.MaxZoom {
                zoomFactor = MenuConstants.MaxZoom
            }

            // Menu Height
            if self.menuHeight > backgroundHeight {
                self.menuHeight = backgroundHeight + MenuConstants.MenuMarginSpace
            }
        }else{

            let zoomFactorHorizontalWithMenu = backgroundWidth/(updatedWidth)
            let zoomFactorVerticalWithMenu = backgroundHeight/(updatedHeight + self.menuHeight + MenuConstants.MenuMarginSpace + MenuConstants.TopMarginSpace + MenuConstants.BottomMarginSpace + (CGFloat(self.items.count) * MenuConstants.ItemDefaultHeight))

            if zoomFactorHorizontalWithMenu < zoomFactorVerticalWithMenu {
                zoomFactor = zoomFactorHorizontalWithMenu
            }else{
                zoomFactor = zoomFactorVerticalWithMenu
            }
            if zoomFactor > MenuConstants.MaxZoom {
                zoomFactor = MenuConstants.MaxZoom
            }
            if zoomFactor < MenuConstants.MinZoom {
                zoomFactor = MenuConstants.MinZoom
            }
        }

        updatedWidth = (updatedWidth * zoomFactor)
        updatedHeight = (updatedHeight * zoomFactor)

        let updatedX = rect.x - (updatedWidth - targetedImageFrame.width)/2
        let updatedY = rect.y - (updatedHeight - targetedImageFrame.height)/2

        return CGRect(x: updatedX, y: updatedY, width: updatedWidth, height: updatedHeight)

    }

    func fixTargetedImageViewExtrudings(){ // here I am checking for extruding part of ImageView
        if tvY > mainViewRect.height - MenuConstants.BottomMarginSpace - tvH {
            tvY = mainViewRect.height - MenuConstants.BottomMarginSpace - tvH
        }
        else if tvY < MenuConstants.TopMarginSpace {
            tvY = MenuConstants.TopMarginSpace
        }

        if tvX < MenuConstants.HorizontalMarginSpace {
            tvX = MenuConstants.HorizontalMarginSpace
            //            mX = MenuConstants.HorizontalMarginSpace
        }
        else if tvX > mainViewRect.width - MenuConstants.HorizontalMarginSpace - tvW {
            tvX = mainViewRect.width - MenuConstants.HorizontalMarginSpace - tvW
            //            mX = mainViewRect.width - MenuConstants.HorizontalMarginSpace - mW
        }

        //        if mY
    }

    func updateHorizontalTargetedImageViewRect(){

        let rightClippedSpace = (tvW + MenuConstants.MenuMarginSpace + mW + tvX + MenuConstants.HorizontalMarginSpace) - mainViewRect.width
        let leftClippedSpace = -(tvX - MenuConstants.MenuMarginSpace - mW - MenuConstants.HorizontalMarginSpace)

        if leftClippedSpace > 0, rightClippedSpace > 0 {

            let diffY = mainViewRect.width - (mW + MenuConstants.MenuMarginSpace + tvW + MenuConstants.HorizontalMarginSpace + MenuConstants.HorizontalMarginSpace)
            if diffY > 0 {
                if (tvX + tvW/2) > mainViewRect.width/2 { //right
                    tvX = tvX + leftClippedSpace
                    mX = tvX - MenuConstants.MenuMarginSpace - mW
                }else{ //left
                    tvX = tvX - rightClippedSpace
                    mX = tvX + MenuConstants.MenuMarginSpace + tvW
                }
            }else{
                if (tvX + tvW/2) > mainViewRect.width/2 { //right
                    tvX = mainViewRect.width - MenuConstants.HorizontalMarginSpace - tvW
                    mX = MenuConstants.HorizontalMarginSpace
                }else{ //left
                    tvX = MenuConstants.HorizontalMarginSpace
                    mX = tvX + tvW + MenuConstants.MenuMarginSpace
                }
            }
        }
        else if rightClippedSpace > 0 {
            mX = tvX - MenuConstants.MenuMarginSpace - mW
        }
        else if leftClippedSpace > 0  {
            mX = tvX + MenuConstants.MenuMarginSpace  + tvW
        }
        else{
            mX = tvX + MenuConstants.MenuMarginSpace + tvW
        }

        if mH >= (mainViewRect.height - MenuConstants.TopMarginSpace - MenuConstants.BottomMarginSpace) {
            mY = MenuConstants.TopMarginSpace
            mH = (CGFloat(self.items.count) * MenuConstants.ItemDefaultHeight)
        }
        else if (tvY + mH) <= (mainViewRect.height - MenuConstants.BottomMarginSpace) {
            mY = tvY
        }
        else if (tvY + mH) > (mainViewRect.height - MenuConstants.BottomMarginSpace){
            mY = tvY - ((tvY + mH) - (mainViewRect.height - MenuConstants.BottomMarginSpace))
        }


    }

    func updateVerticalTargetedImageViewRect(){

        let bottomClippedSpace = (tvH + MenuConstants.MenuMarginSpace + mH + tvY + MenuConstants.BottomMarginSpace) - mainViewRect.height
        let topClippedSpace = -(tvY - MenuConstants.MenuMarginSpace - mH - MenuConstants.TopMarginSpace)

        // not enought space down

        if topClippedSpace > 0, bottomClippedSpace > 0 {

            let diffY = mainViewRect.height - (mH + MenuConstants.MenuMarginSpace + tvH + MenuConstants.TopMarginSpace + MenuConstants.BottomMarginSpace)
            if diffY > 0 {
                if (tvY + tvH/2) > mainViewRect.height/2 { //down
                    tvY = tvY + topClippedSpace
                    mY = tvY - MenuConstants.MenuMarginSpace - mH
                }else{ //up
                    tvY = tvY - bottomClippedSpace
                    mY = tvY + MenuConstants.MenuMarginSpace + tvH
                }
            }else{
                if (tvY + tvH/2) > mainViewRect.height/2 { //down
                    tvY = mH + MenuConstants.TopMarginSpace + MenuConstants.MenuMarginSpace
                    mY = MenuConstants.TopMarginSpace
                    mH = (CGFloat(self.items.count) * MenuConstants.ItemDefaultHeight)
                }else{ //up
                    let bufferTvHeight = mainViewRect.height - ((CGFloat(self.items.count) * MenuConstants.ItemDefaultHeight) + MenuConstants.BottomMarginSpace + MenuConstants.MenuMarginSpace)
                    let menuViewHeight = (CGFloat(self.items.count) * MenuConstants.ItemDefaultHeight)

                    tvY = tvH > bufferTvHeight ? -(tvH - bufferTvHeight) : tvY
                    mY = mainViewRect.height - ((CGFloat(self.items.count) * MenuConstants.ItemDefaultHeight) + MenuConstants.BottomMarginSpace)
                    mH = (CGFloat(self.items.count) * MenuConstants.ItemDefaultHeight)
                }
            }
        }
        else if bottomClippedSpace > 0 {
            mY = tvY - MenuConstants.MenuMarginSpace - mH
        }
        else if topClippedSpace > 0  {
            mY = tvY + MenuConstants.MenuMarginSpace  + tvH
        }
        else{
            mY = tvY + MenuConstants.MenuMarginSpace + tvH
        }

    }

    func updateTargetedImageViewRect(){

        self.mainViewRect = self.customView.frame

        let targetedImagePosition = getZoomedTargetedSize()

        let bufferHeight = mainViewRect.height - ((CGFloat(self.items.count) * MenuConstants.ItemDefaultHeight) + MenuConstants.BottomMarginSpace + MenuConstants.TopMarginSpace + MenuConstants.MenuMarginSpace)
        tvH = targetedImagePosition.height //> bufferHeight ? bufferHeight : targetedImagePosition.height
        tvW = targetedImagePosition.width
        tvY = targetedImagePosition.origin.y
        tvX = targetedImagePosition.origin.x
        mH = menuHeight
        mW = MenuConstants.MenuWidth
        mY = tvY + MenuConstants.MenuMarginSpace
        mX = MenuConstants.HorizontalMarginSpace

        self.fixTargetedImageViewExtrudings()

        let backgroundWidth = mainViewRect.width - (2 * MenuConstants.HorizontalMarginSpace)
        let backgroundHeight = mainViewRect.height - MenuConstants.TopMarginSpace - MenuConstants.BottomMarginSpace

        if backgroundHeight > backgroundWidth {
            self.updateVerticalTargetedImageViewRect()
        }
        else{
            self.updateHorizontalTargetedImageViewRect()
        }

        tableView.frame = CGRect(x: 0, y: 0, width: mW, height: mH)
        tableView.layoutIfNeeded()

    }

    func updateTargetedImageViewPosition(animated: Bool = true, position: Int, _ view: UIView = UIView()){

        self.updateTargetedImageViewRect()

        if animated {
            UIView.animate(withDuration: 0.2,
                           delay: 0,
                           usingSpringWithDamping: 0.9,
                           initialSpringVelocity: 6,
                           options: [.layoutSubviews, .preferredFramesPerSecond60, .allowUserInteraction],
                           animations:
                            {  [weak self] in
                DispatchQueue.main.async {
                    self?.updateTargetedImageViewPositionFrame(position, view)
                }

            })
        }else{
            self.updateTargetedImageViewPositionFrame(position, view)
        }
    }

    func updateTargetedImageViewPositionFrame(_ position: Int, _ view: UIView){
        let weakSelf = self

        weakSelf.menuView.alpha = 1
        weakSelf.menuView.frame = CGRect(
            x: position == 0 ? ContextMenuConstants().MenuMarginSpace : view.frame.width - weakSelf.mW - ContextMenuConstants().MenuMarginSpace,
            y: weakSelf.mY,
            width: weakSelf.mW,
            height: weakSelf.mH
        )

        weakSelf.targetedImageView.frame = CGRect(
            x: weakSelf.tvX,
            y: weakSelf.tvH >= weakSelf.mainViewRect.height ? 30 : weakSelf.tvY,
            width: weakSelf.tvW,
            height: weakSelf.tvH
        )

        weakSelf.blurEffectView.frame = CGRect(
            x: weakSelf.mainViewRect.origin.x,
            y: weakSelf.mainViewRect.origin.y,
            width: weakSelf.mainViewRect.width,
            height: weakSelf.mainViewRect.height
        )
        weakSelf.closeButton.frame = CGRect(
            x: weakSelf.mainViewRect.origin.x,
            y: weakSelf.mainViewRect.origin.y,
            width: weakSelf.mainViewRect.width,
            height: weakSelf.mainViewRect.height
        )
    }
    
    func updateTargetedImage(viewTargeted: UIView) {
        self.viewTargeted = viewTargeted
        targetedImageView.image = viewTargeted.image()
    }
    
    func updateBaseviewPosition(height: CGFloat) {
        let weakSelf = self
        let safeHeight = safeAreaBottom + height
            weakSelf.blurEffectView.frame = CGRect(
                x: weakSelf.mainViewRect.origin.x ,
                y: weakSelf.mainViewRect.origin.y - safeHeight,
                width: weakSelf.mainViewRect.width,
                height: weakSelf.mainViewRect.height
            )
            
            let width = weakSelf.targetedImageView.bounds.width
            let diffHeight = weakSelf.tvH - (safeHeight + 15)
            weakSelf.targetedImageView.clipsToBounds = true
            weakSelf.targetedImageView.contentMode = .scaleAspectFit
            if !(weakSelf.tvH > diffHeight) {
                weakSelf.targetedImageView.frame = CGRect(
                    x: weakSelf.tvX,
                    y: weakSelf.safeAreaTop, //(weakSelf.tvH >= weakSelf.mainViewRect.height ? 30 : weakSelf.tvY) - height
                    width: weakSelf.tvW,
                    height: (weakSelf.tvH - (diffHeight))
                )
            } else {
                weakSelf.targetedImageView.removeFromSuperview()
                if weakSelf.scrollView != nil {
                    weakSelf.scrollView.removeFromSuperview()
                }
                weakSelf.scrollView = UIScrollView(frame: CGRect(
                    x: weakSelf.tvX,
                    y: weakSelf.safeAreaTop, //(weakSelf.tvH >= weakSelf.mainViewRect.height ? 30 : weakSelf.tvY) - height
                    width: weakSelf.tvW,
                    height: (weakSelf.customView.bounds.height - safeHeight - weakSelf.safeAreaBottom - 50)
                ))
                if weakSelf.closeGesture != nil {
                    weakSelf.scrollView.addGestureRecognizer(weakSelf.closeGesture!)
                }
                weakSelf.scrollView.delegate = self
                weakSelf.customView.addSubview(weakSelf.scrollView)
                weakSelf.scrollView.addSubview(weakSelf.targetedImageView)
                if let mentionTable = weakSelf.mentionTableView {
                    let safeHeight = weakSelf.safeAreaBottom + height
                    let tableHeight = CGFloat((weakSelf.searchGroupMembers.count >= 3) ? 210 : (weakSelf.searchGroupMembers.count * 70))
                    weakSelf.mentionTableView?.frame = CGRect(x: 0, y: (weakSelf.scrollView.bounds.height) - (tableHeight - weakSelf.safeAreaTop), width: weakSelf.blurEffectView.bounds.width, height: tableHeight)
                    weakSelf.customView.bringSubviewToFront(mentionTable)
                }
                weakSelf.targetedImageView.translatesAutoresizingMaskIntoConstraints = false
                let height = weakSelf.scrollView.bounds.height
                if height < weakSelf.tvH {
                    weakSelf.targetedImageView.topAnchor.constraint(equalTo: weakSelf.scrollView.topAnchor, constant: 0).isActive = true
                } else {
                    weakSelf.targetedImageView.topAnchor.constraint(equalTo: weakSelf.scrollView.topAnchor, constant: weakSelf.scrollView.bounds.height - weakSelf.tvH).isActive = true
                }
                weakSelf.targetedImageView.leadingAnchor.constraint(equalTo: weakSelf.scrollView.leadingAnchor).isActive = true
                weakSelf.targetedImageView.trailingAnchor.constraint(equalTo: weakSelf.scrollView.trailingAnchor).isActive = true
                weakSelf.targetedImageView.widthAnchor.constraint(equalTo: weakSelf.scrollView.widthAnchor).isActive = true
                weakSelf.targetedImageView.bottomAnchor.constraint(equalTo: weakSelf.scrollView.bottomAnchor).isActive = true
                weakSelf.scrollView.contentSize = CGSize(width: 0, height: weakSelf.targetedImageView.bounds.height)
                weakSelf.scrollView.showsHorizontalScrollIndicator = false // Hide horizontal scroll indicator
                weakSelf.scrollView.contentInset = UIEdgeInsets.zero
                weakSelf.scrollView.contentInsetAdjustmentBehavior = .never
                weakSelf.customView.layoutIfNeeded()
                scrollView.isScrollEnabled = (weakSelf.tvH > scrollView.bounds.height)
            }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x != 0 {
            scrollView.contentOffset.x = 0
        }
    }
    
    func showMentionView(height: CGFloat, members: [GroupParticipantDetail] = []) {
        let weakSelf = self
        let safeHeight = safeAreaBottom + height
        let tableHeight = CGFloat((members.count >= 3) ? 210 : (members.count * 70))
        searchGroupMembers = members
        mentionTableView = UITableView(frame: CGRect(x: 0, y: (weakSelf.scrollView.bounds.height) - (tableHeight - weakSelf.safeAreaTop), width: weakSelf.blurEffectView.bounds.width, height: tableHeight))
        if let mentionTable = mentionTableView {
            weakSelf.customView.addSubview(mentionTable)
            mentionTable.register(UINib(nibName: "MentionTableViewCell",
                                            bundle: nil), forCellReuseIdentifier: "MentionTableViewCell")
            mentionTable.delegate = self
            mentionTable.dataSource = self
        }
    }
    
    func reloadMentionTableview(height: CGFloat, members: [GroupParticipantDetail] = []) {
        let weakSelf = self
        searchGroupMembers = members
        let safeHeight = safeAreaBottom + height
        let tableHeight = CGFloat((members.count >= 3) ? 210 : (members.count * 70))
        mentionTableView?.frame = CGRect(x: 0, y: (weakSelf.scrollView.bounds.height) - (tableHeight - weakSelf.safeAreaTop), width: weakSelf.blurEffectView.bounds.width, height: tableHeight)
        self.mentionTableView?.reloadData()
    }
}

extension ContextMenu : UITableViewDataSource, UITableViewDelegate {

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableView == mentionTableView ? self.searchGroupMembers.count : self.items.count
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == mentionTableView {
            let mentionCell = tableView.dequeueReusableCell(withIdentifier: "MentionTableViewCell", for: indexPath) as? MentionTableViewCell
            mentionCell?.userNameLabel?.text = searchGroupMembers[indexPath.row].displayName
            if let profileDetail = searchGroupMembers[indexPath.row].profileDetail {
                if profileDetail.contactType == .deleted || profileDetail.isBlockedMe || profileDetail.isBlockedByAdmin || (IS_LIVE && ENABLE_CONTACT_SYNC && profileDetail.isItSavedContact == false) {
                    mentionCell?.userImageView?.image = UIImage(named: "ic_profile_placeholder") ?? UIImage()
                } else {
                    let imageUrl = profileDetail.thumbImage.isEmpty ? profileDetail.image : profileDetail.thumbImage
                    mentionCell?.userImageView.sd_setImage(with: ChatUtils.getUserImaeUrl(imageUrl: imageUrl),
                                                           placeholderImage: UIImage(named: "ic_profile_placeholder"))
                }
            }
            return mentionCell ?? UITableViewCell()
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContextMenuCell", for: indexPath) as! ContextMenuCell
            cell.contextMenu = self
            cell.tableView = tableView
            cell.style = self.MenuConstants
            cell.item = self.items[indexPath.row]
            cell.setup()
            return cell
        }
    }

    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == mentionTableView {
            let jid = searchGroupMembers[indexPath.row].memberJid
            if let profileDetail = searchGroupMembers[indexPath.row].profileDetail {
                self.delegate?.contextMenuDidMentionSelect(self, jid: jid, profileDetail: profileDetail)
                self.mentionTableView?.removeFromSuperview()
            }
        } else {
            let item = self.items[indexPath.row]
            if self.onItemTap?(indexPath.row, item) ?? false {
                self.closeAllViews()
            }
            if self.delegate?.contextMenuDidSelect(self, cell: tableView.cellForRow(at: indexPath) as! ContextMenuCell, targetedView: self.viewTargeted, didSelect: self.items[indexPath.row], forRowAt: indexPath.row) ?? false {
                if item.title != MessageActions.edit.rawValue {
                    self.closeAllViews()
                }
            }
        }
    }

    open func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        self.delegate?.contextMenuDidDeselect(self, cell: tableView.cellForRow(at: indexPath) as! ContextMenuCell, targetedView: self.viewTargeted, didSelect: self.items[indexPath.row], forRowAt: indexPath.row)
    }

    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView == mentionTableView ? 70 : MenuConstants.ItemDefaultHeight
    }

    open func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return MenuConstants.ItemDefaultHeight
    }

}



@objc class ClosureSleeve: NSObject {
    let closure: () -> Void

    init (_ closure: @escaping () -> Void) {
        self.closure = closure
    }

    @objc func invoke () {
        closure()
    }
}

extension UIControl {
    func actionHandler(controlEvents control: UIControl.Event = .touchUpInside, ForAction action: @escaping () -> Void) {
        let sleeve = ClosureSleeve(action)
        addTarget(sleeve, action: #selector(ClosureSleeve.invoke), for: control)
        objc_setAssociatedObject(self, "[\(arc4random())]", sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
}

// MARK: - Get Rendered Image Functions

extension UIView {

    /// Creates an image from the view's contents, using its layer.
    ///
    /// - Returns: An image, or nil if an image couldn't be created.
    func scale(by scale: CGFloat) {
        self.contentScaleFactor = scale
        for subview in self.subviews {
            subview.scale(by: scale)
        }
    }

    func image(scale: CGFloat? = nil) -> UIImage {
        let newScale = scale ?? UIScreen.main.scale
        self.scale(by: newScale)

        let format = UIGraphicsImageRendererFormat()
        format.scale = newScale

        let renderer = UIGraphicsImageRenderer(size: self.bounds.size, format: format)

        let image = renderer.image { rendererContext in
            self.layer.render(in: rendererContext.cgContext)
        }

        return image
    }

}
