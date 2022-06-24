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
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1: Set the background and call the function to create the navigation bar
        self.view.backgroundColor = .systemBackground
        setupNavBar()
        
        super.viewDidLoad()
        
        let shareView = ShareView(model: ShareModel(link: "https://open.spotify.com/track/1XT5kxg6Tk0ukCO2vBQN4v?si=96a82a114817481c"))
//        let child = UIHostingController(rootView: TestView())
        let child = UILabel()
        child.text = "CustomShareViewController"
        
        self.view.addSubview(child)
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
    
    func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }
    
    func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
        
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
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


