//
//  CustomTableViewCell.swift
//  Bryt
//
//  Created by Malcolm Parrish on 1/5/16.
//  Copyright © 2016 Bryt. All rights reserved.
//

import Foundation

class CustomTableViewCell: UITableViewCell {
    
    let imgUser = UIImageView()
    let labUerName = UILabel()
    let labMessage = UILabel()
    let labTime = UILabel()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imgUser.backgroundColor = UIColor.blueColor()
        
        imgUser.translatesAutoresizingMaskIntoConstraints = false
        labUerName.translatesAutoresizingMaskIntoConstraints = false
        labMessage.translatesAutoresizingMaskIntoConstraints = false
        labTime.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(imgUser)
        contentView.addSubview(labUerName)
        contentView.addSubview(labMessage)
        contentView.addSubview(labTime)
        
        let viewsDict = [
            "image" : imgUser,
            "username" : labUerName,
            "message" : labMessage,
            "labTime" : labTime,
        ]
        
        contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-[image(10)]", options: [], metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[labTime]-|", options: [], metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-[username]-[message]-|", options: [], metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[username]-[image(10)]-|", options: [], metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[message]-[labTime]-|", options: [], metrics: nil, views: viewsDict))
    }
    
}