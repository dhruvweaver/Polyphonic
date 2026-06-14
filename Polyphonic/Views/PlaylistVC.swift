//
//  SettingsVC.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 6/13/23.
//

import UIKit

class PlaylistVC: UIViewController {
    
    /* UI elements: */
    private let playlistTitleBar = PolyphonicTitle(title: "Polyphonic")
    
    private let inputField = PolyphonicTextField(placeholderText: "Paste a link", keyboardType: .URL)
    
    private let translateButton = PolyphonicButton(title: "Convert")
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    private let outputField = PolyphonicTextField(placeholderText: "New link...", keyboardType: .URL)
    
    private let clearButton = PolyphonicButton(icon: "xmark")
    private let pasteButton = PolyphonicButton(icon: "doc.on.clipboard")
    
    /* Data structures */
    private var inLink: String = ""
    private var outLink: String = ""
    // pasteboard for reading and writing clipboard data
    private let pasteboard = UIPasteboard.general
    private let shownPasteAlertKey = "shownPasteAlert"
    
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
     Clears content `inputField.text` and the corresponding `String`, `inLink`.
     */
    @objc private func clearButtonHandler() {
        buttonClick()
        
        inputField.text = ""
        inLink = ""
    }
    
    /**
     Informs user of the ability to always allow pasting by default.
     */
    func showAlert() {
        let message = "iOS requires that the user gives permission to access the clipboard. If you would like to allow permament access, please visit the Settings app. "
        + "You can change this any time"
        let alert = UIAlertController(title: "Clipboard Access", message: message, preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default) {
            UIAlertAction in
            
            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:])
            }
        }
        
        alert.addAction(settingsAction)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true, completion: nil)
        
        // Set the UserDefaults to indicate the popup has been shown
        UserDefaults.standard.set(true, forKey: shownPasteAlertKey)
    }
    
    /**
     Gets text from `pasteboard` and places it in `inputField.text` and the corresponding `String`, `inLink`.
     */
    @objc private func pasteButtonHandler() {
        buttonClick()
        
        let hasShownAlert = UserDefaults.standard.bool(forKey: shownPasteAlertKey)
        if (!hasShownAlert) {
            showAlert()
        }
        
        if let inLink = pasteboard.string {
            inputField.text = inLink
        } else {
            print("Could not find any pasteboard content")
            return
        }
    }
    
    @objc func translateButtonHandler() {
        
    }
    // MARK: - UI Configuration
    
    /**
     Configures UI by calling each UI component's configure function, each of which also positions the component.
     */
    private func configureUI() {
        configureTitleBar()
        
        configureTranslateButton()
        configureLoadingIndicator()
        
        configureInputTextField()
        configureOutputTextField()
        
        configureClearButton()
        configurePasteButton()
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
     Configure and position `inputField` (`PolyphonicTextField`).
     */
    private func configureInputTextField() {
        view.addSubview(inputField)
        
        NSLayoutConstraint.activate([
            inputField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            inputField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -67),
            inputField.centerYAnchor.constraint(equalTo: translateButton.topAnchor, constant: -30)
        ])
    }
    
    /**
     Configure and position `translateButton` (`PolyphonicButton`). This button determines the y position of most elements.
     */
    private func configureTranslateButton() {
        view.addSubview(translateButton)
        
        translateButton.configuration?.baseBackgroundColor = .label
        translateButton.configuration?.baseForegroundColor = .systemBackground
        
        translateButton.addTarget(self, action: #selector(buttonDeepClick), for: .touchDown)
        translateButton.addTarget(self, action: #selector(translateButtonHandler), for: .touchUpInside)
        translateButton.addTarget(self, action: #selector(buttonSoftClick), for: .touchDragExit)
        
        NSLayoutConstraint.activate([
            translateButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            translateButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            translateButton.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -400)
        ])
    }
    
    /**
     Configure and position `loadingIndicator`.
     */
    private func configureLoadingIndicator() {
        view.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = .label
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: translateButton.centerYAnchor)
        ])
    }
    
    /**
     Configure and position `outputField` (`PolyphonicTextField`).
     */
    private func configureOutputTextField() {
        view.addSubview(outputField)
        
        NSLayoutConstraint.activate([
            outputField.leadingAnchor.constraint(equalTo: inputField.leadingAnchor),
            outputField.trailingAnchor.constraint(equalTo: inputField.trailingAnchor),
            outputField.centerYAnchor.constraint(equalTo: translateButton.bottomAnchor, constant: 60)
        ])
    }
    
    /**
     Configure and position `clearButton` (`PolyphonicButton`).
     */
    private func configureClearButton() {
        view.addSubview(clearButton)
        
        clearButton.addTarget(self, action: #selector(buttonClick), for: .touchDown)
        clearButton.addTarget(self, action: #selector(clearButtonHandler), for: .touchUpInside)
        clearButton.addTarget(self, action: #selector(buttonSoftClick), for: .touchDragExit)
        
        NSLayoutConstraint.activate([
            clearButton.centerYAnchor.constraint(equalTo: inputField.centerYAnchor),
            clearButton.centerXAnchor.constraint(equalTo: view.trailingAnchor, constant: -87)
        ])
    }
    
    /**
     Configure and position `pasteButton` (`PolyphonicButton`).
     */
    private func configurePasteButton() {
        view.addSubview(pasteButton)
        
        pasteButton.addTarget(self, action: #selector(buttonClick), for: .touchDown)
        pasteButton.addTarget(self, action: #selector(pasteButtonHandler), for: .touchUpInside)
        pasteButton.addTarget(self, action: #selector(buttonSoftClick), for: .touchDragExit)
        
        NSLayoutConstraint.activate([
            pasteButton.centerYAnchor.constraint(equalTo: inputField.centerYAnchor),
            pasteButton.centerXAnchor.constraint(equalTo: view.trailingAnchor, constant: -39)
        ])
    }
}
