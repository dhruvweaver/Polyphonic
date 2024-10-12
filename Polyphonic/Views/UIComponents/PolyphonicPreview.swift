//
//  PolyphonicPreview.swift
//  polyphonic_fr
//
//  Created by Dhruv Weaver on 6/13/23.
//

import UIKit

/**
 `UIView` for the translated music preview UI.
 */
class PolyphonicPreview: UIView {
    /* UI elements: */
    private var artData: Data? = nil
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private var ratingView = UIImageView()
    private let albumLabel = UILabel()
    private let artistLabel = UILabel()
    private var isExplicit: Bool = false {
        didSet {
            configureUI()
        }
    }
    private var placeholder: Bool = true
    
    /**
     `UIView`for the translated music preview UI.
     */
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    /**
     NOT IMPLEMENTED!
     Will cause a fatal error.
     */
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
     Creates new `UIView`for the translated music preview UI.
     - Parameter artURL: `String` for the album art URL
     - Parameter title: `String` for song title or for "Album" if the music is an album
     - Parameter album: `String` for album name
     - Parameter artist: `String` for artist or band name
     - Parameter isExplicit: `Bool` for whether or not the song or album is explicit
     - Parameter placeholder: `Bool` indicates whether view should be "redacted", overwriting data and hiding details
     */
    init(art: Data?, title: String, album: String, artist: String, isExplicit: Bool, placeholder: Bool) {
        super.init(frame: .zero)
        
        if (!placeholder) {
            artData = art
            titleLabel.text = title
            albumLabel.text = album
            artistLabel.text = artist
            self.isExplicit = isExplicit
            self.placeholder = placeholder
        } else {
            artData = nil
            titleLabel.text = "Song Name"
            albumLabel.text = "Big Album Name"
            artistLabel.text = "Artist/Band"
            self.isExplicit = false
        }
        
        configureUI()
    }
    
    /**
     Updates the translated music preview UI.
     - Parameter artURL: `String` for the album art URL
     - Parameter title: `String` for song title or for "Album" if the music is an album
     - Parameter album: `String` for album name
     - Parameter artist: `String` for artist or band name
     - Parameter isExplicit: `Bool` for whether or not the song or album is explicit
     - Parameter placeholder: `Bool` indicates whether view should be "redacted", overwriting data and hiding details
     */
    func update(art: Data?, title: String, album: String, artist: String, isExplicit: Bool, placeholder: Bool) {
        if (!placeholder) {
            artData = art
            titleLabel.text = title
            albumLabel.text = album
            artistLabel.text = artist
            self.isExplicit = isExplicit
            self.placeholder = placeholder
        } else {
            artData = nil
            self.isExplicit = false
            self.placeholder = true
        }
        
        configureUI()
    }
    
    // MARK: - UI Configuration
    
    /**
     Configures UI by calling each UI component's configure function, each of which also positions the component.
     */
    private func configureUI() {
        configureArt()
        configureText()
    }
    
    /**
     Configures Album, Title, and Artist labels.
     */
    private func configureText() {
        configureAlbum()
        configureTitle()
        configureArtist()
    }
    
    /**
     Configures and gets album art (using `getImageData()`.
     */
    private func configureArt() {
        self.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.backgroundColor = UIColor(named: "CustomGray")
        
        if (!placeholder) {
            if let imageData = artData {
                let image = UIImage(data: imageData)
                imageView.image = image
            }
        } else {
            imageView.image = UIImage()
        }
        
        imageView.layer.masksToBounds = true
//        imageView.layer.cornerRadius = 15
        imageView.layer.borderWidth = 2.5
        imageView.layer.borderColor = UIColor.label.cgColor
        
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalTo: self.heightAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }
    
    /**
     Changes text field border color to adapt to light/dark mode changes.
     */
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if(traitCollection.userInterfaceStyle == .dark){
            imageView.layer.borderColor = UIColor.label.cgColor
        } else {
            imageView.layer.borderColor = UIColor.label.cgColor
        }
    }
    
    /**
     Configures title (song name or "Album") label with or without explicit marker (depending on `isExplicit` status.
     */
    private func configureTitle() {
        // reset these views for when the explicit symbol is added and removed
        titleLabel.removeFromSuperview()
        ratingView.removeFromSuperview()
        
        self.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.font = UIFont(name: "SpaceMono-Bold", size: 17)
        
        if (placeholder) {
            titleLabel.textColor = UIColor(named: "CustomGray")
            titleLabel.backgroundColor = UIColor(named: "CustomGray")
            titleLabel.layer.masksToBounds = true
//            titleLabel.layer.cornerRadius = 4
            
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: albumLabel.leadingAnchor),
                titleLabel.bottomAnchor.constraint(equalTo: albumLabel.topAnchor, constant: -4),
                titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor)
            ])
        } else {
            titleLabel.textColor = .label
            titleLabel.backgroundColor = .clear
            titleLabel.layer.masksToBounds = false
            
            if (isExplicit) { // set up explicit icon
                let weight = UIImage.SymbolConfiguration(pointSize: 17, weight: .bold)
                let color = UIImage.SymbolConfiguration(paletteColors: [.label])
                let configuration = weight.applying(color)
                let ratingSymbol = UIImage(systemName: "e.square", withConfiguration: configuration)
                
                ratingView = UIImageView(image: ratingSymbol)
                
                addSubview(ratingView)
                ratingView.translatesAutoresizingMaskIntoConstraints = false
                
                NSLayoutConstraint.activate([
                    titleLabel.leadingAnchor.constraint(equalTo: albumLabel.leadingAnchor),
                    titleLabel.bottomAnchor.constraint(equalTo: albumLabel.topAnchor, constant: -4),
                    titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -24),
                    
                    ratingView.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 3.5),
                    ratingView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor)
                ])
            } else {
                NSLayoutConstraint.activate([
                    titleLabel.leadingAnchor.constraint(equalTo: albumLabel.leadingAnchor),
                    titleLabel.bottomAnchor.constraint(equalTo: albumLabel.topAnchor, constant: -4),
                    titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor)
                ])
            }
        }
    }
    
    /**
     Configures album label.
     */
    private func configureAlbum() {
        self.addSubview(albumLabel)
        albumLabel.translatesAutoresizingMaskIntoConstraints = false
        
        albumLabel.font = UIFont(name: "SpaceMono-Regular", size: 17)
        
        if (placeholder) {
            albumLabel.textColor = UIColor(named: "CustomGray")
            albumLabel.backgroundColor = UIColor(named: "CustomGray")
            albumLabel.layer.masksToBounds = true
//            albumLabel.layer.cornerRadius = 4
        } else {
            albumLabel.textColor = .label
            albumLabel.backgroundColor = .clear
            albumLabel.layer.masksToBounds = false
        }
        NSLayoutConstraint.activate([
            albumLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 14),
            albumLabel.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            albumLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor)
        ])
    }
    
    /**
     Configures artist label.
     */
    private func configureArtist() {
        self.addSubview(artistLabel)
        artistLabel.translatesAutoresizingMaskIntoConstraints = false
        
        artistLabel.font = UIFont(name: "SpaceMono-Bold", size: 17)
        
        if (placeholder) {
            artistLabel.textColor = UIColor(named: "CustomGray")
            artistLabel.backgroundColor = UIColor(named: "CustomGray")
            artistLabel.layer.masksToBounds = true
//            artistLabel.layer.cornerRadius = 4
        } else {
            artistLabel.textColor = .label
            artistLabel.backgroundColor = .clear
            artistLabel.layer.masksToBounds = false
        }
        NSLayoutConstraint.activate([
            artistLabel.leadingAnchor.constraint(equalTo: albumLabel.leadingAnchor),
            artistLabel.topAnchor.constraint(equalTo: albumLabel.bottomAnchor, constant: 4),
            artistLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor)
        ])
    }
}
