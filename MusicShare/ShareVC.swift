//
//  ShareViewController.swift
//  LinkShare
//
//  Created by Dhruv Weaver on 6/22/22.
//

import UIKit
import Social
import SwiftUI

/**
 `UIViewController` that appears when the user chooses Polyphonic from the share sheet.
 */
class ShareVC: UIViewController {
    /* UI elements: */
    private let mainTitleBar = PolyphonicTitle(title: "Polyphonic")
    
    private let inputField = PolyphonicTextField(placeholderText: "Input link", keyboardType: .URL)
    
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    private let outputField = PolyphonicTextField(placeholderText: "Translated link...", keyboardType: .URL)
    
    private let copyButton = PolyphonicButton(icon: "doc.on.doc")
    private let shareButton = PolyphonicButton(icon: "square.and.arrow.up")
    
    private let convertedLabel = UILabel()
    
    let sharePreview = PolyphonicPreview(art: nil, title: "", album: "", artist: "", isExplicit: true, placeholder: true)
    private let editButton = PolyphonicButton(title: "Edit")
    private let loadingIndicatorEdit = UIActivityIndicatorView(style: .medium)
    
    /* Data structures */
    private var inLink: String = ""
    private var outLink: String = ""
    
    var keySong: Song = Song(title: "", ISRC: "", artists: [""], album: "", albumID: "", explicit: false, trackNum: 0)
    var keyArtist: Artist = Artist(name: "")
    var type: MusicType = .album
    var altSongs: [String] = []
    var alts: [Song] = []
    var altArtists: [Artist] = []
    var match: TranslationMatchLevel = .none
    
    // pasteboard for reading and writing clipboard data
    private let pasteboard = UIPasteboard.general
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .systemBackground
        setupNavBar()
        
        var urlStr = "Link could not be processed"
        Task {
            if let str = await getURL() {
                urlStr = str
                print(urlStr)
            }
            
            inLink = urlStr
            inputField.text = inLink
            
            configureUI()
            
            // immediately translate links without user input (once share extension is launched)
            translateMusic()
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
    
    /**
     TODO: Will be used for translating links between streaming services.
     */
    @objc private func translateMusic() {
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
                    type = results.3
                    altSongs = results.4
                    alts = results.5
                    altArtists = results.6
                    match = results.7
                    
                    keySong = song
                    // setup preview UI elements
                    await setupPreview(fromSong: song)
                    
                    loadingIndicator.stopAnimating()
                    outputField.placeholder = "New link..."
                } else if let artist = results.2 {
                    type = results.3
                    altSongs = results.4
                    alts = results.5
                    altArtists = results.6
                    match = results.7
                    
                    keyArtist = artist
                    // setup preview UI elements
                    await setupPreview(fromArtist: artist)
                    
                    loadingIndicator.stopAnimating()
                    outputField.placeholder = "New link..."
                } else {
                    alts = []
                    altSongs = []
                    match = .none
                    
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
        
        
        sharePreview.update(art: await getImageData(imageURL: song.getTranslatedImgURL()), title: title, album: album, artist: artist, isExplicit: isExplicit, placeholder: false)
        
        outputField.text = outLink
    }
    
    private func setupPreview(fromArtist artist: Artist) async {
        let title = "Artist"
        
        sharePreview.update(art: await getImageData(imageURL: artist.getTranslatedImgURL()), title: title, album: artist.getName(), artist: "", isExplicit: false, placeholder: false)
        
        outputField.text = outLink
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
     Copies text from `outLink` to the pasteboard.
     */
    @objc private func copyButtonHandler() {
        buttonClick()
        
        outLink = outputField.text! // remove later, this is just so that clipboard functionality can be tested
        pasteboard.string = outLink
    }
    
    struct SharingViewController: UIViewControllerRepresentable {
        @Binding var isPresenting: Bool
        var content: () -> UIViewController
        
        func makeUIViewController(context: Context) -> UIViewController {
            UIViewController()
        }
        
        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
            if isPresenting {
                uiViewController.present(content(), animated: true, completion: nil)
            }
        }
    }
    
    /**
     TODO: Will share translated link throught the system share sheet.
     */
    @objc private func shareButtonHandler() {
        buttonClick()
        
        if let urlShare = URL(string: outLink) {
            let shareActivity = UIActivityViewController(activityItems: [urlShare], applicationActivities: nil)
            
            //            self.view.window?.windowScene
            //            let scenes = UIApplication.shared.connectedScenes
            //            let windowScene = scenes.first as? UIWindowScene
            //
            //            windowScene?.keyWindow?.rootViewController?.present(shareActivity, animated: true, completion: nil)
            self.present(shareActivity, animated: true)
        }
    }
    
    @objc private func editButtonHandler() {
        buttonClick()

        Task {
            /* turn edit button into loading indicator */
            editButton.removeFromSuperview()
            configureLoadingIndicatorEdit()
            loadingIndicatorEdit.startAnimating()
            
            if (type != .artist) {
                for i in alts {
                    await i.setTranslatedImgData()
                }
                
                
                let editView = EditVC(altSongs: altSongs, alts: alts, currentSong: keySong, type: type)
                editView.delegate = self
                
                present(editView, animated: true)
            } else {
                for i in altArtists {
                    await i.setTranslatedImgData()
                }


                let editView = EditVC(altArtists: altArtists, currentArtist: keyArtist, type: .artist)
                editView.delegate = self

                present(editView, animated: true)
            }
            
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
        
        configureEditButton()
        configurePreview()
        configureConvertedLabel()
        
        configureOutputTextField()
        configureInputTextField()
        
        configureCopyButton()
        configureShareButton()
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
        inputField.isUserInteractionEnabled = false
        
        NSLayoutConstraint.activate([
            inputField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            inputField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            inputField.bottomAnchor.constraint(equalTo: outputField.topAnchor, constant: -20),
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
            loadingIndicator.bottomAnchor.constraint(equalTo: outputField.bottomAnchor)
        ])
    }
    
    /**
     Configure and position `outputField` (`PolyphonicTextField`).
     */
    private func configureOutputTextField() {
        view.addSubview(outputField)
        outputField.isUserInteractionEnabled = false
        
        NSLayoutConstraint.activate([
            outputField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            outputField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -65),
            outputField.bottomAnchor.constraint(equalTo: convertedLabel.topAnchor, constant: -20)
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
            copyButton.centerXAnchor.constraint(equalTo: view.trailingAnchor, constant: -85)
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
            shareButton.centerXAnchor.constraint(equalTo: view.trailingAnchor, constant: -37)
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
            convertedLabel.bottomAnchor.constraint(equalTo: sharePreview.topAnchor, constant: -20),
        ])
    }
    
    /**
     Configure and position `preview` which previews the translated music. Also configures `editButton` for translation refining.
     */
    private func configurePreview() {
        view.addSubview(sharePreview)
        sharePreview.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            sharePreview.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sharePreview.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -115),
            sharePreview.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.895),
            sharePreview.heightAnchor.constraint(equalTo: sharePreview.widthAnchor, multiplier: 0.48),
        ])
    }
    
    /**
     Configure and position `editButton` and enables or disables the button depending on whether alternatives are available.
     */
    private func configureEditButton() {
        view.addSubview(editButton)
        editButton.translatesAutoresizingMaskIntoConstraints = false

        if ((alts.count > 1) || (altArtists.count > 1)) {
            editButton.isUserInteractionEnabled = true

            editButton.configuration?.baseForegroundColor = .label
            
            // color code edit button depending on whether an exact match was found
            if (match.rawValue < TranslationMatchLevel.exact.rawValue) {
                editButton.configuration?.baseBackgroundColor = .systemYellow
                editButton.configuration?.baseForegroundColor = UIColor(named: "EditLabelColor")
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

            // drop shadow
            editButton.layer.shadowColor = UIColor.clear.cgColor
        }

        NSLayoutConstraint.activate([
            editButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            editButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -65)
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
            loadingIndicatorEdit.topAnchor.constraint(equalTo: sharePreview.bottomAnchor, constant: 18)
        ])
    }
    
    /**
     Setup navigation bar with cancel button.
     */
    private func setupNavBar() {
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelAction))
        cancelButton.tintColor = .label
        
        self.navigationItem.leftBarButtonItem = cancelButton
    }
    
    /**
     Close the share extension when the cancel button is pressed.
     */
    @objc private func cancelAction() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}

@objc(CustomShareNavigationController)
class CustomShareNavigationController: UINavigationController {
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        // 2: set the ViewControllers
        self.setViewControllers([ShareVC()], animated: false)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

/**
 Allows edit sheet to pass data back to this main view.
 */
extension ShareVC: EditVCDelegate {
    func updateSelection(withSong song: Song) {
        keySong = song
        
        // first show empty preview
        sharePreview.update(art: nil, title: "", album: "", artist: "", isExplicit: false, placeholder: true)
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
    
    func updateSelection(withArtist artist: Artist) {
        keyArtist = artist
        
        // first show empty preview
        sharePreview.update(art: nil, title: "", album: "", artist: "", isExplicit: false, placeholder: true)
        outputField.text = ""
        outputField.placeholder = "Loading..."
        
        Task {
            await setupPreview(fromArtist: artist)
            // set output to alt song's link
            outLink = artist.getTranslatedURLasString()
            outputField.text = outLink
        }
        
        outputField.placeholder = "New link..."
    }
}
