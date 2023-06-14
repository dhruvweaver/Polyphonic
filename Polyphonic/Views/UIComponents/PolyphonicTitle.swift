//
//  PolyphonicTitle.swift
//  polyphonic_fr
//
//  Created by Dhruv Weaver on 6/13/23.
//

import UIKit

/**
 `UIView` for creating title bars following the Polyphonic design language.
 */
class PolyphonicTitle: UIView {
    private let titleLabel = UILabel()
    
    /**
     Creates new `UIView` for making title bars following the Polyphonic design language.
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
     Creates new `UIView` for making title bars following the Polyphonic design language.
     - Parameter title: `String` for navigation title
     */
    init(title: String) {
        super.init(frame: .zero)
        addSubview(titleLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = UIFont(name: "SpaceMono-Bold", size: 34)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
    }
}
