//
//  LMPhotoExportAndImportService.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-09-01.
//

import UIKit
import Photos

class LMPhotoExportAndImportService {
    let albumName = "LensMemo"
    weak var appContext: LMAppContext?
    static let shared = LMPhotoExportAndImportService()
    
    var assetCollection: PHAssetCollection?
    
    func fetchAssetCollectionForAlbum() -> PHAssetCollection! {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        return collection.firstObject
    }
    
    private init() {
        if let assetCollection = fetchAssetCollectionForAlbum() {
            self.assetCollection = assetCollection
            return
        }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: self.albumName)
        }) { success, _ in
            if success {
                self.assetCollection = self.fetchAssetCollectionForAlbum()
            }
        }
    }
    
    static func checkPermission(completion: @escaping CallBack<Bool>) {
        if PHPhotoLibrary.authorizationStatus() == .notDetermined {
            PHPhotoLibrary.requestAuthorization { (state) in
                completion(state == .authorized)
            }
        } else {
            completion(PHPhotoLibrary.authorizationStatus() == .authorized)
        }
    }
    
    #if targetEnvironment(macCatalyst)
    func saveImage(images: [UIImage], completion: @escaping ([Error]) -> ()) {
        var errorList: [Error] = []
        let group = DispatchGroup()
        group.enter()
        let urls: [URL] = images.compactMap{ image in
            let uuid = UUID().uuidString
            guard let exportURL = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask)
                .first?.appendingPathComponent(uuid) else { return nil }
            group.enter()
            DispatchQueue.global().async {
                let data = image.jpegData(compressionQuality: 1.0)
                
                main {
                    do {
                        try data?.write(to: exportURL)
                    } catch (let error) {
                        errorList.append(error)
                    }
                    group.leave()
                }
            }
            return exportURL
        }
        
        group.leave()
        group.notify(queue: .main) {
            let controller = UIDocumentPickerViewController(urls: urls, in: .exportToService)
            self.appContext?.mainViewController.present(controller, animated: true) {
                urls.forEach { (url) in
                    do {
                        try FileManager.default.removeItem(at: url)
                    } catch (let error) {
                        errorList.append(error)
                    }
                }
                completion(errorList)
            }
        }
    }
    #else
    func saveImage(images: [UIImage], completion: @escaping ([Error]) -> ()) {
        guard let assetCollection = assetCollection else { return }
        
        PHPhotoLibrary.shared().performChanges({
            let assetChangeRequests = images.map { PHAssetChangeRequest.creationRequestForAsset(from: $0) }
            let assetPlaceholders = assetChangeRequests.map { $0.placeholderForCreatedAsset }
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: assetCollection)
            albumChangeRequest?.addAssets(assetPlaceholders as NSFastEnumeration)
        }, completionHandler: { flag, error in
            completion([])
        })
    }
    #endif
}
