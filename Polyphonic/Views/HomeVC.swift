//
//  ViewController.swift
//  polyphonic_fr
//
//  Created by Grant Elijah Kilgard on 5/6/23.
//

import UIKit

class HomeVC: UIViewController, UITextFieldDelegate {
    
    /* UI elements: */
    private let mainTitleBar = PolyphonicTitle(title: "Polyphonic")
    
    private let inputField = PolyphonicTextField(placeholderText: "Paste a link", keyboardType: .URL)
    private let translateButton = PolyphonicButton(title: "Translate")
    private let outputField = PolyphonicTextField(placeholderText: "New link...", keyboardType: .URL)
    
    private let clearButton = PolyphonicButton(icon: "xmark")
    private let pasteButton = PolyphonicButton(icon: "doc.on.clipboard")
    
    private let copyButton = PolyphonicButton(icon: "doc.on.doc")
    private let shareButton = PolyphonicButton(icon: "square.and.arrow.up")
    
    private let convertedLabel = UILabel()
    
    private var preview = PolyphonicPreview(art: nil, title: "", album: "", artist: "", isExplicit: true, placeholder: true)
    private let editButton = PolyphonicButton(title: "Edit")
    
    /* Data structures */
    private var inLink: String = ""
    private var outLink: String = ""
    
    var keySong: Song = Song(title: "", ISRC: "", artists: [""], album: "", albumID: "", explicit: false, trackNum: 0)
    var type: MusicType = .album
    var altSongs: [String] = []
    var alts: [Song] = []
    
    
    // pasteboard for reading and writing clipboard data
    private let pasteboard = UIPasteboard.general
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Additional setup after loading the view.
        view.backgroundColor = .systemBackground
        
        // custom UIView for navigation bar title
//        self.navigationItem.titleView = PolyphonicTitle(title: "Polyphonic")
        
        // setup UI
        configureUI()
        
        inputField.delegate = self
        outputField.delegate = self
        
        /* Allows for dismissal of keyboard on swipe or tap outside of text field */
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(endEditing))
        swipeGesture.direction = .down
        view.addGestureRecognizer(tapGesture)
        view.addGestureRecognizer(swipeGesture)
    }
    
    // MARK: - App Logic
    
    /**
     Close keyboard.
     */
    @objc private func endEditing() {
        view.endEditing(true)
    }
    
    // close keyboard when done is pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        endEditing()
        return false
    }
    
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
     Gets text from `pasteboard` and places it in `inputField.text` and the corresponding `String`, `inLink`.
     */
    @objc private func pasteButtonHandler() {
        buttonClick()
        
        if let inLink = pasteboard.string {
            inputField.text = inLink
        } else {
            print("Could not find any pasteboard content")
            return
        }
    }
    
    /**
     TODO: Will be used for translating links between streaming services.
     */
    @objc private func translateButtonHandler() {
        buttonDeepClick()
        
        // close keyboard
        endEditing()
        
        if let inLink = inputField.text {
            print("Translating: \(inLink)")
            
            // replace with translation process
//            outLink = "Displaying \(inLink)"
            let musicData = MusicData()
            Task {
                let results = await musicData.translateData(link: inLink)
                
                outLink = results.0
                if let song = results.1 {
                    keySong = song
                    type = results.2
                    altSongs = results.3
                    alts = results.4
                    
                    var title = song.getTitle()
                    if (type == .album) {
                        title = "Album"
                    }
                    let album = song.getAlbum()
                    let artist = keySong.getArtists()[0]
                    let isExplicit = keySong.getExplicit()
                    
                    preview.update(art: await getImageData(imageURL: keySong.getTranslatedImgURL()), title: title, album: album, artist: artist, isExplicit: isExplicit, placeholder: false)
                    
                    outputField.text = outLink
                } else {
                    preview.update(art: nil, title: "", album: "", artist: "", isExplicit: false, placeholder: true)
                    
                    outputField.text = outLink
                }
            }
        } else {
            debugPrint("Error: could not get text from input field")
            return
        }
    }
    
    /**
     Copies text from `outLink` to the pasteboard.
     */
    @objc private func copyButtonHandler() {
        buttonClick()
        
        outLink = outputField.text! // remove later, this is just so that clipboard functionality can be tested
        pasteboard.string = outLink
    }
    
    /**
     TODO: Will share translated link throught the system share sheet.
     */
    @objc private func shareButtonHandler() {
        buttonClick()
        
        if let urlShare = URL(string: outLink) {
            let shareActivity = UIActivityViewController(activityItems: [urlShare], applicationActivities: nil)
            
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            
            windowScene?.keyWindow?.rootViewController?.present(shareActivity, animated: true, completion: nil)
        }
    }
    
    // MARK: - UI Configuration
    
    /**
     Configures UI by calling each UI component's configure function, each of which also positions the component.
     */
    private func configureUI() {
        configureTitleBar()
        
        configureTranslateButton()
        configureInputTextField()
        configureOutputTextField()
        
        configureClearButton()
        configurePasteButton()
        configureCopyButton()
        configureShareButton()
        
        configureConvertedLabel()
        configurePreview()
    }
    
    /**
     Configures custom title bar (`PolyphonicTitle)` and places it at the top of the UI.
     */
    private func configureTitleBar() {
        view.addSubview(mainTitleBar)
        mainTitleBar.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mainTitleBar.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mainTitleBar.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    /**
     Configure and position `inputField` (`PolyphonicTextField`).
     */
    private func configureInputTextField() {
        view.addSubview(inputField)
        
        NSLayoutConstraint.activate([
            inputField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            inputField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -65),
            inputField.centerYAnchor.constraint(equalTo: translateButton.topAnchor, constant: -30)
        ])
    }
    
    /**
     Configure and position `translateButton` (`PolyphonicButton`). This button determines the y position of most elements.
     */
    private func configureTranslateButton() {
        view.addSubview(translateButton)
        
        translateButton.addTarget(self, action: #selector(buttonDeepClick), for: .touchDown)
        translateButton.addTarget(self, action: #selector(translateButtonHandler), for: .touchUpInside)
        translateButton.addTarget(self, action: #selector(buttonSoftClick), for: .touchDragExit)
        
        NSLayoutConstraint.activate([
            translateButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            translateButton.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -400)
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
        
        NSLayoutConstraint.activate([
            clearButton.centerYAnchor.constraint(equalTo: inputField.centerYAnchor),
            clearButton.centerXAnchor.constraint(equalTo: view.trailingAnchor, constant: -81)
        ])
    }
    
    /**
     Configure and position `pasteButton` (`PolyphonicButton`).
     */
    private func configurePasteButton() {
        view.addSubview(pasteButton)
        
        pasteButton.addTarget(self, action: #selector(buttonClick), for: .touchDown)
        pasteButton.addTarget(self, action: #selector(pasteButtonHandler), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            pasteButton.centerYAnchor.constraint(equalTo: inputField.centerYAnchor),
            pasteButton.centerXAnchor.constraint(equalTo: view.trailingAnchor, constant: -37)
        ])
    }
    
    /**
     Configure and position `copyButton` (`PolyphonicButton`).
     */
    private func configureCopyButton() {
        view.addSubview(copyButton)
        
        copyButton.addTarget(self, action: #selector(buttonClick), for: .touchDown)
        copyButton.addTarget(self, action: #selector(copyButtonHandler), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            copyButton.centerYAnchor.constraint(equalTo: outputField.centerYAnchor),
            copyButton.centerXAnchor.constraint(equalTo: clearButton.centerXAnchor)
        ])
    }
    
    /**
     Configure and position `shareButton` (`PolyphonicButton`).
     */
    private func configureShareButton() {
        view.addSubview(shareButton)
        
        shareButton.addTarget(self, action: #selector(buttonClick), for: .touchDown)
        shareButton.addTarget(self, action: #selector(shareButtonHandler), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            shareButton.centerYAnchor.constraint(equalTo: outputField.centerYAnchor),
            shareButton.centerXAnchor.constraint(equalTo: pasteButton.centerXAnchor)
        ])
    }
    
    /**
     Configure and position `convertedLabel`.
     `UILabel` describing translated music preview below.
     */
    private func configureConvertedLabel() {
        view.addSubview(convertedLabel)
        
        convertedLabel.translatesAutoresizingMaskIntoConstraints = false
        convertedLabel.text = "Converted Music"
        convertedLabel.font = UIFont(name: "SpaceMono-Regular", size: 20)
        
        NSLayoutConstraint.activate([
            convertedLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            convertedLabel.topAnchor.constraint(equalTo: outputField.bottomAnchor, constant: 20)
        ])
    }
    
    /**
     Configure and position `preview` which previews the translated music. Also configures `editButton` for translation refining.
     */
    private func configurePreview() {
        view.addSubview(preview)
        preview.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(editButton)
        editButton.translatesAutoresizingMaskIntoConstraints = false
        
        editButton.addTarget(self, action: #selector(buttonClick), for: .touchDown)
        editButton.addTarget(self, action: #selector(buttonClick), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            preview.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            preview.topAnchor.constraint(equalTo: convertedLabel.bottomAnchor, constant: 20),
            preview.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.895),
            preview.heightAnchor.constraint(equalTo: preview.widthAnchor, multiplier: 0.48),
            
            editButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            editButton.topAnchor.constraint(equalTo: preview.bottomAnchor, constant: 12)
        ])
    }
}

