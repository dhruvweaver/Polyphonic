//
//  PolyphonicButton.swift
//  polyphonic_fr
//
//  Created by Dhruv Weaver on 6/12/23.
//

import UIKit

/**
 `UIButton` in the style of the Polyphonic design language.
 */
class PolyphonicButton: UIButton {
    // only icon buttons are without a custom border, as they come with their own circle shape
    private let customBorder: Bool
    
    /**
     Creates a new `UIButton` in the style of the Polyphonic design language.
     */
    override init(frame: CGRect) {
        customBorder = true
        super.init(frame: .zero)
        
        configure()
        
        applyPadding(customVertPadding: nil)
    }
    
    /**
     NOT IMPLEMENTED!
     Will cause a fatal error.
     */
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
     Creates a new `UIButton` in the style of the Polyphonic design language.
     - Parameter title: provide a `String` for the button's title.
     */
    init(title: String) {
        customBorder = true
        super.init(frame: .zero)
        
        configure()
        configuration?.baseBackgroundColor = .systemBackground
        configuration?.baseForegroundColor = .label
        configuration?.title = title
        // use custom font
        configuration?.attributedTitle = AttributedString(title, attributes: AttributeContainer([NSAttributedString.Key.font: UIFont(name: "SpaceMono-Regular", size: 16)!]))
        layer.cornerRadius = 19
        
        // drop shadow
        layer.shadowColor = UIColor.label.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 5
        layer.shadowOffset = CGSize(width: 0, height: 0)
        
        applyPadding(customVertPadding: 6.85)
    }
    
    /**
     Creates a new UIButton in the style of the Polyphonic design language. These use their own built in rounding.
     - Parameter icon: provide a `String` for the button's icon.
     */
    init(icon: String) {
        customBorder = false
        super.init(frame: .zero)
        
        configure()
        configuration?.baseBackgroundColor = .label
        configuration?.baseForegroundColor = .systemBackground
        configuration?.image = UIImage(systemName: icon)
        
        // drop shadow
        layer.shadowColor = UIColor.label.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 2
        layer.shadowOffset = CGSize(width: 0, height: 0)
        
        applyPadding(customVertPadding: nil)
    }
    
    /**
     Configure button styling.
     Note: Other configurations should be made after this is called, not before.
     */
    private func configure() {
        translatesAutoresizingMaskIntoConstraints = false
        
        configuration = .filled()
        configuration?.baseBackgroundColor = .label
        configuration?.baseForegroundColor = .systemBackground
        configuration?.cornerStyle = .capsule
        
        if (customBorder) {
            layer.borderWidth = 1.5
            layer.borderColor = UIColor.label.cgColor
        }
    }
    
    /**
     Apply padding to the inside of the button. Default is 8.75 on all edges.
     */
    private func applyPadding(customVertPadding: CGFloat?) {
        let padding: CGFloat = 8.75
        if let vertPadding = customVertPadding {
            configuration?.contentInsets.top = vertPadding
            configuration?.contentInsets.trailing = padding
            configuration?.contentInsets.bottom = vertPadding
            configuration?.contentInsets.leading = padding
        } else {
            configuration?.contentInsets.top = padding
            configuration?.contentInsets.trailing = padding
            configuration?.contentInsets.bottom = padding
            configuration?.contentInsets.leading = padding
        }
    }
    
    /**
     Changes button border and drop shadow color to adapt to light/dark mode changes.
     */
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if(customBorder && (traitCollection.userInterfaceStyle == .dark)){
            layer.borderColor = UIColor.label.cgColor
//            layer.shadowColor = UIColor.label.cgColor;
        } else {
            layer.borderColor = UIColor.label.cgColor
//            layer.shadowColor = UIColor.label.cgColor;
        }
    }
    
}
