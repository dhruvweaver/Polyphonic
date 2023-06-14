//
//  SettingsVC.swift
//  polyphonic_fr
//
//  Created by Dhruv Weaver on 6/13/23.
//

import UIKit

class SettingsVC: UIViewController {
    
    /* UI elements: */
    private let settingTitleBar = PolyphonicTitle(title: "Settings")
    
    private let pasteInfoLabel = UILabel()
    private let settingsButton = PolyphonicButton(title: "Open Settings")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .systemBackground
        
        configureUI()
    }
    
    // MARK: - Logic
    
    /**
     Basic button clicking haptic feedback. A short "rigid" tap.
     Can be called twice (on touchDown and touchUpInside) to simulate a simple physical button pressing in and out.
     */
    @objc private func buttonClick() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }
    
    /**
     Basic button clicking haptic feedback. A deep "heavy" tap.
     Can be called twice (on touchDown and touchUpInside) to simulate a big physical button pressing in and out.
     */
    @objc private func buttonDeepClick() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /**
     Basic button clicking haptic feedback. A short "soft" tap.
     Can be called twice (on touchDown and touchUpInside) to simulate a squishy physical button pressing in and out.
     Also use for a exiting a large button click.
     */
    @objc private func buttonSoftClick() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
    
    /**
     Opens app settings in the iOS Settings app.
     */
    @objc private func openSettings() {
        buttonDeepClick()
        
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    // MARK: - UI Configuration
    
    /**
     Configures UI by calling each UI component's configure function, each of which also positions the component.
     */
    private func configureUI() {
        configureTitleBar()
        configurePasteInfoLabel()
        configureSettingsButton()
    }
    
    /**
     Configures custom title bar (`PolyphonicTitle)` and places it at the top of the UI.
     */
    private func configureTitleBar() {
        view.addSubview(settingTitleBar)
        settingTitleBar.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            settingTitleBar.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            settingTitleBar.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    /**
     Configure and position `settingsButton` (`PolyphonicButton`). This button determines the y position of most elements.
     */
    private func configureSettingsButton() {
        view.addSubview(settingsButton)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        
        settingsButton.addTarget(self, action: #selector(buttonDeepClick), for: .touchDown)
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        settingsButton.configuration?.image = UIImage(systemName: "arrow.up.right")
        settingsButton.configuration?.imagePadding = 5
        settingsButton.configuration?.imagePlacement = .trailing
        
        NSLayoutConstraint.activate([
            settingsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            settingsButton.topAnchor.constraint(equalTo: pasteInfoLabel.bottomAnchor, constant: 20)
        ])
    }
    
    /**
     Configure and position a message telling users why iOS asks for clipboard permission, and how they can fix it.
     */
    private func configurePasteInfoLabel() {
        view.addSubview(pasteInfoLabel)
        pasteInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        pasteInfoLabel.text = """
        iOS 16+ requires all apps to ask for clipboard access every time.
        
        This can be changed in settings by choosing "Allow" from
        "Paste from Other Apps"
        """
        
        pasteInfoLabel.font = UIFont(name: "SpaceMono-Regular", size: 16)
        pasteInfoLabel.numberOfLines = 0
        pasteInfoLabel.textAlignment = .center
        
        NSLayoutConstraint.activate([
            pasteInfoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pasteInfoLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            pasteInfoLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9)
        ])
    }
}
