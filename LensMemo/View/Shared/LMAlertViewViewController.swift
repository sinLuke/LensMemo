//
//  LMAlertViewViewController.swift
//  LensMemo-iOS
//
//  Created by Luke Yin on 2020-07-01.
//

import UIKit

class LMAlertViewViewController: LMViewController {
    @IBOutlet weak var dismissTapView: UIView!
    @IBOutlet weak var alertView: UIView!
    @IBOutlet weak var alertViewYConstraint: NSLayoutConstraint!
    @IBOutlet weak var alertViewXConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var primaryButton: UIButton!
    @IBOutlet weak var secondaryButton: UIButton!
    @IBOutlet weak var topBar: UIVisualEffectView!
    @IBOutlet weak var bottomBar: UIVisualEffectView!
    
    var data: Data!
    var allowDismiss = true
    var cells: [Cell] = []
    var primaryButtonTappedCallBack: (() -> ())?
    var secondaryButtonTappedCallBack: (() -> ())?
    
    override var modalPresentationStyle: UIModalPresentationStyle {
        get { .overCurrentContext }
        set { }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 16)
        view.layer.shadowRadius = 24
        view.layer.shadowOpacity = 0.8
        
        alertView.layer.cornerRadius = 8
        alertView.clipsToBounds = true
        
        tableView.delegate = self
        tableView.dataSource = self
        
        primaryButton.layer.cornerRadius = 8
        primaryButton.clipsToBounds = true
        secondaryButton.layer.cornerRadius = 8
        secondaryButton.clipsToBounds = true
        
        tableView.register(UINib(nibName: String(describing: AlertTextTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: AlertTextTableViewCell.self))
        tableView.register(UINib(nibName: String(describing: AlertPickerTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: AlertPickerTableViewCell.self))
        tableView.register(UINib(nibName: String(describing: AlertTextFieldTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: AlertTextFieldTableViewCell.self))
        
        tableView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 44, right: 0)
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil) { (notification) in
            let targetFrame = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            if targetFrame.minY < self.alertView.frame.maxY {
                self.alertViewYConstraint.constant -= (self.alertView.frame.maxY - targetFrame.minY) + 16
                UIView.animate(withDuration: 0.3) {
                    self.view.layoutIfNeeded()
                }
            }
        }
        
        configure()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        tableViewHeight.constant = min(tableView.contentSize.height + 64 + 44 + 12, 0.75 * view.bounds.height)
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func setIcon(image: UIImage, color: UIColor) {
        iconView.image = image
        iconView.tintColor = color
    }
    
    @IBAction func primaryButtonTapped(_ sender: Any) {
        tableView.firstResponder?.resignFirstResponder()
        primaryButtonTappedCallBack?()
    }
    
    @IBAction func secondaryButtonTapped(_ sender: Any) {
        tableView.firstResponder?.resignFirstResponder()
        secondaryButtonTappedCallBack?()
    }
    
    @objc func dissmissView() {
        if allowDismiss {
            self.dismiss(animated: true, completion: nil)
        }
        tableView.firstResponder?.resignFirstResponder()
    }
    
    @objc func dissmissKeyboard() {
        tableView.firstResponder?.resignFirstResponder()
    }
    
    @objc func handlePanGuesture(_ sender: UIPanGestureRecognizer) {
        tableView.firstResponder?.resignFirstResponder()
        switch sender.state {
        case .changed:
            let translation = sender.translation(in: self.view)
            alertView.transform = CGAffineTransform(translationX: translation.x, y: translation.y)
        case .ended:
            alertViewXConstraint.constant += alertView.transform.tx
            alertViewYConstraint.constant += alertView.transform.ty
            alertView.transform = .identity
            view.layoutIfNeeded()
        default:
            return
        }
    }
    
    func configure() {
        self.allowDismiss = data.allowDismiss
        
        let topBarPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGuesture))
        topBar.addGestureRecognizer(topBarPanGestureRecognizer)
        
        let bottomBarPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGuesture))
        bottomBar.addGestureRecognizer(bottomBarPanGestureRecognizer)
        
        let dismissTapGesture = UITapGestureRecognizer(target: self, action: #selector(dissmissView))
        self.dismissTapView.addGestureRecognizer(dismissTapGesture)
        
        let dismissKeyboardTapGesture = UITapGestureRecognizer(target: self, action: #selector(dissmissKeyboard))
        self.alertView.addGestureRecognizer(dismissKeyboardTapGesture)
        
        if let icon = data.icon {
            self.iconView.image = icon
            self.iconView.tintColor = data.color ?? .label
        }
        
        self.titleLabel.text = data.title
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
        
        if let parimaryButtonData = data.primaryButton {
            if let secondaryButtonData = data.secondaryButton {
                self.secondaryButton.isHidden = false
                self.secondaryButton.setTitle(secondaryButtonData.title, for: .normal)
                self.secondaryButtonTappedCallBack = secondaryButtonData.onTap
            } else {
                self.secondaryButton.isHidden = true
            }
            
            self.primaryButton.isHidden = false
            self.primaryButton.setTitle(parimaryButtonData.title, for: .normal)
            self.primaryButtonTappedCallBack = parimaryButtonData.onTap
        } else {
            self.primaryButton.isHidden = true
        }
    }
    
    static func getInstance(data: Data) -> LMAlertViewViewController {
        let alert = LMAlertViewViewController(nibName: String(describing: LMAlertViewViewController.self), bundle: nil)
        alert.data = data
        return alert
    }
}

extension LMAlertViewViewController {
    struct Button {
        var title: String = "Dismiss"
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
        var primaryButton: Button? = nil
        var secondaryButton: Button? = nil
    }
}

extension LMAlertViewViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch cells[indexPath.row] {
            case let .text(string):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: AlertTextTableViewCell.self), for: indexPath)
                (cell as? AlertTextTableViewCell)?.configure(string: string)
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
        case text(string: String)
        case colorPicker(callBack: (String) -> ())
        case stickerPicker(callBack: ((String) -> ()))
        case textFiled(title: String, defaultValue: String?, onEditingEnd: (String) -> ())
    }
}
