//
//  LMAlertViewViewController.swift
//  LensMemo-iOS
//
//  Created by Luke Yin on 2020-07-01.
//

import UIKit

class LMAlertViewViewController: LMViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var buttonContainer: UIStackView!
    @IBOutlet weak var buttomContainerHeight: NSLayoutConstraint!
    
    var data: Data!
    var allowDismiss = true
    var cells: [Cell] = []
    var lastYConstraint: CGFloat = 0
    @IBOutlet weak var bottomGradientView: UIGradientView!
    
    var inputsValid: [String: Bool] = [:] {
        didSet {
            validInputs()
        }
    }
    var preferedTableViewHeight: CGFloat {
        return min(self.tableView.contentSize.height + 12 + 24, 0.8 * (self.view.bounds.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        #if targetEnvironment(macCatalyst)
        buttomContainerHeight.constant = 44
        
        #else
        buttomContainerHeight.constant = 66
        view.backgroundColor = .secondarySystemBackground
        #endif
        
        view.clipsToBounds = true
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
        tableView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        tableView.register(UINib(nibName: String(describing: AlertTextTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: AlertTextTableViewCell.self))
        tableView.register(UINib(nibName: String(describing: AlertPickerTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: AlertPickerTableViewCell.self))
        tableView.register(UINib(nibName: String(describing: AlertTextFieldTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: AlertTextFieldTableViewCell.self))
        tableView.register(UINib(nibName: String(describing: AlertHeaderTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: AlertHeaderTableViewCell.self))
        
//        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil) { (notification) in
//            let targetFrame = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
//            if targetFrame.minY < self.alertView.frame.maxY {
//                self.lastYConstraint = self.alertViewYConstraint.constant
//                var offset = (self.alertView.frame.maxY - targetFrame.minY) + 16
//                self.alertViewYConstraint.constant -= offset
//
//                if self.alertView.frame.minY - offset < self.view.safeAreaInsets.top {
//                    offset = (self.view.safeAreaInsets.top - self.alertView.frame.minY + offset) / 2
//                    self.tableViewHeight.constant -= offset * 2
//                    self.alertViewYConstraint.constant += offset
//                }
//
//                UIView.animate(withDuration: 0.3, animations: {
//                    self.view.layoutIfNeeded()
//                })
//            }
//        }
//
//        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil) { (notification) in
//            self.alertViewYConstraint.constant = self.lastYConstraint
//            let maximumHeight = (self.view.bounds.height / 2) - (self.alertView.frame.height / 2) - (self.view.safeAreaInsets.top + self.view.safeAreaInsets.bottom)
//            self.alertViewYConstraint.constant = min(maximumHeight, max(-maximumHeight, self.alertViewYConstraint.constant))
//            self.tableViewHeight.constant = self.preferedTableViewHeight
//            UIView.animate(withDuration: 0.3) {
//                self.view.layoutIfNeeded()
//            }
//        }
        
        configure()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        self.view.layoutIfNeeded()
    }
    
    @objc func dissmissView() {
        if allowDismiss {
            dismiss(animated: true, completion: nil)
        }
        tableView.firstResponder?.resignFirstResponder()
    }
    
    @objc func dissmissKeyboard() {
        tableView.firstResponder?.resignFirstResponder()
    }
    
    func configure() {
        self.allowDismiss = data.allowDismiss
        
        self.cells.append(.header(title: data.title ?? "Untitle", icon: data.icon, color: data.color ?? .label))
        
        for message in data.messages {
            self.cells.append(.text(string: message))
        }
        
        for textField in data.textFields {
            self.cells.append(.textFiled(title: textField.title, defaultValue: textField.defaultValue, onEditingEnd: textField.onEditingEnd))
        }
        
        if let colorPicker = data.colorPicker {
            self.cells.append(.colorPicker(callBack: colorPicker))
        }
        
        if let stickerPicker = data.stickerPicker {
            self.cells.append(.stickerPicker(callBack: stickerPicker))
        }
        
        
        for buttonData in data.buttons {
            let button = LMButtonView(frame: .zero)
            button.text = buttonData.title
            button.needsValidate = buttonData.validateInput
            button.isValidated = !buttonData.validateInput
            button.onTap = { [weak self] in
                guard let self = self else { return }
                self.tableView.resignFirstResponder()
                self.validInputs()
                if button.isValidated {
                    buttonData.onTap()
                }
            }
            buttonContainer.addArrangedSubview(button)
        }
    }
    
    func validInputs() {
        var isValid = true
        inputsValid.values.forEach { (flag) in
            isValid = isValid && flag
        }
        for buttonView in buttonContainer.arrangedSubviews {
            if let button = buttonView as? LMButtonView {
                button.isValidated = !button.needsValidate || isValid
            }
        }
        var newCells: [Cell] = []
        for cell in cells {
            switch cell {
            case .error(_):
                break
            default:
                newCells.append(cell)
            }
        }
        
        for errorKey in inputsValid.keys {
            if inputsValid[errorKey] == false {
                newCells.append(.error(string: errorKey))
            }
        }
        
        self.cells = newCells
        tableView.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        })
    }
    
    static func getInstance(data: Data) -> LMAlertViewViewController {
        let alert = LMAlertViewViewController(nibName: String(describing: LMAlertViewViewController.self), bundle: nil)
        alert.data = data
        return alert
    }
    
    static func getInstance(error: Error) -> LMAlertViewViewController {
        let alert = LMAlertViewViewController(nibName: String(describing: LMAlertViewViewController.self), bundle: nil)
        var messages: [String] = [error.localizedDescription]
        let nsError = error as NSError
        messages.append("Error Code: \(nsError.code)")
        messages.append(nsError.domain)
        if let localizedRecoverySuggestion = nsError.localizedRecoverySuggestion {
            messages.append("Recovery Suggestion: \(localizedRecoverySuggestion)")
        }
        if nsError.localizedRecoveryOptions?.count ?? 0 > 0 {
            messages.append("Recovery Options:")
            messages.append(contentsOf: nsError.localizedRecoveryOptions ?? [])
        }
        
        messages.append("Debug description: \(nsError.debugDescription)")
        
        let data = Data(allowDismiss: true, icon: UIImage(systemName: "xmark.octagon"), color: .systemRed, title: "Error", messages: messages, colorPicker: nil, stickerPicker: nil, textFields: [], buttons: [Button(title: "OK", onTap: {
            alert.dismiss(animated: true, completion: nil)
        })])
        alert.data = data
        return alert
    }
}

extension LMAlertViewViewController {
    struct Button {
        var title: String = "Dismiss"
        var validateInput = false
        var onTap: () -> ()
    }

    struct TextField {
        var title: String = "Dismiss"
        var defaultValue: String?
        var onEditingEnd: (String) -> ()
    }

    struct Data {
        var allowDismiss: Bool = true
        var icon: UIImage? = nil
        var color: UIColor? = nil
        var title: String? = nil
        var messages: [String] = []
        var colorPicker: ((String) -> ())? = nil
        var stickerPicker: ((String) -> ())? = nil
        var textFields: [TextField] = []
        var buttons: [Button] = []
    }
}

extension LMAlertViewViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch cells[indexPath.row] {
            case let .header(title, icon, color):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: AlertHeaderTableViewCell.self), for: indexPath)
                (cell as? AlertHeaderTableViewCell)?.configure(title: title, icon: icon, color: color)
                return cell
            case let .text(string):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: AlertTextTableViewCell.self), for: indexPath)
                (cell as? AlertTextTableViewCell)?.configure(string: string)
                return cell
            case let .error(string):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: AlertTextTableViewCell.self), for: indexPath)
                (cell as? AlertTextTableViewCell)?.configure(string: string, isError: true)
                return cell
            case let .colorPicker(callBack):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: AlertPickerTableViewCell.self), for: indexPath)
                (cell as? AlertPickerTableViewCell)?.configure(callBack: callBack)
                return cell
            case let .stickerPicker(callBack):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: AlertPickerTableViewCell.self), for: indexPath)
                (cell as? AlertPickerTableViewCell)?.configure(callBack: callBack)
                return cell
            case let .textFiled(title, defaultValue, onEditingEnd):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: AlertTextFieldTableViewCell.self), for: indexPath)
                (cell as? AlertTextFieldTableViewCell)?.configure(title: title, defaultValue: defaultValue, onEditingEndCallBack: onEditingEnd)
                return cell
        }
    }
    
    enum Cell {
        case header(title: String, icon: UIImage?, color: UIColor)
        case text(string: String)
        case error(string: String)
        case colorPicker(callBack: (String) -> ())
        case stickerPicker(callBack: ((String) -> ()))
        case textFiled(title: String, defaultValue: String?, onEditingEnd: (String) -> ())
    }
    
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        #if targetEnvironment(macCatalyst)
        bottomGradientView.colors = [UIColor(named: "panelGradientStart"), UIColor(named: "panelGradientEnd")].compactMap { $0 }
        #else
        bottomGradientView.isHidden = true
        #endif
    }
}
