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
        
        var urlStr = "Link could not be processed"
        Task {
            if let str = await getURL() {
                urlStr = str
                print(urlStr)
            }
            
            buildSwiftUI(url: urlStr)
        }
    }
    
    func getURL() async -> String? {
        var urlStr: String? = nil
        if let item = extensionContext?.inputItems.first as? NSExtensionItem {
            if let itemProvider = item.attachments?.first {
                if itemProvider.hasItemConformingToTypeIdentifier("public.url") {
                    do {
                        let url = try await itemProvider.loadItem(forTypeIdentifier: "public.url", options: nil)
                        do {
                            if let url = url as? URL{
                                urlStr = url.absoluteString
                            }
                        }
                    } catch {
                        debugPrint("Error getting url: \(String(describing: error))")
                    }
                }
            }
        }
        return urlStr
    }
    
    @objc func openURL(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                return application.perform(#selector(openURL(_:)), with: url) != nil
            }
            responder = responder?.next
        }
        return false
    }
    
    func buildSwiftUI(url: String) {
        print("URL to UI:")
        print(url)
        let hostingController = UIHostingController(rootView: ShareView(linkStr: url))
        self.addChild(hostingController)
        self.view.addSubview(hostingController.view)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints=false
        hostingController.view.topAnchor.constraint(equalTo:view.topAnchor).isActive=true
        hostingController.view.bottomAnchor.constraint(equalTo:view.bottomAnchor).isActive=true
        hostingController.view.leftAnchor.constraint(equalTo:view.leftAnchor).isActive=true
        hostingController.view.rightAnchor.constraint(equalTo:view.rightAnchor).isActive=true
    }
}
