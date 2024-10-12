//
//  PlaylistOverviewVC.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 7/19/23.
//

import UIKit

class PlaylistOverviewVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private var playlistTableView = UITableView()
    
    private var playlist: Playlist = Playlist(id: "", name: "", creator: "", platform: .unknown, originalURL: nil, converted: false, songs: [])
    
    init(playlist: Playlist) {
        super.init(nibName: nil, bundle: nil)
        self.playlist = playlist
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        title = playlist.name
        
        view.addSubview(playlistTableView)
        playlistTableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            playlistTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            playlistTableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            playlistTableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            playlistTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        playlistTableView.dataSource = self
        playlistTableView.delegate = self

        playlistTableView.register(PolyphonicTableViewCell.self, forCellReuseIdentifier: PolyphonicTableViewCell.identifier)
    }
    
    /**
     Tells the table view how many objects there are to list.
     */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlist.songs.count
    }
    
    /**
     Tells the table view what each cell should be. This app uses a custom cell `PolyphonicTableViewCell`.
     */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let song = playlist.songs[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: PolyphonicTableViewCell.identifier, for: indexPath) as! PolyphonicTableViewCell
        
        cell.type = .song
        cell.song = song
        return cell
    }
    
//    /**
//     When an alternate song is selected from the table, the sheet closes and passes that information back to the home view.
//     */
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let song = newAltSongs[indexPath.row]
//        self.delegate?.updateSelection(withSong: song)
//        dismiss(animated: true, completion: nil)
//    }
    
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
