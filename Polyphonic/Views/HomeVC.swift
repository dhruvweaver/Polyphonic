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
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    private let outputField = PolyphonicTextField(placeholderText: "New link...", keyboardType: .URL)
    
    private let clearButton = PolyphonicButton(icon: "xmark")
    private let pasteButton = PolyphonicButton(icon: "doc.on.clipboard")
    
    private let copyButton = PolyphonicButton(icon: "doc.on.doc")
    private let shareButton = PolyphonicButton(icon: "square.and.arrow.up")
    
    private let convertedLabel = UILabel()
    
    let mainPreview = PolyphonicPreview(art: nil, title: "", album: "", artist: "", isExplicit: true, placeholder: true)
    private let editButton = PolyphonicButton(title: "Edit")
    private let loadingIndicatorEdit = UIActivityIndicatorView(style: .medium)
    
    /* Data structures */
    private var inLink: String = ""
    private var outLink: String = ""
    
    var keySong: Song = Song(title: "", ISRC: "", artists: [""], album: "", albumID: "", explicit: false, trackNum: 0)
    var type: MusicType = .album
    var altSongs: [String] = []
    var alts: [Song] = []
    var match: TranslationMatchLevel = .none
    
    
    // pasteboard for reading and writing clipboard data
    private let pasteboard = UIPasteboard.general
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Additional setup after loading the view.
        view.backgroundColor = .systemBackground
        
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
     Populates preview UI element with data from a provided `Song`.
     - Parameter fromSong:`Song` for displaying preview.
     */
    private func setupPreview(fromSong song: Song) async {
        var title = song.getTitle()
        if (type == .album) {
            title = "Album"
        }
        let album = song.getAlbum()
        let artist = song.getArtists()[0]
        let isExplicit = song.getExplicit()
        
        
        mainPreview.update(art: await getImageData(imageURL: song.getTranslatedImgURL()), title: title, album: album, artist: artist, isExplicit: isExplicit, placeholder: false)
        
        outputField.text = outLink
    }
    
    /**
     TODO: Will be used for translating links between streaming services.
     */
    @objc private func translateButtonHandler() {
        buttonDeepClick()
        
        // close keyboard
        endEditing()
        
        loadingIndicator.startAnimating()
        if let inLink = inputField.text {
            print("Translating: \(inLink)")
            
            outputField.text = ""
            outputField.placeholder = "Loading..."
            
            let musicData = MusicData()
            Task {
                let results = await musicData.translateData(link: inLink)
                
                outLink = results.0
                if let song = results.1 {
//                    keySong = song
                    type = results.2
                    altSongs = results.3
                    alts = results.4
                    match = results.5
                    
                    keySong = song
                    // setup preview UI elements
                    await setupPreview(fromSong: song)
                    
                    loadingIndicator.stopAnimating()
                    outputField.placeholder = "New link..."
                } else {
                    alts = []
                    altSongs = []
                    match = .none
                    
                    mainPreview.update(art: nil, title: "", album: "", artist: "", isExplicit: false, placeholder: true)
                    
                    outputField.text = outLink
                    
                    loadingIndicator.stopAnimating()
                    outputField.placeholder = "New link..."
                }
                
                configureEditButton()
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
     Shares translated link throught the system share sheet.
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
    
    /**
     Launches edit modal sheet for chooseing from alternative translations.
     */
    @objc private func editButtonHandler() {
        buttonClick()
        
        Task {
            /* turn edit button into loading indicator */
            editButton.removeFromSuperview()
            configureLoadingIndicatorEdit()
            loadingIndicatorEdit.startAnimating()
            
            for i in alts {
                await i.setTranslatedImgData()
            }
            
            let editView = EditVC(altSongs: altSongs, alts: alts, currentSong: keySong, type: type)
            editView.delegate = self
            
            present(editView, animated: true)
            
            /* turn loading indicator back into edit button */
            loadingIndicatorEdit.stopAnimating()
            loadingIndicatorEdit.removeFromSuperview()
            configureEditButton()
        }
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
        configureCopyButton()
        configureShareButton()
        
        configureConvertedLabel()
        configurePreview()
        configureEditButton()
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
        
        translateButton.configuration?.baseBackgroundColor = .label
        translateButton.configuration?.baseForegroundColor = .systemBackground
        
        translateButton.addTarget(self, action: #selector(buttonDeepClick), for: .touchDown)
        translateButton.addTarget(self, action: #selector(translateButtonHandler), for: .touchUpInside)
        translateButton.addTarget(self, action: #selector(buttonSoftClick), for: .touchDragExit)
        
        NSLayoutConstraint.activate([
            translateButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            translateButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -65),
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
            loadingIndicator.centerXAnchor.constraint(equalTo: view.trailingAnchor, constant: -37),
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
        
        NSLayoutConstraint.activate([
            clearButton.centerYAnchor.constraint(equalTo: inputField.centerYAnchor),
            clearButton.centerXAnchor.constraint(equalTo: view.trailingAnchor, constant: -85)
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
        view.addSubview(mainPreview)
        mainPreview.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mainPreview.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainPreview.topAnchor.constraint(equalTo: convertedLabel.bottomAnchor, constant: 20),
            mainPreview.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.895),
            mainPreview.heightAnchor.constraint(equalTo: mainPreview.widthAnchor, multiplier: 0.48),
        ])
    }
    
    /**
     Configure and position `editButton` and enables or disables the button depending on whether alternatives are available.
     */
    private func configureEditButton() {
        view.addSubview(editButton)
        editButton.translatesAutoresizingMaskIntoConstraints = false
        
        if (alts.count > 1) {
            editButton.isUserInteractionEnabled = true
            
            editButton.configuration?.baseForegroundColor = .label
            
            // color code edit button depending on whether an exact match was found
            if (match.rawValue < TranslationMatchLevel.exact.rawValue) {
                editButton.configuration?.baseBackgroundColor = .systemYellow
            } else {
                editButton.configuration?.baseBackgroundColor = .systemBackground
            }
            
            // drop shadow
            editButton.layer.shadowColor = UIColor.label.cgColor
            
            editButton.addTarget(self, action: #selector(buttonClick), for: .touchDown)
            editButton.addTarget(self, action: #selector(editButtonHandler), for: .touchUpInside)
        } else {
            editButton.isUserInteractionEnabled = false
            editButton.configuration?.baseForegroundColor = .systemGray4
            editButton.configuration?.baseBackgroundColor = .systemBackground
            
            // drop shadow
            editButton.layer.shadowColor = UIColor.clear.cgColor
        }
        
        NSLayoutConstraint.activate([
            editButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            editButton.topAnchor.constraint(equalTo: mainPreview.bottomAnchor, constant: 12)
        ])
    }
    
    /**
     Configure and position `loadingIndicatorEdit` in the same place as the edit button.
     */
    private func configureLoadingIndicatorEdit() {
        view.addSubview(loadingIndicatorEdit)
        loadingIndicatorEdit.translatesAutoresizingMaskIntoConstraints = false
        
        loadingIndicatorEdit.hidesWhenStopped = true
        loadingIndicatorEdit.color = .label
        
        NSLayoutConstraint.activate([
            loadingIndicatorEdit.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicatorEdit.topAnchor.constraint(equalTo: mainPreview.bottomAnchor, constant: 18)
        ])
    }
}

/**
 Allows edit sheet to pass data back to this home view.
 */
extension HomeVC: EditVCDelegate {
    func updateSelection(withSong song: Song) {
        keySong = song
        
        // first show empty preview
        mainPreview.update(art: nil, title: "", album: "", artist: "", isExplicit: false, placeholder: true)
        outputField.text = ""
        outputField.placeholder = "Loading..."
        
        Task {
            await setupPreview(fromSong: song)
            // set output to alt song's link
            outLink = song.getTranslatedURLasString()
            outputField.text = outLink
        }
        
        outputField.placeholder = "New link..."
    }
}

