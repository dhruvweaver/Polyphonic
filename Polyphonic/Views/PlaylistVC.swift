//
//  SettingsVC.swift
//  polyphonic_fr
//
//  Created by Dhruv Weaver on 6/13/23.
//

import UIKit

class PlaylistVC: UIViewController {
    
    /* UI elements: */
    private let playlistTitleBar = PolyphonicTitle(title: "Polyphonic")
    
    private let playlistInfoLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .systemBackground
        
        configureUI()
    }
    
    // MARK: - Logic
    
    // MARK: - UI Configuration
    
    /**
     Configures UI by calling each UI component's configure function, each of which also positions the component.
     */
    private func configureUI() {
        configureTitleBar()
        configurePlaylistInfoLabel()
    }
    
    /**
     Configures custom title bar (`PolyphonicTitle)` and places it at the top of the UI.
     */
    private func configureTitleBar() {
        view.addSubview(playlistTitleBar)
        playlistTitleBar.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            playlistTitleBar.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            playlistTitleBar.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    /**
     Configure and position a message telling users that playlist sharing is coming soon.
     */
    private func configurePlaylistInfoLabel() {
        view.addSubview(playlistInfoLabel)
        playlistInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        playlistInfoLabel.text = "Coming soon..."
        
        playlistInfoLabel.font = UIFont(name: "SpaceMono-Regular", size: 16)
        playlistInfoLabel.numberOfLines = 0
        playlistInfoLabel.textAlignment = .center
        
        NSLayoutConstraint.activate([
            playlistInfoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playlistInfoLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            playlistInfoLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9)
        ])
    }
}
