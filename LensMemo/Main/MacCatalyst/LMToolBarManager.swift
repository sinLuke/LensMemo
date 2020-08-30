//
//  LMToolBarManager.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-26.
//

#if targetEnvironment(macCatalyst)
import AppKit
import UIKit

class LMToolBarManager: NSObject {
    let appContext: LMAppContext
    let toolBar = NSToolbar(identifier: "LMToolBar")
    static var shared: LMToolBarManager!
    init(appContext: LMAppContext) {
        self.appContext = appContext
        super.init()
        toolBar.delegate = self
        toolBar.displayMode = .iconOnly
    }
}

extension LMToolBarManager: NSToolbarDelegate {
    
    func noteListBarItem() -> NSToolbarItem {
        let barButtonItem = UIBarButtonItem()
        let item = NSToolbarItem(itemIdentifier: .noteListControl, barButtonItem: barButtonItem)
        item.image = UIImage(systemName: "sidebar.left")
        item.isBordered = true
        return item
    }
    
    func propertyInspectorBarItem() -> NSToolbarItem {
        let barButtonItem = UIBarButtonItem()
        let item = NSToolbarItem(itemIdentifier: .propertyInspectorControl, barButtonItem: barButtonItem)
        item.image = UIImage(systemName: "info.circle")
        item.isBordered = true
        return item
    }
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier {
        case .addButton:
            let addBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: nil)
            return NSToolbarItem(itemIdentifier: .addButton, barButtonItem: addBarButtonItem)
        case .controlGroup:
            let controlGroup = NSToolbarItemGroup(itemIdentifier: .controlGroup, images: [UIImage(systemName: "sidebar.left"), UIImage(systemName: "info.circle")].compactMap{ $0 }, selectionMode: .selectAny, labels: ["Side bar", "Property Inspector"], target: self, action: #selector(controlGroupAction))
            controlGroup.selectionMode = .momentary
            return controlGroup
        default:
            return nil
        }
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.addButton, .flexibleSpace, .controlGroup]
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.addButton, .flexibleSpace, .controlGroup]
    }
    
    @objc func controlGroupAction(_ sender: NSToolbarItemGroup) {
        switch sender.selectedIndex {
        case 0:
            self.appContext.mainDetailViewController.isNoteListVisible.toggle()
        case 1:
            self.appContext.mainDetailViewController.isPropertyInspectorVisible.toggle()
        default:
            return
        }
    }
    
    @objc func addButtonTapped(_ sender: NSToolbarItem) {
        self.appContext.mainDetailViewController.isPropertyInspectorVisible = !self.appContext.mainDetailViewController.isPropertyInspectorVisible
    }
}

extension NSToolbarItem.Identifier {
    static let controlGroup: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "controlGroup")
    static let noteListControl: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "noteListControl")
    static let propertyInspectorControl: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "propertyInspectorControl")
    static let addButton: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "addButton")
}
#endif
