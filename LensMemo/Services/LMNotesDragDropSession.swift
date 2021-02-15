//
//  LMNotesDragDropSession.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-08-29.
//

import UIKit

class LMNotesDragDropSession {
    let dragItem: [UIDragItem]
    var notebook: LMNotebook
    weak var appContext: LMAppContext?
    
    var resultList: [LMNote] = []
    var errorList: [Error] = []
    var loadingGroup = DispatchGroup()
    
    init(dragItem: [UIDragItem], notebook: LMNotebook, appContext: LMAppContext) {
        self.dragItem = dragItem
        self.appContext = appContext
        self.notebook = notebook
    }
    
    func createNotes() {
        
        loadingGroup.enter()
        dragItem.forEach { (item) in
            guard let type = item.itemProvider.registeredTypeIdentifiers.first else {
                errorList.append(NSError(domain: "Unknown file format", code: 0, userInfo: nil))
                showResultOrError()
                return
            }
            loadingGroup.enter()
            item.itemProvider.loadDataRepresentation(forTypeIdentifier: type) { (data, error) in
                if let data = data {
                    self.loadNoteFromData(data: data)
                } else if let error = error {
                    self.errorList.append(error)
                    self.showResultOrError()
                }
            }
        }
        loadingGroup.leave()
        loadingGroup.notify(queue: .main) {
            self.showResultOrError()
        }
    }
    
    func showResultOrError() {
        if (resultList.isEmpty && errorList.isEmpty) {
            return
        }
        var alertTitle: String
        var alertIcon: String
        var alertColor: UIColor
        var alertMessage: [String]
        
        if resultList.isEmpty {
            alertTitle = "Import Faild"
            alertIcon = "xmark.octagon.fill"
            alertColor = .red
            alertMessage = errorList.map { "error: \($0.localizedDescription)" }
        } else if errorList.isEmpty {
            alertTitle = "Import Finished"
            alertIcon = "checkmark.circle.fill"
            alertColor = .systemGreen
            alertMessage = resultList.count == 1 ? [] : ["Imported \(resultList.count) images"]
        } else {
            alertTitle = "Import finish with \(errorList.count) Error"
            alertIcon = "exclamationmark.triangle.fill"
            alertColor = .systemYellow
            alertMessage = errorList.map { "error: \($0.localizedDescription)" }
        }
        
        var alert: UIViewController?
        if alertMessage.count > 1 {
            alert = LMAlertViewViewController.getInstance(data: LMAlertViewViewController.Data(allowDismiss: true, icon: UIImage(systemName: alertIcon), color: alertColor, title: alertTitle, messages: alertMessage, buttons: [LMAlertViewViewController.Button(title: "OK", validateInput: false, onTap: { [weak alert] in
                alert?.dismiss(animated: true, completion: nil)
            })]))
        } else if !alertMessage.isEmpty {
            alert = UIAlertController(title: alertTitle, message: alertMessage.first, preferredStyle: .alert)
            (alert as? UIAlertController)?.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] _ in
                alert?.dismiss(animated: true, completion: nil)
            }))
        }
        
        main {
            if let alert = alert {
                self.appContext?.mainViewController.present(alert, animated: true, completion: nil)
            }
        }
        
        try? appContext?.storage.saveContext()
        
        #if targetEnvironment(macCatalyst)
        let mainViewMenuNoteListViewController = self.appContext?.mainViewMenuNoteListViewController
        #else
        let mainViewMenuNoteListViewController = self.appContext?.mainViewMenuViewNavigationController.topViewController as? LMNoteListViewController
        #endif
        mainViewMenuNoteListViewController?.update()
    }
    
    func loadNoteFromData(data: Data) {
        main {
            guard let image = UIImage(data: data) else {
                self.errorList.append(NSError(domain: "Error when decoding image", code: 0, userInfo: nil))
                self.loadingGroup.leave()
                return
            }
            self.appContext?.noteService.addNote(name: "", to: self.notebook, message: "", image: image, stickers: [], result: { (result) in
                result.see(ifSuccess: { (note) in
                    DispatchQueue.main.async {
                        self.resultList.append(note)
                        self.loadingGroup.leave()
                    }
                }) { (error) in
                    DispatchQueue.main.async {
                        self.errorList.append(error)
                        self.loadingGroup.leave()
                    }
                }
            })
        }
    }
}
