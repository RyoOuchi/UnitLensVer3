import UIKit
import RealmSwift

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    let realm = try! Realm()
    @IBOutlet var tableView: UITableView!
    @IBOutlet var unitInput: UITextField!
    @IBOutlet var addUnit: UIBarButtonItem!
    @IBOutlet var changeUnit: UIBarButtonItem!
    let unitTypeArray: [String] = ["length", "weight", "time"]
    var conversionData: [ConversionData] = []
    var unitTypeArrayID: Int = 0
    var buttons: [UIButton] = []
    var blurEffectView: UIVisualEffectView?
    var isAnimatingBlur = false
    var unitTypeNow: String = ""
    var changeButton: UIButton!
    @IBOutlet var unitButton: UIButton!
    var units: [String] = []
    var inputValue: Double = 0
    let conversionAlgorithm = Converter()
    var sendToResultVCName: String = ""
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        unitInput.delegate = self
        unitInput.layer.cornerRadius = 5.0
        unitButton.clipsToBounds = true
        
        conversionData.forEach { unit in
            print(unit)
        }
        
        unitButton.setTitle(conversionAlgorithm.convertToBaseString(inputUnitType: unitTypeArray[unitTypeArrayID]), for: .normal)
        
        units = fetchUnits(unitType: unitTypeArray[unitTypeArrayID])
        
        setupUnitButtonMenu()
        
        tableView.backgroundColor = .clear
        
        conversionData = fetchConversionData()
        
        tableView.separatorStyle = .none
        
        unitButton.layer.cornerRadius = 5.0
        unitButton.clipsToBounds = true
        
        tableView.register(UINib(nibName: "ViewTableViewCell", bundle: nil), forCellReuseIdentifier: "UnitCell")
        
        tableView.delegate = self
        tableView.dataSource = self
        
        changeButton = UIButton(type: .system)
        
        if let image = UIImage(named: unitTypeArray[unitTypeArrayID])?.withRenderingMode(.alwaysOriginal) {
            changeButton.setImage(image, for: .normal)
        } else {
            print("No such image")
        }
        
        changeButton.backgroundColor = UIColor.systemBlue
        changeButton.layer.cornerRadius = 22
        changeButton.clipsToBounds = true
        
        changeButton.translatesAutoresizingMaskIntoConstraints = false
        changeButton.imageView?.contentMode = .scaleAspectFit
        changeUnit.customView = changeButton
        
        NSLayoutConstraint.activate([
            changeButton.widthAnchor.constraint(equalToConstant: 44),
            changeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        changeButton.addTarget(self, action: #selector(changeButtonTapped), for: .touchUpInside)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeRight)
        self.view.addGestureRecognizer(swipeLeft)
        
        unitButton.contentHorizontalAlignment = .left
    }
    
    //Unit type changer
    
    @objc func changeButtonTapped() {
        print("Change button tapped!")
        blurScreenAndShowButtons()
    }
    
    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        blurScreenAndShowButtons()
        switch gesture.direction {
        case .right:
            unitTypeArrayID = (unitTypeArrayID == unitTypeArray.count - 1) ? 0 : unitTypeArrayID + 1
        case .left:
            unitTypeArrayID = (unitTypeArrayID == 0) ? unitTypeArray.count - 1 : unitTypeArrayID - 1
        default:
            break
        }
        updateButtonTitles()
    }
    
    func updateButtonTitles() {
        for (index, button) in buttons.enumerated() {
            let titleIndex = (unitTypeArrayID + index) % unitTypeArray.count
            let unitType = unitTypeArray[titleIndex]
            
            if let updatedImage = UIImage(named: unitType)?.withRenderingMode(.alwaysOriginal) {
                button.setImage(updatedImage, for: .normal)
                button.setTitle(nil, for: .normal)
            } else {
                button.setImage(nil, for: .normal)
                button.setTitle(unitType, for: .normal)
                button.setTitleColor(.white, for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            }
        }
    }
    
    @objc func buttonTapped(_ sender: UIButton) {
        guard let buttonIdentifier = sender.accessibilityIdentifier else {
            print("Button identifier is nil")
            return
        }
        print(buttonIdentifier)
        
        if let index = unitTypeArray.firstIndex(of: buttonIdentifier) {
            unitTypeArrayID = index
        }
        
        DispatchQueue.main.async {
            self.unitTypeNow = self.unitTypeArray[self.unitTypeArrayID]
            
            // Update the image of the `changeButton` directly
            if let newImage = UIImage(named: "\(self.unitTypeArray[self.unitTypeArrayID]).png")?.withRenderingMode(.alwaysOriginal) {
                self.changeButton.setImage(newImage, for: .normal)
            }
            
            // Fetch updated units for the selected unit type and rebuild the menu
            self.units = self.fetchUnits(unitType: self.unitTypeArray[self.unitTypeArrayID])
            self.setupUnitButtonMenu()  // Rebuild the menu based on the updated units
        }
        
        print("Button tapped: \(buttonIdentifier), unitTypeArrayID updated to \(unitTypeArrayID)")
        unitButton.setTitle(conversionAlgorithm.convertToBaseString(inputUnitType: unitTypeArray[unitTypeArrayID]), for: .normal)
        tableView.reloadData()
        deleteBlurView()
    }

    func setupUnitButtonMenu() {
        // Ensure the units array is populated before setting up the menu
        guard !units.isEmpty else { return }
        
        let actions = units.map { unit in
            UIAction(title: unit, image: nil) { _ in
                self.unitButton.setTitle(unit, for: .normal)  // First update the button title
                print("\(unit) selected")
            }
        }
        
        let menu = UIMenu(title: "Select Unit", children: actions)
        
        unitButton.menu = menu
        unitButton.showsMenuAsPrimaryAction = true
    }
    
    func fetchUnits(unitType: String) -> [String] {
        var stringArray: [String] = []
        switch unitType{
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
    
    func blurScreenAndShowButtons() {
        guard blurEffectView == nil else { return }
        
        let middleButtonSize = min(view.bounds.width, view.bounds.height) * 0.4
        let sideButtonSize = min(view.bounds.width, view.bounds.height) * 0.2
        let spacing: CGFloat = 20
        
        blurEffectView = UIVisualEffectView(effect: nil)
        blurEffectView?.frame = view.bounds
        blurEffectView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        navigationController?.navigationBar.isHidden = true
        
        if let blurEffectView = blurEffectView {
            view.addSubview(blurEffectView)
            
            // Create and configure the middle button
            let middleButton = UIButton(type: .system)
            let middleImageName = unitTypeArray[unitTypeArrayID]
            print("Setting middle button identifier to: \(middleImageName)")
            if let middleImage = UIImage(named: middleImageName)?.withRenderingMode(.alwaysOriginal) {
                middleButton.setImage(middleImage, for: .normal)
                middleButton.accessibilityIdentifier = "\(unitTypeArray[unitTypeArrayID])_MiddleButton"
            } else {
                print("Image not found: \(middleImageName)")
                middleButton.setTitle(middleImageName, for: .normal)
                middleButton.setTitleColor(.white, for: .normal)
                middleButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .bold)
                middleButton.accessibilityIdentifier = middleImageName
            }
            print("Middle button identifier after assignment: \(middleButton.accessibilityIdentifier ?? "None")")
            
            middleButton.backgroundColor = UIColor.systemBlue
            middleButton.layer.cornerRadius = middleButtonSize / 2
            middleButton.clipsToBounds = true
            middleButton.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            blurEffectView.contentView.addSubview(middleButton)
            buttons.append(middleButton)
            
            middleButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                middleButton.centerXAnchor.constraint(equalTo: blurEffectView.centerXAnchor),
                middleButton.bottomAnchor.constraint(equalTo: blurEffectView.centerYAnchor, constant: middleButtonSize / 2),
                middleButton.widthAnchor.constraint(equalToConstant: middleButtonSize),
                middleButton.heightAnchor.constraint(equalToConstant: middleButtonSize)
            ])
            
            // Adding side buttons
            for index in [1, 2] {
                let button = UIButton(type: .system)
                let sideButtonID = (unitTypeArrayID + index) % unitTypeArray.count
                let imageName = unitTypeArray[sideButtonID]
                
                if let sideImage = UIImage(named: imageName)?.withRenderingMode(.alwaysOriginal) {
                    button.setImage(sideImage, for: .normal)
                    button.accessibilityIdentifier = "\(imageName)_SideButton"
                    print("side button image name: " + imageName)
                } else {
                    print("Image not found: \(imageName)")
                    button.setTitle(imageName, for: .normal)
                    button.setTitleColor(.white, for: .normal)
                    button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
                    button.accessibilityIdentifier = "\(imageName)_SideButton"
                }
                button.backgroundColor = UIColor.systemBlue
                button.layer.cornerRadius = sideButtonSize / 2
                button.clipsToBounds = true
                button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
                blurEffectView.contentView.addSubview(button)
                buttons.append(button)
                
                button.translatesAutoresizingMaskIntoConstraints = false
                let horizontalOffset: CGFloat = (index == 1) ? -middleButtonSize / 2 - sideButtonSize / 2 - spacing : middleButtonSize / 2 + sideButtonSize / 2 + spacing
                NSLayoutConstraint.activate([
                    button.centerXAnchor.constraint(equalTo: blurEffectView.centerXAnchor, constant: horizontalOffset),
                    button.bottomAnchor.constraint(equalTo: middleButton.bottomAnchor),
                    button.widthAnchor.constraint(equalToConstant: sideButtonSize),
                    button.heightAnchor.constraint(equalToConstant: sideButtonSize)
                ])
            }
            
            UIView.animate(withDuration: 0.5) {
                blurEffectView.effect = UIBlurEffect(style: .dark)
            }
        }
    }
    
    func deleteBlurView() {
        isAnimatingBlur = true
        if let blurEffectView = blurEffectView {
            UIView.animate(withDuration: 0.5, animations: {
                blurEffectView.effect = nil
                blurEffectView.alpha = 0
            }) { _ in
                blurEffectView.removeFromSuperview()
                self.blurEffectView = nil
                self.buttons.removeAll()
                self.isAnimatingBlur = false
                self.navigationController?.navigationBar.isHidden = false
            }
        } else {
            self.isAnimatingBlur = false
            self.navigationController?.navigationBar.isHidden = false
        }
    }
    
    //Unit type changer
    
    //table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let currentUnitBase = conversionAlgorithm.convertToBaseString(inputUnitType: unitTypeArray[unitTypeArrayID])
        let filteredConversionData = filterConversionData(byBaseUnit: currentUnitBase)
        print("\(filteredConversionData.count)")
        return filteredConversionData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentUnitBase = conversionAlgorithm.convertToBaseString(inputUnitType: unitTypeArray[unitTypeArrayID])
        print("Current Unit Base: \(currentUnitBase)")
        
        let filteredConversionData = filterConversionData(byBaseUnit: currentUnitBase)
        print("Filtered Data: \(filteredConversionData), IndexPath Row: \(indexPath.row)")  // Check if data is filtered correctly

        let cell = tableView.dequeueReusableCell(withIdentifier: "UnitCell") as! ViewTableViewCell
        
        let unit: ConversionData = filteredConversionData[indexPath.row]
        let image = unit.unitImage ?? UIImage(systemName: "nosign")!
        
        if let inputText = unitInput.text, let inputValue = Double(inputText), let unitTitle = unitButton.currentTitle {
            print("Input Text: \(inputText), Unit Title: \(unitTitle)")
            
            let baseUnitType = conversionAlgorithm.convertToBaseString(inputUnitType: unitTitle)
            print("unit.convertToKey: \(unit.convertToKey), baseUnitType: \(baseUnitType)")
            
            if conversionAlgorithm.convertToBaseString(inputUnitType: unit.convertToKey) == baseUnitType {
                if let conversionValue = conversionAlgorithm.convert(value: inputValue, fromUnit: unitTitle, toUnit: unit.convertToKey) {
                    let amount = unit.conversionRate * conversionValue
                    print("Conversion Value: \(conversionValue), Amount: \(amount)")
                    cell.setCell(unitLabel: unit.unitKey, unitValue: amount, unitImage: image)
                    print("Set cell with label: \(unit.unitKey), value: \(amount)")
                }
            } else {
                print("Conversion condition not met")
            }
        } else {
            print("Invalid input or unit title")
        }
        
        return cell
    }
    
    func filterConversionData(byBaseUnit baseUnit: String) -> [ConversionData] {
        let filteredData = conversionData.filter { $0.convertToKey == baseUnit }
        return filteredData
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.backgroundColor = .white
        cell.layer.masksToBounds = false
        cell.layer.shadowOffset = CGSize(width: 0, height: 1)
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowRadius = 4
        cell.layer.shadowOpacity = 0.1
        
        let padding: CGFloat = 10
        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(roundedRect: cell.bounds.insetBy(dx: padding, dy: padding), cornerRadius: 10).cgPath
        cell.layer.mask = maskLayer
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    //sending information to ResultViewController
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //segueVariable = indexPath.row
        
        let currentUnitBase = conversionAlgorithm.convertToBaseString(inputUnitType: unitTypeArray[unitTypeArrayID])
        let filteredConversionData = filterConversionData(byBaseUnit: currentUnitBase)
        let unit = filteredConversionData[indexPath.row]
        
        sendToResultVCName = unit.unitKey
        
        performSegue(withIdentifier: "toResult", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "toResult":
            let resultVC = segue.destination as! ResultViewController
            let inputDouble = Double(unitInput.text ?? "0")
            resultVC.inputFromVC = inputDouble ?? 0
            resultVC.uniqueUnitName = sendToResultVCName
        default:
            break
        }
    }
    
    //realm fetch functions
    func fetchConversionData() -> [ConversionData]{
        return Array(realm.objects(ConversionData.self))
    }
    
    //Activates when the user presses return on their keypad
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        tableView.reloadData()
        return true
    }
    

    
}
