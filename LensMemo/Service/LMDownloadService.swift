//
//  LMDownloadService.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-18.
//

import UIKit
import CloudKit
import UIKit

class LMDownloadService {
    static let shared = LMDownloadService()
    weak var appContext: LMAppContext?
    
    //download
    var requestingTasks: Set<String> = []
    var downloadingTasks: Set<String> = []
    var failedTasks: Set<String> = []
    
    //upload
    var requestingUploadTasks: Set<String> = []
    var toBeUploadTasks: Set<String> = [] {
        didSet {
            self.saveToBeUploadTasksToFile()
        }
    }
    
    let networkErrorCodes: [CKError.Code] = [
        .networkFailure,
        .networkUnavailable
    ]
    
    var timer: Timer? = nil
    var imageCache: [String: UIImage] = [:]
    
    private init() {}
    
    func startTimer() {
        loadToBeUploadTasksFromFile()
        timer = Timer(timeInterval: 1.5, repeats: true, block: { [weak self] _ in
            self?.timerBlock()
        })
        timer!.tolerance = 0.5
        main {
            RunLoop.current.add(self.timer!, forMode: .default)
        }
    }
    
    func timerBlock() {
        main {
            print("timerBlock request: \(self.requestingTasks.count), downloading: \(self.downloadingTasks.count), failed: \(self.failedTasks.count)")
            print("timerBlock requestingUploadTasks: \(self.requestingUploadTasks.count), toBeUploadTasks: \(self.toBeUploadTasks.count), failed: \(self.failedTasks.count)")
            self.requestingTasks.subtract(self.failedTasks)
            if !self.requestingTasks.isEmpty {
                self.downloadImages()
            }
            
            if !self.requestingUploadTasks.isEmpty || !self.toBeUploadTasks.isEmpty {
                self.uploadImages()
            }
        }
    }
    
    func scheduleTask(fingerPrint: String) {
        main {
            print("scheduleTask")
            if !self.requestingTasks.contains(fingerPrint), !self.downloadingTasks.contains(fingerPrint), !self.failedTasks.contains(fingerPrint) {
                self.requestingTasks.insert(fingerPrint)
            }
        }
    }
    
    func scheduleUploadTask(fingerPrint: String) {
        main {
            self.toBeUploadTasks.insert(fingerPrint)
        }
    }
    
    func uploadImages() {
        main {
            guard let documentURL = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else { return }
            var onGoingTasks = self.requestingUploadTasks
            onGoingTasks.formUnion(self.toBeUploadTasks)
            onGoingTasks = Set(Array(onGoingTasks).prefix(8))
            self.requestingUploadTasks.subtract(onGoingTasks)
            self.toBeUploadTasks.subtract(onGoingTasks)
            let records: [CKRecord] = Array(onGoingTasks).compactMap { task in
                let imagePath = documentURL.appendingPathComponent(task, isDirectory: false)
                guard FileManager.default.fileExists(atPath: imagePath.path) else { return nil }
                let newRecord:CKRecord = CKRecord(recordType: LMImage.Keys.Images.rawValue)
                let asset: CKAsset?  = CKAsset(fileURL: imagePath)
                newRecord.setValue(task, forKey: LMImage.Keys.fingerPrint.rawValue)
                newRecord.setValue(asset, forKey: LMImage.Keys.data.rawValue)
                return newRecord
            }

            let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
            operation.modifyRecordsCompletionBlock = {_, _, error in
                if error != nil {
                    self.toBeUploadTasks.formUnion(onGoingTasks)
                }
            }
            CKContainer.default().privateCloudDatabase.add(operation)
        }
    }
    
    func downloadImages() {
        main {
            print("downloadImage")
            
            var onGoingTasks = self.requestingTasks
            onGoingTasks = Set(Array(onGoingTasks).prefix(8))
            let predicate = NSPredicate(format:"fingerPrint IN %@", Array(onGoingTasks))
            let query = CKQuery(recordType: LMImage.Keys.Images.rawValue, predicate: predicate)
            self.downloadingTasks.formUnion(onGoingTasks)
            
            
            self.requestingTasks.subtract(onGoingTasks)
            
            CKContainer.default().privateCloudDatabase.perform(query, inZoneWith: CKRecordZone.default().zoneID) { (records, error) in
                main {
                    
                    if let error = error {
                        self.downloadingTasks.removeAll()
                        print("downloadFinished error: \(error.localizedDescription)")
                    } else if let records = records {
                        let resultTasks = Set(records.compactMap { $0.object(forKey: LMImage.Keys.fingerPrint.rawValue) as? String })
                        self.failedTasks.formUnion(onGoingTasks.subtracting(resultTasks))
                        self.downloadingTasks.subtract(onGoingTasks)
                        
                        print("downloadFinished downloadFinished")
                        records.forEach { record in
                            if
                                let imageAsset = record.object(forKey: LMImage.Keys.data.rawValue) as? CKAsset,
                                let imageFileURL = imageAsset.fileURL,
                                let imageData = try? Data(contentsOf: imageFileURL),
                                let fingerPrint = record.object(forKey: LMImage.Keys.fingerPrint.rawValue) as? String {
                                self.appContext?.imageService.saveImageToFile(data: imageData, fingerPrint: fingerPrint, completeion: { _ in })
                                if let image = UIImage(data: imageData) {
                                    self.imageCache[fingerPrint] = image
                                }
                            }
                        }
                        NotificationCenter.default.post(Notification(name: .downloadFinished))
                    }
                }
            }
        }
    }
    
    func saveToBeUploadTasksToFile() {
        guard var uploadingListPath = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else { return }
        uploadingListPath.appendPathComponent("uploadingTasks.plist")
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        print("save to file \(toBeUploadTasks)")
        guard let data = try? encoder.encode(toBeUploadTasks) else { return }
        try? data.write(to: uploadingListPath)
    }
    
    func loadToBeUploadTasksFromFile() {
        guard var uploadingListPath = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else { return }
        uploadingListPath.appendPathComponent("uploadingTasks.plist")
        guard let data = try? Data(contentsOf: uploadingListPath) else { return }
        let decoder = PropertyListDecoder()
        guard let tasksFromFile = try? decoder.decode(Set<String>.self, from: data) else { return }
        print("read from file \(tasksFromFile)")
        toBeUploadTasks.formUnion(tasksFromFile)
    }
    
    static func createImageFingerPrint(noteID: String, quality: LMImage.Quality) -> String {
        return "\(noteID)\(quality.rawValue)"
    }
}
