//
//  TabVC.swift
//  polyphonic_fr
//
//  Created by Dhruv Weaver on 6/13/23.
//

import UIKit

class TabVC: UITabBarController, UITabBarControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Assign self for delegate so that TabVC can respond to UITabBarControllerDelegate methods
        self.delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create home tab
        let homeTab = HomeVC()
        let homeViewBarItem = UITabBarItem(title: "Basic Sharing", image: UIImage(systemName: "music.note"), tag: 0)
        
        homeTab.tabBarItem = homeViewBarItem
        
        // Create playlist tab
        let playlistTab = PlaylistVC()
        let playlistViewBarItem = UITabBarItem(title: "Playlist Sharing", image: UIImage(systemName: "music.note.list"), tag: 1)
        
        playlistTab.tabBarItem = playlistViewBarItem
        
        // Create settings tab
        let settingsTab = SettingsVC()
        let settingsViewBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gear"), tag: 2)
        
        settingsTab.tabBarItem = settingsViewBarItem
        
        
        self.viewControllers = [homeTab, playlistTab, settingsTab]
    }
}
