//
//  ViewTableViewCell.swift
//  UnitLensVer3
//
//  Created by 大内亮 on 2024/09/21.
//

import UIKit

class ViewTableViewCell: UITableViewCell {
    
    @IBOutlet var unitLabel: UILabel!
    @IBOutlet var unitValue: UILabel!
    @IBOutlet var unitImage: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        self.backgroundView = nil
        self.contentView.layer.cornerRadius = 10
        self.contentView.layer.masksToBounds = true
        unitImage.layer.cornerRadius = unitImage.frame.size.width / 2
        unitImage.clipsToBounds = true
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setCell(unitLabel: String, unitValue: Double, unitImage: UIImage){
        self.unitLabel.text = unitLabel
        self.unitValue.textColor = UIColor.red
        self.unitValue.text = String(unitValue)
        self.unitImage.image = unitImage
        
    }
    
}
