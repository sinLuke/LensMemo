//
//  LMImageService.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-11.
//

import CoreData
import CoreImage
import CloudKit
import UIKit

class LMImageService {
    var viewContext: NSManagedObjectContext
    let imageSavingQueue = DispatchQueue(label: "imageSaving")
    let imageProcessingGroup = LMDispatchGroup()
    
    init(persistentService: LMPersistentStorageService) throws {
        self.viewContext = persistentService.viewContext
    }
    
    func saveImage(image: UIImage, note: LMNote, result: @escaping ResultAsync<Any?>) {
        DispatchQueue.global().async {
            do {
                guard let noteID = note.id else {
                    result(.failure(LMError.errorWhenSaveImage))
                    return
                }
                
                print("saveImage start")
                
                try self.imageProcessingGroup.wait()
                self.imageProcessingGroup.enter()
                
                print("saveImage original saveImageToFile")
                let originalFingerPrint = LMDownloadService.createImageFingerPrint(noteID: noteID.uuidString, quality: .original)
                
                main {
                    LMDownloadService.shared.imageCache[originalFingerPrint] = image
                }
                
                self.saveImageToFile(image: image, fingerPrint: originalFingerPrint) {
                    $0.see(ifSuccess: { (url) in
                        print("saveImage original uploadImageToCloud")
                        LMDownloadService.shared.scheduleUploadTask(fingerPrint: originalFingerPrint)
                        self.imageProcessingGroup.leave()
                    }) { (error) in
                        self.imageProcessingGroup.terminate(error: error)
                    }
                }
                
                try self.imageProcessingGroup.wait()
                self.imageProcessingGroup.enter()
                
                print("saveImage small createThumbnailImageData")
                let smallFingerPrint = LMDownloadService.createImageFingerPrint(noteID: noteID.uuidString, quality: .small)
                if let smallData = self.createThumbnailImageData(image: image, size: 256, fingerPrint: smallFingerPrint) {
                    print("saveImage small saveImageToFile")
                    self.saveImageToFile(data: smallData, fingerPrint: smallFingerPrint) {
                        $0.see(ifSuccess: { (url) in
                            print("saveImage small uploadImageToCloud")
                            LMDownloadService.shared.scheduleUploadTask(fingerPrint: smallFingerPrint)
                            self.imageProcessingGroup.leave()
                        }) { (error) in
                            self.imageProcessingGroup.terminate(error: error)
                        }
                    }
                }
                
                try self.imageProcessingGroup.wait()
                self.imageProcessingGroup.enter()
                
                print("saveImage large uploadImageToCloud")
                let largeFingerPrint = LMDownloadService.createImageFingerPrint(noteID: noteID.uuidString, quality: .large)
                if let largeData = self.createThumbnailImageData(image: image, size: 1024, fingerPrint: largeFingerPrint) {
                    print("saveImage large saveImageToFile")
                    self.saveImageToFile(data: largeData, fingerPrint: largeFingerPrint) {
                        $0.see(ifSuccess: { (url) in
                            print("saveImage large uploadImageToCloud")
                            LMDownloadService.shared.scheduleUploadTask(fingerPrint: largeFingerPrint)
                            self.imageProcessingGroup.leave()
                        }) { (error) in
                            self.imageProcessingGroup.terminate(error: error)
                        }
                    }
                }
                
                try self.imageProcessingGroup.wait()
                
                main {
                    print("saveImage result")
                    result(.success(nil))
                }
            } catch (let error) {
                main {
                    print("saveImage error \(error)")
                    result(.failure(error))
                }
            }
        }
    }
    
    enum Key: String {
        case hasLaunchedBefore
        case documentEnhancerEnable
        case documentEnhancerAmount
        case alertWhenDeleteNote
        case alertWhenDeleteNotebook
        case alertWhenDeleteSticker
        case uploadInMobileInternet
        case downloadInMobileInternet
        case jpegCompressionQuality
        case downloadQualityInMobileInternet
    }
    
    func getImage(for note: LMNote, quality: LMImage.Quality, onlyFromLocal: Bool = false, completion: @escaping ResultAsync<UIImage>) -> UIImage? {
        guard let noteID = note.id else {
            return nil
        }
        
        var usingQuality = quality
        
        var qualityLimit = LMUserDefaults.downloadQualityInMobileInternet
        if !LMDownloadService.isInternetExpensive {
            qualityLimit = 3
        }
        
        if qualityLimit == 2, quality == .original {
            usingQuality = .large
        }
        
        if qualityLimit == 1, quality == .original || quality == .large {
            usingQuality = .small
        }
        
        let downloadImage = {
            let fingerPrint = LMDownloadService.createImageFingerPrint(noteID: noteID.uuidString, quality: usingQuality)
            self.getLocalImageFile(fingerPrint: fingerPrint) { (result) in
                result.see(ifSuccess: { (image) in
                    completion(.success(image))
                }) { (error) in
                    completion(.failure(error))
                    if !onlyFromLocal {
                        LMDownloadService.shared.scheduleTask(fingerPrint: fingerPrint)
                    }
                }
            }
        }
        
        var fingerPrint = LMDownloadService.createImageFingerPrint(noteID: noteID.uuidString, quality: .original)
        if let image = LMDownloadService.shared.imageCache[fingerPrint] {
            return image
        }
        
        fingerPrint = LMDownloadService.createImageFingerPrint(noteID: noteID.uuidString, quality: .large)
        if let image = LMDownloadService.shared.imageCache[fingerPrint] {
            if usingQuality == .original {
                downloadImage()
            }
            return image
        }
        
        fingerPrint = LMDownloadService.createImageFingerPrint(noteID: noteID.uuidString, quality: .small)
        if let image = LMDownloadService.shared.imageCache[fingerPrint] {
            if usingQuality == .large || usingQuality == .original {
                downloadImage()
            }
            return image
        }
        
        downloadImage()
        return nil
    }
    
    private func createThumbnailImageData(image: UIImage, size: CGFloat = 300, fingerPrint: String) -> Data? {
        let ratio = image.size.width / image.size.height
        let imageSize = CGSize(width: ratio * size, height: size)
        
        UIGraphicsBeginImageContext(imageSize)
        image.draw(in: CGRect(origin: .zero, size: imageSize))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let thumbnailImage = thumbnail, let thumbnailData = thumbnailImage.jpegData(compressionQuality: CGFloat(LMUserDefaults.jpegCompressionQuality)) else {
            return nil
        }
        
        LMDownloadService.shared.imageCache[fingerPrint] = thumbnailImage
        return thumbnailData
    }
    
    private func getLocalImageFile(fingerPrint: String, completion: @escaping ResultAsync<UIImage>) {
        imageSavingQueue.async {
            do {
                let documentURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let imagePath = documentURL.appendingPathComponent(fingerPrint, isDirectory: false)
                if FileManager.default.fileExists(atPath: imagePath.path) {
                    let data = try Data(contentsOf: imagePath)
                    DispatchQueue.global().async {
                        if let image = UIImage(data: data) {
                            main {
                                LMDownloadService.shared.imageCache[fingerPrint] = image
                                completion(.success(image))
                            }
                        } else {
                            main {
                                completion(.failure(LMError.errorWhenLoadImage))
                            }
                        }
                    }
                } else {
                    main {
                        completion(.failure(LMError.errorWhenLoadImage))
                    }
                }
            } catch (let error) {
                main {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func saveImageToFile(image: UIImage, fingerPrint: String, completeion: @escaping ResultAsync<URL>) {
        if let imageData = image.jpegData(compressionQuality: CGFloat(LMUserDefaults.jpegCompressionQuality)) {
            self.saveImageToFile(data: imageData, fingerPrint: fingerPrint, completeion: completeion)
        } else {
            completeion(.failure(LMError.errorWhenSaveImage))
        }
    }
    
    func saveImageToFile(data: Data, fingerPrint: String, completeion: @escaping ResultAsync<URL>) {
        imageSavingQueue.async {
            if let documentURL = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
                do {
                    let imageItemURL = documentURL.appendingPathComponent(fingerPrint, isDirectory: false)
                    try data.write(to: imageItemURL)
                    completeion(.success(imageItemURL))
                } catch {
                    completeion(.failure(error))
                }
            }
        }
    }
    
    private func cleanupCache() {
        LMDownloadService.shared.imageCache = [:]
    }
}
