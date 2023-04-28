//
//  NavigationControllerExtension.swift
//  MirrorflyUIkit
//
//  Created by John on 27/11/22.
//

import Foundation
import UIKit

extension UINavigationController {
    
    func removeViewController(_ controller: UIViewController.Type) {
        if let viewController = viewControllers.first(where: { $0.isKind(of: controller.self) }) {
            viewController.removeFromParent()
        }
    }
}
