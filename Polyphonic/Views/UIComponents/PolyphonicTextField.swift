//
//  PolyphonicTextField.swift
//  polyphonic_fr
//
//  Created by Dhruv Weaver on 6/12/23.
//

import UIKit

/**
 `UITextField` in the style of the Polyphonic design language.
 Notably, this modification applies an uneven padding with more space on the right (27 pts) for an attached button.
 */
class PolyphonicTextField: UITextField {
    
    /**
     Creates a new `UITextField` in the style of the Polyphonic design language.
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
     Creates a new `UITextField` in the style of the Polyphonic design language.
     - Parameter placeholderText: provide a `String` for the text field's placeholder.
     - Parameter keyboardType: provide a `UIKeyboardType` for the type of keyboard used with this text field.
     */
    init(placeholderText: String, keyboardType: UIKeyboardType) {
        super.init(frame: .zero)
        
        translatesAutoresizingMaskIntoConstraints = false
        
        placeholder = placeholderText
        autocorrectionType = UITextAutocorrectionType.no
        self.keyboardType = keyboardType
        autocapitalizationType = .none
        returnKeyType = UIReturnKeyType.done
        // clearButtonMode = UITextField.ViewMode.whileEditing
        layer.borderWidth = 2.5
        layer.cornerRadius = 19
        font = UIFont(name: "SpaceMono-Regular", size: 16)
        
        layer.borderColor = UIColor.label.cgColor
    }
    
    // extra padding on the right to account for buttons that sit on the right side of a text field
    private let padding = UIEdgeInsets(top: 5.85, left: 15, bottom: 5.85, right: 42);
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    /**
     Changes text field border color to adapt to light/dark mode changes.
     */
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if(traitCollection.userInterfaceStyle == .dark){
            layer.borderColor = UIColor.label.cgColor
        } else {
            layer.borderColor = UIColor.label.cgColor
        }
    }
    
}
