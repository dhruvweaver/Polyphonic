//
//  PreviewTableCell.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 6/15/23.
//

import UIKit

/**
 `UITableViewCell` for displaying a series of alternate previews.
 */
class PolyphonicTableViewCell: UITableViewCell {
    static let identifier = "previewCell"
    var preview = PolyphonicPreview(art: nil, title: "song", album: "album", artist: "artist", isExplicit: false, placeholder: true)

    var songStr: String = ""
    var song: Song? {
        didSet {
            if let song = song {
                Task {
                    let art = song.getTranslatedImgData()
                    var title: String
                    if (type == .song) {
                        title = song.getTitle()
                    } else {
                        title = "Album"
                    }
                    let album = song.getAlbum()
                    let artist = song.getArtists()[0]
                    let isExplicit = song.getExplicit()
                    
                    preview.update(art: art, title: title, album: album, artist: artist, isExplicit: isExplicit, placeholder: false)
                }
            }
        }
    }
    var type: MusicType = .song
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        debugPrint("Displaying preview")
        
        self.contentView.addSubview(preview)
        preview.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            preview.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor),
            preview.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
            preview.widthAnchor.constraint(equalTo: self.contentView.widthAnchor, multiplier: 0.895),
            preview.heightAnchor.constraint(equalTo: preview.widthAnchor, multiplier: 0.3),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
