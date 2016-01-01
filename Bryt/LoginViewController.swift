//
//  LoginViewController.swift
//  
//
//  Created by Malcolm Parrish on 1/1/16.
//
//

import UIKit


class LoginViewController: UIViewController {
    
    
    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var loginButton: UIButton!
    
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