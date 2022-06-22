//
//  ShareViewController.swift
//  LinkShare
//
//  Created by Dhruv Weaver on 6/22/22.
//

import UIKit
import Social
import SwiftUI

class CustomShareViewController: UIViewController {
    @IBOutlet var container: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1: Set the background and call the function to create the navigation bar
        self.view.backgroundColor = .systemGray6
        setupNavBar()
        
        super.viewDidLoad()
        let childView = UIHostingController(rootView: ShareView())
        addChild(childView)
        childView.view.frame = container.bounds
        container.addSubview(childView.view)
        childView.didMove(toParent: self)
        
    }
    
    //     2: Set the title and the navigation items
    private func setupNavBar() {
        let itemCancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelAction))
        self.navigationItem.setLeftBarButton(itemCancel, animated: false)
    }
    
    // 3: Define the actions for the navigation items
    @objc private func cancelAction () {
        let error = NSError(domain: "some.bundle.identifier", code: 0, userInfo: [NSLocalizedDescriptionKey: "An error description"])
        extensionContext?.cancelRequest(withError: error)
    }
}

// 1: Set the `objc` annotation
@objc(CustomShareNavigationController)
class CustomShareNavigationController: UINavigationController {
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        // 2: set the ViewControllers
        self.setViewControllers([CustomShareViewController()], animated: false)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
}


