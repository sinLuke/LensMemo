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
                let originalFingerPrint = LMInternetService.createImageFingerPrint(noteID: noteID.uuidString, quality: .original)
                
                main {
                    LMInternetService.shared.imageCache[originalFingerPrint] = image
                }
                
                if let imageData = image.jpegData(compressionQuality: CGFloat(LMUserDefaults.jpegCompressionQuality)) {
                    self.saveImageAndUpload(imageData: imageData, fingerPrint: originalFingerPrint)
                } else {
                    self.imageProcessingGroup.terminate(error: LMError.errorWhenSaveImage)
                }
                
                try self.imageProcessingGroup.wait()
                self.imageProcessingGroup.enter()
                
                print("saveImage small createThumbnailImageData")
                let smallFingerPrint = LMInternetService.createImageFingerPrint(noteID: noteID.uuidString, quality: .small)
                if let smallData = self.createThumbnailImageData(image: image, size: 256, fingerPrint: smallFingerPrint) {
                    self.saveImageAndUpload(imageData: smallData, fingerPrint: smallFingerPrint)
                } else {
                    self.imageProcessingGroup.terminate(error: LMError.errorWhenSaveImage)
                }
                
                try self.imageProcessingGroup.wait()
                self.imageProcessingGroup.enter()
                
                print("saveImage large uploadImageToCloud")
                let largeFingerPrint = LMInternetService.createImageFingerPrint(noteID: noteID.uuidString, quality: .large)
                if let largeData = self.createThumbnailImageData(image: image, size: 1024, fingerPrint: largeFingerPrint) {
                    self.saveImageAndUpload(imageData: largeData, fingerPrint: smallFingerPrint)
                } else {
                    self.imageProcessingGroup.terminate(error: LMError.errorWhenSaveImage)
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

    func getImageFromMemory(for noteID: UUID, quality: LMImage.Quality?) -> UIImage? {
        
        if let quality = quality {
            let fingerPrint = LMInternetService.createImageFingerPrint(noteID: noteID.uuidString, quality: quality)
            return LMInternetService.shared.imageCache[fingerPrint]
        }
        
        for compromisedQuality: LMImage.Quality in [.original, .large, .small] {
            let fingerPrint = LMInternetService.createImageFingerPrint(noteID: noteID.uuidString, quality: compromisedQuality)
            if let image = LMInternetService.shared.imageCache[fingerPrint] {
                return image
            }
        }
        
        return nil
    }
    
    func getImageFromDisk(for noteID: UUID, quality: LMImage.Quality?) -> UIImage? {
        if let quality = quality {
            let fingerPrint = LMInternetService.createImageFingerPrint(noteID: noteID.uuidString, quality: quality)
            return try? self.getLocalImageFile(fingerPrint: fingerPrint)
        }
        
        for compromisedQuality: LMImage.Quality in [.original, .large, .small] {
            let fingerPrint = LMInternetService.createImageFingerPrint(noteID: noteID.uuidString, quality: compromisedQuality)
            if let image = try? self.getLocalImageFile(fingerPrint: fingerPrint) {
                return image
            }
        }
        
        return nil
    }
    
    func getImageFromCloud(for noteID: UUID, quality: LMImage.Quality, completion: @escaping ResultAsync<UIImage?>) {
        var compromisedQuality = quality
        var qualityLimit = LMUserDefaults.downloadQualityInMobileInternet
        if !LMInternetService.isInternetExpensive {
            qualityLimit = 3
        }
        
        if qualityLimit == 2, quality == .original {
            compromisedQuality = .large
        }
        
        if qualityLimit == 1, quality == .original || quality == .large {
            compromisedQuality = .small
        }
        
        let fingerPrint = LMInternetService.createImageFingerPrint(noteID: noteID.uuidString, quality: compromisedQuality)
        LMInternetService.shared.scheduleTask([LMInternetService.Task(fingerPrint: fingerPrint, isDownloading: true, callBack: completion)])
    }
    
    func getImages(for noteIDs: [UUID], completion: @escaping CallBack<[Result<UIImage, Error>]>) -> Progress {
        let progress = Progress(totalUnitCount: Int64(noteIDs.count))
        
        let imageExportingGroup = DispatchGroup()
        
        imageSavingQueue.async {
            var resultArray: [Result<UIImage, Error>] = []
            noteIDs.forEach { noteID in
                guard let imageFromMemory = self.getImageFromMemory(for: noteID, quality: .original) else {
                    guard let imageFromDisk = self.getImageFromDisk(for: noteID, quality: .original) else {
                        imageExportingGroup.wait()
                        imageExportingGroup.enter()
                        self.getImageFromCloud(for: noteID, quality: .original) { (result) in
                            result.see { (image) in
                                if let imageFromCloud = image {
                                    resultArray.append(.success(imageFromCloud))
                                    progress.completedUnitCount = Int64(resultArray.count)
                                } else {
                                    resultArray.append(.failure(NSError()))
                                    progress.completedUnitCount = Int64(resultArray.count)
                                }
                            } ifNot: { (error) in
                                resultArray.append(.failure(error))
                                progress.completedUnitCount = Int64(resultArray.count)
                            }
                            imageExportingGroup.leave()
                        }
                        return
                    }
                    resultArray.append(.success(imageFromDisk))
                    progress.completedUnitCount = Int64(resultArray.count)
                    return
                }
                resultArray.append(.success(imageFromMemory))
                progress.completedUnitCount = Int64(resultArray.count)
                return
            }
            completion(resultArray)
        }
        
        return progress
    }
    
    private func saveImageAndUpload(imageData: Data, fingerPrint: String) {
        self.saveImageToFile(data: imageData, fingerPrint: fingerPrint) {
            $0.see(ifSuccess: { (url) in
                LMInternetService.shared.scheduleTask([.init(fingerPrint: fingerPrint, isDownloading: false, callBack: { (result) in
                    self.imageProcessingGroup.leave()
                })])
                
            }) { (error) in
                self.imageProcessingGroup.terminate(error: error)
            }
        }
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
        
        LMInternetService.shared.imageCache[fingerPrint] = thumbnailImage
        return thumbnailData
    }
    
    private func getLocalImageFile(fingerPrint: String) throws -> UIImage {
        let documentURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let imagePath = documentURL.appendingPathComponent(fingerPrint, isDirectory: false)
        if FileManager.default.fileExists(atPath: imagePath.path) {
            let data = try Data(contentsOf: imagePath)
            if let image = UIImage(data: data) {
                return image
            } else {
                throw LMError.errorWhenReadingImageData
            }
        } else {
            throw LMError.errorLocalImageFileNotExist
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
        LMInternetService.shared.imageCache = [:]
    }
}
