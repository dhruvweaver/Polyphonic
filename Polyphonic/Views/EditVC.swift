//
//  EditVC.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 6/14/23.
//

import UIKit

/**
 Allows for the edit sheet to send the selected song back to the home view.
 */
protocol EditVCDelegate: UIViewController {
    func updateSelection(withSong song: Song)
    func updateSelection(withArtist artist: Artist)
}

/**
 `UIViewController` that displays a list of alternative songs based on an array of songs.
 */
class EditVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    weak var delegate: EditVCDelegate?
    
    private var altSongs: [String] = []
    private var altArtists: [Artist] = []
    private var alts: [Song] = []
    private var currentSong: Song = Song(title: "", ISRC: "", artists: [""], album: "", albumID: "", explicit: false, trackNum: 0)
    private var currentArtist: Artist = Artist(name: "")
    private var type: MusicType = .song
    
    private var newAltSongs: [Song] = []
    private var newAltArtists: [Artist] = []
    
    private let previewTableView = UITableView()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
     Creates a new `UIViewController` that presents alternative songs for the user to pick from.
     - Parameter altSongs: list of song names as a `String`.
     - Parameter alts: list of `Song` objects.
     - Parameter currentSong: the currently selected song object for excluding from list of alternatives.
     */
    init(altSongs: [String], alts: [Song], currentSong: Song, type: MusicType) {
        super.init(nibName: nil, bundle: nil)
        
        self.altSongs = altSongs
        self.alts  = alts
        self.currentSong = currentSong
        self.type = type
        
        newAltSongs = alts.filter({$0.getTranslatedURL() != currentSong.getTranslatedURL()})
    }
    
    /**
      Creates a new `UIViewController` that presents alternative songs for the user to pick from.
      - Parameter altSongs: list of song names as a `String`.
      - Parameter alts: list of `Song` objects.
      - Parameter currentSong: the currently selected song object for excluding from list of alternatives.
      */
     init(altArtists: [Artist], currentArtist: Artist, type: MusicType) {
         super.init(nibName: nil, bundle: nil)
         
         self.altArtists = altArtists
         self.currentArtist = currentArtist
         self.type = type
         
         newAltArtists = altArtists.filter({$0.getTranslatedURL() != currentArtist.getTranslatedURL()})
     }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        /*--------------------- Add navigation bar with cancel button ---------------------*/
        let navbar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 40))
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navbar.standardAppearance = navAppearance

        let navItem = UINavigationItem()
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancel))
        cancelButton.tintColor = .label
        navItem.leftBarButtonItem = cancelButton

        navbar.items = [navItem]
        view.addSubview(navbar)
        /*---------------------------------------------------------------------------------*/
        
        view.backgroundColor = .systemBackground
        
        view.addSubview(previewTableView)
        previewTableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            previewTableView.topAnchor.constraint(equalTo: navbar.bottomAnchor),
            previewTableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            previewTableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            previewTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        previewTableView.dataSource = self
        previewTableView.delegate = self

        previewTableView.register(PolyphonicTableViewCell.self, forCellReuseIdentifier: PolyphonicTableViewCell.identifier)
    }
    
    /**
     Tells the table view how many objects there are to list.
     */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (type != .artist) {
            return newAltSongs.count
        } else {
            return newAltArtists.count
        }
    }
    
    /**
     Tells the table view what each cell should be. This app uses a custom cell `PolyphonicTableViewCell`.
     */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (type != .artist) {
            let song = newAltSongs[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: PolyphonicTableViewCell.identifier, for: indexPath) as! PolyphonicTableViewCell
            
            cell.type = type
            cell.song = song
            return cell
        } else {
            let artist = newAltArtists[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: PolyphonicTableViewCell.identifier, for: indexPath) as! PolyphonicTableViewCell
            
            cell.type = type
            cell.artist = artist
            return cell
        }
    }
    
    /**
     When an alternate song is selected from the table, the sheet closes and passes that information back to the home view.
     */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (type != .artist) {
            let song = newAltSongs[indexPath.row]
            self.delegate?.updateSelection(withSong: song)
            dismiss(animated: true, completion: nil)
        } else {
            let artist = newAltArtists[indexPath.row]
            self.delegate?.updateSelection(withArtist: artist)
            dismiss(animated: true, completion: nil)
        }
    }
    
    /**
     Tells the table view how tall the rows should be. They have a height of `140`.
     */
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }
    
    /**
     Dismisses the sheet.
     */
    @objc func cancel() {
        self.dismiss(animated: true, completion: nil)
    }
}
