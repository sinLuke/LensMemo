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
                LMDownloadService.shared.imageCache[originalFingerPrint] = image
                self.saveImageToFile(image: image, fingerPrint: originalFingerPrint) {
                    $0.see(ifSuccess: { (url) in
                        print("saveImage original uploadImageToCloud")
                        LMDownloadService.shared.scheduleUploadTask(fingerPrint: originalFingerPrint)
                        self.imageProcessingGroup.leave()
                    }) { (error) in
                        result(.failure(error))
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
                            result(.failure(error))
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
                            result(.failure(error))
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
    
    func createThumbnailImageData(image: UIImage, size: CGFloat = 300, fingerPrint: String) -> Data? {
        let ratio = image.size.width / image.size.height
        let imageSize = CGSize(width: ratio * size, height: size)
        
        UIGraphicsBeginImageContext(imageSize)
        image.draw(in: CGRect(origin: .zero, size: imageSize))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let thumbnailImage = thumbnail, let thumbnailData = thumbnailImage.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        
        LMDownloadService.shared.imageCache[fingerPrint] = thumbnailImage
        return thumbnailData
    }
    
    func getImage(for note: LMNote, quality: LMImage.Quality, onlyFromLocal: Bool = false, completion: @escaping ResultAsync<UIImage>) -> UIImage? {
        guard let noteID = note.id else {
            return nil
        }
        
        let fingerPrint = LMDownloadService.createImageFingerPrint(noteID: noteID.uuidString, quality: quality)
        if let image = LMDownloadService.shared.imageCache[fingerPrint] {
            return image
        }
        
        getLocalImageFile(fingerPrint: fingerPrint) { (result) in
            result.see(ifSuccess: { (image) in
                completion(.success(image))
            }) { (error) in
                completion(.failure(error))
                if !onlyFromLocal {
                    LMDownloadService.shared.scheduleTask(fingerPrint: fingerPrint)
                }
            }
        }
        
        return nil
    }
    
    func getLocalImageFile(fingerPrint: String, completion: @escaping ResultAsync<UIImage>) {
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
    
    func saveImageToFile(image: UIImage, fingerPrint: String, completeion: @escaping ResultAsync<URL>) {
        if let imageData = image.jpegData(compressionQuality: 0.8) {
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
    
    func cleanupCache() {
        LMDownloadService.shared.imageCache = [:]
    }
}
