//
//  ShareViewController.swift
//  LinkShare
//
//  Created by Dhruv Weaver on 6/22/22.
//

import UIKit
import Social
import SwiftUI

class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the hosting controller as a child view controller
        let hostingController = UIHostingController(rootView: ShareView())
        self.addChild(hostingController)
        self.view.addSubview(hostingController.view)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints=false
        hostingController.view.topAnchor.constraint(equalTo:view.topAnchor).isActive=true
        hostingController.view.bottomAnchor.constraint(equalTo:view.bottomAnchor).isActive=true
        hostingController.view.leftAnchor.constraint(equalTo:view.leftAnchor).isActive=true
        hostingController.view.rightAnchor.constraint(equalTo:view.rightAnchor).isActive=true
    }
}
