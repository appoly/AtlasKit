//
//  TabBarController.swift
//  UIKitExample
//
//  Created by James Wolfe on 17/03/2022.
//



import Foundation
import UIKit



class TabBarController: UITabBarController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let viewControllers = viewControllers as? [LocationSearchViewController] else { return }
        let atlasses = [
            AtlasKit(.apple),
            AtlasKit(.google(key: "test")),
            AtlasKit(.getAddress(key: "test"))
        ]
        
        viewControllers.enumerated().forEach {
            $0.element.atlas = atlasses[$0.offset]
        }
    }
}
