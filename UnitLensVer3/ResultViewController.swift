//
//  ResultViewController.swift
//  UnitLensVer3
//
//  Created by 大内亮 on 2024/09/21.
//

import UIKit
import RealmSwift

class ResultViewController: UIViewController {
    
    let realm = try! Realm()
    //ex. ぞう,キリン
    var uniqueUnitName: String = ""
    var inputFromVC: Double = 0
    var currentUnit: String = ""
    //Data from VC
    
    var conversionData: ConversionData?
    let conversionAlgorithm = Converter()
    
    //Outlets
    @IBOutlet var unitTypeImage: UIImageView!
    @IBOutlet var layerLabel: UILabel!
    @IBOutlet var conversionRateLabel: UILabel!
    @IBOutlet var inputUniqueTextField: UITextField!
    @IBOutlet var inputOriginalTextField: UITextField!
    @IBOutlet var uniqueUnitNameLabel: UILabel!
    @IBOutlet var unitButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Input from View Controller: \(inputFromVC). Unique Unit Name: \(uniqueUnitName)")
        
        
        
        unitButton.setTitle(currentUnit, for: .normal)
        conversionData = fetchConversionData(for: uniqueUnitName)
        uniqueUnitNameLabel.text = uniqueUnitName

        
        unitTypeImage.image = UIImage(named: conversionAlgorithm.getUnitCategory(for: conversionData!.convertToKey)!)
        roundEdges(view: inputUniqueTextField)
        roundEdges(view: inputOriginalTextField)
        roundEdges(view: conversionRateLabel)
        roundEdges(view: layerLabel)
        
        unitTypeImage.layer.cornerRadius = unitTypeImage.frame.size.width / 2
        unitTypeImage.clipsToBounds = true
        
        addPaddingToTextField(textField: inputUniqueTextField)
        addPaddingToTextField(textField: inputOriginalTextField)
        
        let conversionRateFromOtherBase = conversionAlgorithm.baseUnitToOtherUnit(conversionRate: conversionData!.conversionRate, baseUnit: conversionData!.convertToKey, otherUnit: currentUnit)
        inputUniqueTextField.text = "\(inputFromVC * (conversionRateFromOtherBase))"
        inputOriginalTextField.text = "\(inputFromVC)"
        
        conversionRateLabel.text = "\(conversionRateFromOtherBase) \(uniqueUnitName)/\(currentUnit)"
    }
    
    // Add padding function
    func addPaddingToTextField(textField: UITextField) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
    }
    
    func roundEdges<T: UIView>(view: T){
        view.layer.cornerRadius = 22.0
        view.clipsToBounds = true
    }
    
    //fetch functions
    func fetchConversionData(for uniqueUnitName: String) -> ConversionData? {
        return realm.objects(ConversionData.self).filter("unitKey == %@", uniqueUnitName).first
    }
    
    
}
