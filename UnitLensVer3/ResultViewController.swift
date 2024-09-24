//
//  ResultViewController.swift
//  UnitLensVer3
//
//  Created by 大内亮 on 2024/09/21.
//

import UIKit
import RealmSwift

class ResultViewController: UIViewController, UITextFieldDelegate {

    let realm = try! Realm()
    var uniqueUnitName: String = ""
    var inputFromVC: Double = 0
    var currentUnit: String = ""
    
    var conversionData: ConversionData?
    let conversionAlgorithm = Converter()
    var units: [String] = []
    
    @IBOutlet var unitTypeImage: UIImageView!
    @IBOutlet var layerLabel: UILabel!
    @IBOutlet var conversionRateLabel: UILabel!
    @IBOutlet var inputUniqueTextField: UITextField!
    @IBOutlet var inputOriginalTextField: UITextField!
    @IBOutlet var uniqueUnitNameLabel: UILabel!
    @IBOutlet var unitButton: UIButton!
    @IBOutlet var unitImage: UIImageView!
    @IBOutlet var timesUnitImageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Input from View Controller: \(inputFromVC). Unique Unit Name: \(uniqueUnitName)")
        let unitTypeString = conversionAlgorithm.getUnitCategory(for: currentUnit)
        units = fetchUnits(unitType: unitTypeString ?? "length")
        
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
        
        updateConversion()
        
        setupUnitButtonMenu()
        
        // Set the delegate for text fields
        inputUniqueTextField.delegate = self
        inputOriginalTextField.delegate = self
    }
    
    func updateConversion() {
        guard let conversionData = conversionData else { return }
        
        let conversionRateFromOtherBase = conversionAlgorithm.baseUnitToOtherUnit(
            conversionRate: conversionData.conversionRate,
            baseUnit: conversionData.convertToKey,
            otherUnit: currentUnit
        )
        
        let uniqueValue = inputFromVC * conversionRateFromOtherBase
        inputUniqueTextField.text = "\(uniqueValue)"
        inputOriginalTextField.text = "\(inputFromVC)"
        conversionRateLabel.text = "\(conversionRateFromOtherBase) \(uniqueUnitName)/\(currentUnit)"
        timesUnitImageLabel.text = "✖︎ \(uniqueValue)"
        unitImage.image = conversionData.unitImage ?? UIImage(systemName: "nosign")
    }
    
    func addPaddingToTextField(textField: UITextField) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
    }
    
    func roundEdges<T: UIView>(view: T) {
        view.layer.cornerRadius = 22.0
        view.clipsToBounds = true
    }
    
    func fetchConversionData(for uniqueUnitName: String) -> ConversionData? {
        return realm.objects(ConversionData.self).filter("unitKey == %@", uniqueUnitName).first
    }
    
    func fetchUnits(unitType: String) -> [String] {
        var stringArray: [String] = []
        switch unitType {
        case "length":
            stringArray = conversionAlgorithm.length
        case "weight":
            stringArray = conversionAlgorithm.weight
        case "time":
            stringArray = conversionAlgorithm.time
        default:
            break
        }
        return stringArray
    }
    
    func setupUnitButtonMenu() {
        guard !units.isEmpty else { return }
        
        let actions = units.map { unit in
            UIAction(title: unit, image: nil) { _ in
                self.currentUnit = unit
                self.unitButton.setTitle(unit, for: .normal)
                print("\(unit) selected")
                self.updateConversion()
            }
        }
        
        let menu = UIMenu(title: "Select Unit", children: actions)
        
        unitButton.menu = menu
        unitButton.showsMenuAsPrimaryAction = true
    }
    
    // Update this method to handle both text fields
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text, let value = Double(text) else { return }
        
        if textField == inputOriginalTextField {
            // When inputOriginalTextField is edited
            inputFromVC = value
        } else if textField == inputUniqueTextField {
            // When inputUniqueTextField is edited
            // Reverse conversion from unique to original
            guard let conversionData = conversionData else { return }
            
            let conversionRateFromOtherBase = conversionAlgorithm.baseUnitToOtherUnit(
                conversionRate: conversionData.conversionRate,
                baseUnit: conversionData.convertToKey,
                otherUnit: currentUnit
            )
            
            let originalValue = value / conversionRateFromOtherBase
            inputFromVC = originalValue
            inputOriginalTextField.text = "\(originalValue)"
        }
        
        updateConversion()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
