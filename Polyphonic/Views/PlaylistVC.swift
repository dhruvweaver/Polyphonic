//
//  SettingsVC.swift
//  polyphonic_fr
//
//  Created by Dhruv Weaver on 6/13/23.
//

import UIKit

class PlaylistVC: UIViewController, UITextFieldDelegate {
    
    /* UI elements: */
    private let playlistTitleBar = PolyphonicTitle(title: "Polyphonic")
    private let segmentControl = UISegmentedControl()
    
    private var exportStr = ""
    private var importStr = ""
    private let playlistLinkField = PolyphonicTextField(placeholderText: "Enter a playlist link", keyboardType: .URL)
    
    private let pasteButton = PolyphonicButton(icon: "doc.on.clipboard")
    
    private let getPlaylistButton = PolyphonicButton(title: "Get Playlist")
    
    private let previewLabel = UILabel()
    
    private var exportPlaylist: Playlist = Playlist(id: "", name: "", creator: "", platform: .unknown, originalURL: nil, converted: false, songs: [])
    private var exportImage: Data? = nil
    private var gotExport: Bool = false
    private var importPlaylist: Playlist = Playlist(id: "", name: "", creator: "", platform: .unknown, originalURL: nil, converted: false, songs: [])
    private var importImage: Data? = nil
    private var gotImport: Bool = false
    private let playlistPreview = PolyphonicPreview(art: nil, title: "No Playlist", album: "123", artist: "No creator", isExplicit: false, placeholder: true)
    
    // TODO: change to "Next" button
    private let convertPlaylistButton = PolyphonicButton(title: "Convert")
    private let nextButton = PolyphonicButton(title: "Next")
    private let loadingIndicatorNext = UIActivityIndicatorView(style: .medium)
    
    private var progressBarTimer: Timer!
    private var isLoading: Bool = false
    private var counter = ProgressCounter()
    private let progressIndicator = UIProgressView(progressViewStyle: .bar)
    
    private let loadingLabel = UILabel()
    
    private var playlist: Playlist = Playlist(id: "", name: "", creator: "", platform: .unknown, originalURL: nil, converted: false, songs: [])
    
    
    // pasteboard for reading and writing clipboard data
    // TODO: try using same pasteboard as main view later
    private let pasteboard = UIPasteboard.general
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .systemBackground
        
        // setup segment controller
        segmentControl.insertSegment(withTitle: "Export", at: 0, animated: true)
        segmentControl.insertSegment(withTitle: "Import", at: 1, animated: true)
        segmentControl.selectedSegmentIndex = 0
        
        configureUI()
        
        playlistLinkField.delegate = self
        
        /* Allows for dismissal of keyboard on swipe or tap outside of text field */
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(endEditing))
        swipeGesture.direction = .down
        view.addGestureRecognizer(tapGesture)
        view.addGestureRecognizer(swipeGesture)
    }
    
    // MARK: - Logic
    
    /**
     Close keyboard.
     */
    @objc private func endEditing() {
        view.endEditing(true)
        
        if (segmentControl.selectedSegmentIndex == 0) {
            if let text = playlistLinkField.text {
                exportStr = text
            }
        } else {
            if let text = playlistLinkField.text {
                importStr = text
            }
        }
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
    
    @objc private func segmentControlChanged() {
        if (segmentControl.selectedSegmentIndex == 0) {
            debugPrint("export was selected")
            
            Task {
                await setupPreview(playlist: exportPlaylist)
            }
        } else {
            debugPrint("import was selected")
            
            Task {
                await setupPreview(playlist: importPlaylist)
            }
        }
        
        configureUI()
    }
    
    /**
     Gets text from `pasteboard` and places it in `inputField.text` and the corresponding `String`, `inLink`.
     */
    @objc private func pasteButtonHandler() {
        buttonClick()
        
        if let inLink = pasteboard.string {
            if (segmentControl.selectedSegmentIndex == 0) {
                exportStr = inLink
                playlistLinkField.text = exportStr
            } else {
                importStr = inLink
                playlistLinkField.text = importStr
            }
        } else {
            print("Could not find any pasteboard content")
            return
        }
    }
    
    /**
     Populates preview UI element with data from a provided `Song`.
     - Parameter fromSong:`Song` for displaying preview.
     */
    private func setupPreview(playlist: Playlist) async {
        let title = playlist.name
        let album = "\(playlist.songs.count) tracks"
        let artist = playlist.creator
        let isExplicit = false
        
        if ((segmentControl.selectedSegmentIndex == 0) && (gotExport)) {
            playlistPreview.update(art: exportImage, title: title, album: album, artist: artist, isExplicit: isExplicit, placeholder: false)
        } else if ((segmentControl.selectedSegmentIndex == 1) && (gotImport)) {
            playlistPreview.update(art: importImage, title: title, album: album, artist: artist, isExplicit: isExplicit, placeholder: false)
        } else {
            playlistPreview.update(art: nil, title: "", album: "", artist: "", isExplicit: false, placeholder: true)
        }
    }
    
    @objc func getPlaylistButtonHandler() {
        buttonDeepClick()
        
        // close keyboard
        endEditing()
        
        if (segmentControl.selectedSegmentIndex == 0) { // if exporting
            if let link = playlistLinkField.text {
                print("Getting playlist data for export: \(link)")
                
                
                playlistPreview.update(art: nil, title: "", album: "", artist: "", isExplicit: false, placeholder: true)
                
                Task {
                    let results = await getPlaylistData(fromURL: link)
                    
                    if let playlist = results.1 {
                        self.playlist = playlist
                        
                        gotExport = true
                        
                        exportPlaylist = playlist
                        exportImage = await getImageData(imageURL: playlist.getImageURL())
                        await setupPreview(playlist: exportPlaylist)
                    } else {
                        gotExport = false
                        
                        playlistLinkField.text = results.0
                    }
                    
                    configureConvertPlaylistButton()
                }
            } else {
                debugPrint("Error: could not get text from input field")
                
                gotExport = false
                
                configureConvertPlaylistButton()
                
                return
            }
        } else { // if importing
            if let code = playlistLinkField.text {
                print("Getting playlist data for import: \(code)")
                
                
                playlistPreview.update(art: nil, title: "", album: "", artist: "", isExplicit: false, placeholder: true)
                
                Task {
                    let results = await getPlaylistData(fromCode: code)
                    
                    if let playlist = results.1 {
                        self.playlist = playlist
                        
                        gotImport = true
                        
                        importPlaylist = playlist
                        importImage = await getImageData(imageURL: playlist.getImageURL())
                        await setupPreview(playlist: importPlaylist)
                    } else {
                        gotImport = false
                        
                        playlistLinkField.text = results.0
                    }
                    
                    configureConvertPlaylistButton()
                }
            } else {
                debugPrint("Error: could not get text from input field")
                
                gotImport = false
                
                configureConvertPlaylistButton()
                
                return
            }
        }
    }
    
    @objc private func updateProgress() {
        loadingLabel.text = "\(counter.value) of \(playlist.songs.count)"
        
        progressIndicator.progress = Float(counter.value) / Float(playlist.songs.count)
        progressIndicator.setProgress(progressIndicator.progress, animated: true)
        if(progressIndicator.progress == 1.0)
        {
            progressBarTimer.invalidate()
            isLoading = false
        }
    }
    
    /**
     Launches edit modal sheet for chooseing from alternative translations.
     */
    @objc private func convertPlaylistButtonHandler() {
        buttonClick()
        
        counter.reset()
        loadingLabel.text = "0 of \(playlist.songs.count)"
        progressBarTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateProgress), userInfo: nil, repeats: true)
        
        Task {
            isLoading = true
            
            /* turn convert button into loading indicator */
            convertPlaylistButton.removeFromSuperview()
            
            if ((segmentControl.selectedSegmentIndex == 0 && !exportPlaylist.converted)
                || (segmentControl.selectedSegmentIndex == 1 && !importPlaylist.converted)) {
                configureProgressIndicator()
                configureLoadingLabel()
                progressIndicator.progress = 0.0
                
                await translatePlaylistContent(playlist: playlist, counter: counter)
                
                let converted = convertToPolyphonicPlaylistData(playlist: playlist)
                
                if let polyphonicPlaylistData = converted {
                    print("Counter: \(counter.value)")
                    let success = await postPolyphonicPlaylistData(playlistData: polyphonicPlaylistData)
                    
                    if (!success) {
                        playlistLinkField.text = "Error"
                    } else {
                        playlistLinkField.text = "Uploaded!"
                    }
                }
                
                /* turn loading indicator into next button */
                progressIndicator.removeFromSuperview()
                loadingLabel.removeFromSuperview()
            }
            
            configureNextButton()
        }
    }
    
    @objc private func nextButtonHandler() {
        buttonClick()
        
        navigationController?.pushViewController(PlaylistOverviewVC(playlist: playlist), animated: true)
    }
    
    // MARK: - UI Configuration
    
    /**
     Configures UI by calling each UI component's configure function, each of which also positions the component.
     */
    private func configureUI() {
        configureTitleBar()
        configureSegmentControl()
        configureGetPlaylistButton()
        configureLinkTextField()
        configurePreviewLabel()
        configurePasteButton()
        configurePreview()
        
        if ((segmentControl.selectedSegmentIndex == 0 && !exportPlaylist.converted)
            || (segmentControl.selectedSegmentIndex == 1 && !importPlaylist.converted)) { // TODO: need to fix "converted" tracking, it is now always true
            configureConvertPlaylistButton()
        } else {
            configureNextButton()
        }
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
    
    private func configureSegmentControl() {
        view.addSubview(segmentControl)
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        
        let font = UIFont(name: "SpaceMono-Regular", size: 14)!
        segmentControl.setTitleTextAttributes([NSAttributedString.Key.font: font], for: .normal)
        
        segmentControl.addTarget(self, action: #selector(segmentControlChanged), for: .valueChanged)
        
        NSLayoutConstraint.activate([
            segmentControl.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.54),
            segmentControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            segmentControl.topAnchor.constraint(equalTo: playlistTitleBar.bottomAnchor, constant: 60)
        ])
    }
    
    /**
     Configure and position text field to take a playlist link for playlist conversion.
     */
    private func configureLinkTextField() {
        view.addSubview(playlistLinkField)
        playlistLinkField.translatesAutoresizingMaskIntoConstraints = false
        
        if (segmentControl.selectedSegmentIndex == 0) {
            playlistLinkField.placeholder = "Enter a playlist link"
            playlistLinkField.text = exportStr
        } else {
            playlistLinkField.placeholder = "Enter a playlist code"
            playlistLinkField.text = importStr
        }
        
        NSLayoutConstraint.activate([
            playlistLinkField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playlistLinkField.centerYAnchor.constraint(equalTo: getPlaylistButton.topAnchor, constant: -30),
            playlistLinkField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9)
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
            pasteButton.centerYAnchor.constraint(equalTo: playlistLinkField.centerYAnchor),
            pasteButton.centerXAnchor.constraint(equalTo: view.trailingAnchor, constant: -37)
        ])
    }
    
    /**
     Configure and position button that gets playlist data from a streaming service, based on the provided link.
     */
    private func configureGetPlaylistButton() {
        view.addSubview(getPlaylistButton)
        getPlaylistButton.translatesAutoresizingMaskIntoConstraints = false
        
        getPlaylistButton.configuration?.baseBackgroundColor = .label
        getPlaylistButton.configuration?.baseForegroundColor = .systemBackground
        
        getPlaylistButton.addTarget(self, action: #selector(buttonDeepClick), for: .touchDown)
        getPlaylistButton.addTarget(self, action: #selector(getPlaylistButtonHandler), for: .touchUpInside)
        getPlaylistButton.addTarget(self, action: #selector(buttonSoftClick), for: .touchDragExit)
        
        NSLayoutConstraint.activate([
            getPlaylistButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            getPlaylistButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -65),
            getPlaylistButton.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -400)
        ])
    }
    
    /**
     Configure and position `previewLabel`.
     `UILabel` describing the playlist preview below.
     */
    private func configurePreviewLabel() {
        view.addSubview(previewLabel)
        
        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        previewLabel.text = "Playlist Preview"
        previewLabel.font = UIFont(name: "SpaceMono-Regular", size: 20)
        
        NSLayoutConstraint.activate([
            previewLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            previewLabel.topAnchor.constraint(equalTo: getPlaylistButton.bottomAnchor, constant: 99)
        ])
    }
    
    /**
     Configure and position `preview` which previews the translated music. Also configures `editButton` for translation refining.
     */
    private func configurePreview() {
        view.addSubview(playlistPreview)
        playlistPreview.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            playlistPreview.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playlistPreview.topAnchor.constraint(equalTo: previewLabel.bottomAnchor, constant: 20),
            playlistPreview.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.895),
            playlistPreview.heightAnchor.constraint(equalTo: playlistPreview.widthAnchor, multiplier: 0.48),
        ])
    }
    
    /**
     Configure and position `convertPlaylistButton` and enables or disables the button depending on whether alternatives are available.
     */
    private func configureConvertPlaylistButton() {
        view.addSubview(convertPlaylistButton)
        convertPlaylistButton.translatesAutoresizingMaskIntoConstraints = false
        
        if ((segmentControl.selectedSegmentIndex == 0 && gotExport) || (segmentControl.selectedSegmentIndex == 1 && gotImport)) {
            convertPlaylistButton.isUserInteractionEnabled = true
            
            convertPlaylistButton.configuration?.baseForegroundColor = .label
            convertPlaylistButton.configuration?.baseBackgroundColor = .systemBackground
            
            // drop shadow
            convertPlaylistButton.layer.shadowColor = UIColor.label.cgColor
            
            convertPlaylistButton.addTarget(self, action: #selector(buttonClick), for: .touchDown)
            convertPlaylistButton.addTarget(self, action: #selector(convertPlaylistButtonHandler), for: .touchUpInside)
        } else {
            convertPlaylistButton.isUserInteractionEnabled = false
            convertPlaylistButton.configuration?.baseForegroundColor = .systemGray4
            convertPlaylistButton.configuration?.baseBackgroundColor = .systemBackground
            
            // drop shadow
            convertPlaylistButton.layer.shadowColor = UIColor.clear.cgColor
        }
        
        NSLayoutConstraint.activate([
            convertPlaylistButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            convertPlaylistButton.topAnchor.constraint(equalTo: playlistPreview.bottomAnchor, constant: 12)
        ])
    }
    
    /**
     Configure and position `nextButton` and enables or disables the button depending on whether alternatives are available.
     */
    private func configureNextButton() {
        view.addSubview(nextButton)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        
        if ((segmentControl.selectedSegmentIndex == 0 && gotExport) || (segmentControl.selectedSegmentIndex == 1 && gotImport)) {
            nextButton.isUserInteractionEnabled = true
            
            nextButton.configuration?.baseForegroundColor = .label
            nextButton.configuration?.baseBackgroundColor = .systemBackground
            
            // drop shadow
            nextButton.layer.shadowColor = UIColor.label.cgColor
            
            nextButton.addTarget(self, action: #selector(buttonClick), for: .touchDown)
//            nextButton.addTarget(self, action: #selector(convertPlaylistButtonHandler), for: .touchUpInside)
        } else {
            nextButton.isUserInteractionEnabled = false
            nextButton.configuration?.baseForegroundColor = .systemGray4
            nextButton.configuration?.baseBackgroundColor = .systemBackground
            
            // drop shadow
            nextButton.layer.shadowColor = UIColor.clear.cgColor
        }
        
        NSLayoutConstraint.activate([
            nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nextButton.topAnchor.constraint(equalTo: playlistPreview.bottomAnchor, constant: 12)
        ])
    }
    
    /**
     Configure and position `loadingIndicatorEdit` in the same place as the edit button.
     */
    private func configureLoadingIndicatorNext() {
        view.addSubview(loadingIndicatorNext)
        loadingIndicatorNext.translatesAutoresizingMaskIntoConstraints = false
        
        loadingIndicatorNext.hidesWhenStopped = true
        loadingIndicatorNext.color = .label
        
        NSLayoutConstraint.activate([
            loadingIndicatorNext.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicatorNext.topAnchor.constraint(equalTo: playlistPreview.bottomAnchor, constant: 18)
        ])
    }
    
    private func configureProgressIndicator() {
        view.addSubview(progressIndicator)
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        progressIndicator.tintColor = .label
        progressIndicator.backgroundColor = UIColor(named: "CustomGray")
        
        NSLayoutConstraint.activate([
            progressIndicator.topAnchor.constraint(equalTo: playlistPreview.bottomAnchor, constant: 15),
            progressIndicator.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20.5),
            progressIndicator.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20.5),
            progressIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func configureLoadingLabel() {
        view.addSubview(loadingLabel)
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        
        loadingLabel.font = UIFont(name: "SpaceMono-Regular", size: 15)
        
        NSLayoutConstraint.activate([
            loadingLabel.topAnchor.constraint(equalTo: progressIndicator.bottomAnchor, constant: 5),
            loadingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
}
