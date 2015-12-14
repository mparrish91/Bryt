//
//  LoginViewController.swift
//  Bryt
//
//  Created by Malcolm Parrish on 12/12/15.
//  Copyright © 2015 Bryt. All rights reserved.
//

import Foundation


class LoginViewController: UIViewController {


override func viewDidLoad() {
    super.viewDidLoad()

    
    //Home Screen
    let imageName = "studentStudying.jpg"
    let image = UIImage(named: imageName)
    
    self.imageView.image = image
    self.imageView.contentMode = UIViewContentMode .ScaleAspectFill
    
    loginButton.layer.cornerRadius = 5
    loginButton.layer.borderWidth = 1
    loginButton.layer.borderColor = UIColor.whiteColor().CGColor
    
    }
}