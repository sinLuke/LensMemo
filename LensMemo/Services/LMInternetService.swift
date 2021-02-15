//
//  LMInternetService.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-18.
//

import UIKit
import CloudKit
import Network
import UIKit

class LMInternetService {
    static let shared = LMInternetService()
    let monitor = NWPathMonitor()
    static var isInternetExpensive = true
    static var isWorking = false
    static var isRestricted = false
    weak var appContext: LMAppContext?
    
    var tasks: [Task] = []
    var failedFingerPrints: [String: Error] = [:]
    
    var toBeUploadTasks: [Task] = [] {
        didSet {
            self.saveToBeUploadTasksToFile()
        }
    }
    
    var timer: Timer?
    var imageCache: [String: UIImage] = [:]
    
    private init() {
        monitor.pathUpdateHandler = { path in
            main {
                LMInternetService.isInternetExpensive = path.isExpensive
                LMInternetService.isRestricted = path.isExpensive && (!LMUserDefaults.downloadInMobileInternet && !LMUserDefaults.uploadInMobileInternet)
                LMInternetService.isWorking = path.status == .satisfied
                
                if (LMInternetService.isRestricted || !LMInternetService.isWorking) {
                    if self.timer?.isValid == true {
                        self.timer?.invalidate()
                    }
                } else {
                    if self.timer?.isValid == false {
                        self.startTimer()
                    }
                }
                
                self.appContext?.mainViewController.isInternetWorking = LMInternetService.isWorking
                #if !targetEnvironment(macCatalyst)
                self.appContext?.cameraViewController.isInternetWorking = LMInternetService.isWorking
                #endif
            }
        }
        
        let queue = DispatchQueue(label: "Monitor")
        monitor.start(queue: queue)
    }
    
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
        DispatchQueue.global().async { [self] in
            print("DL### self.tasks \(self.tasks.count)")
            print("DL### failedFingerPrints \(self.failedFingerPrints.count)")
            
            if self.failedFingerPrints.count == 23 {
                print("aaa")
            }
            
            let requestingDownloadTasks = self.tasks.filter { (task) -> Bool in
                task.status == .requesting && task.isDownloading
            }
            
            let requestingUploadTasks = self.tasks.filter { (task) -> Bool in
                task.status == .requesting && !task.isDownloading
            }
            
            main {
                self.tasks.forEach { (task) in
                    switch task.status {
                    case let .failed(error):
                        failedFingerPrints[task.fingerPrint] = error
                        task.callBack?(.failure(error ?? LMError.defaultError))
                    default:
                        if failedFingerPrints.keys.contains(task.fingerPrint) {
                            task.callBack?(.failure(failedFingerPrints[task.fingerPrint] ?? LMError.defaultError))
                        }
                    }
                }
                
                self.tasks.removeAll(where: { $0.status == .failed(error: nil) })
                self.tasks.removeAll(where: { failedFingerPrints.keys.contains($0.fingerPrint) })
                
                print("DL### main 1")
                if !requestingDownloadTasks.isEmpty, !(!LMUserDefaults.downloadInMobileInternet && LMInternetService.isInternetExpensive) {
                    self.downloadImages()
                }
                
                print("DL### main 2")
                if requestingDownloadTasks.isEmpty {
                    self.tasks.removeAll(where: { $0.status == .finished && $0.isDownloading })
                }
                
                print("DL### main 3")
                if !requestingUploadTasks.isEmpty, !(!LMUserDefaults.downloadInMobileInternet && LMInternetService.isInternetExpensive) {
                    self.uploadImages()
                }
                
                print("DL### main 4")
                if requestingUploadTasks.isEmpty {
                    self.tasks.removeAll(where: { $0.status == .finished && !$0.isDownloading })
                }
            }
        }
    }
    
    func scheduleTask(_ tasks: [Task]) {
        DispatchQueue.global().async {
            let requestingTasks = tasks.filter { (task) -> Bool in
                let flag = !self.failedFingerPrints.keys.contains(task.fingerPrint)
                if !flag {
                    task.callBack?(.failure(self.failedFingerPrints[task.fingerPrint] ?? LMError.defaultError))
                }
                return flag
            }
            
            main {
                self.tasks.append(contentsOf: requestingTasks)
            }
        }
    }
    
    func uploadImages() {
        main {
            guard let documentURL = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else { return }
            
            var onGoingTasks = self.tasks.filter { (task) -> Bool in
                !task.isDownloading && task.status == .requesting
            } .sorted { (lhs, rhs) -> Bool in
                lhs.created > rhs.created
            }
            
            onGoingTasks = Array(onGoingTasks.prefix(8))
            onGoingTasks.forEach { $0.status = .ongoing }
            
            let records: [CKRecord] = onGoingTasks.compactMap { task in
                let imagePath = documentURL.appendingPathComponent(task.fingerPrint, isDirectory: false)
                guard FileManager.default.fileExists(atPath: imagePath.path) else { return nil }
                let newRecord:CKRecord = CKRecord(recordType: LMImage.Keys.Images.rawValue)
                let asset: CKAsset?  = CKAsset(fileURL: imagePath)
                newRecord.setValue(task.fingerPrint, forKey: LMImage.Keys.fingerPrint.rawValue)
                newRecord.setValue(asset, forKey: LMImage.Keys.data.rawValue)
                return newRecord
            }

            let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
            operation.modifyRecordsCompletionBlock = {_, _, error in
                if let error = error {
                    onGoingTasks.forEach {
                        $0.status = .failed(error: error)
                        $0.callBack?(.failure(error))
                    }
                } else {
                    onGoingTasks.forEach {
                        $0.status = .finished
                        $0.callBack?(.success(nil))
                    }
                }
            }
            CKContainer.default().privateCloudDatabase.add(operation)
        }
    }
    
    func downloadImages() {
        main {
            print("downloadImage")
            
            var onGoingTasks = self.tasks.filter { (task) -> Bool in
                task.isDownloading && task.status == .requesting
            } .sorted { (lhs, rhs) -> Bool in
                lhs.created > rhs.created
            }
            
            // if the task's result been cache, use that directly
            onGoingTasks.forEach {
                if self.imageCache.keys.contains($0.fingerPrint) {
                    $0.status = .finished
                    $0.callBack?(.success(self.imageCache[$0.fingerPrint]))
                }
            }
            onGoingTasks.removeAll { $0.status != .requesting}
            
            // take the first 8 tasks
            onGoingTasks = Array(onGoingTasks.prefix(8))
            onGoingTasks.forEach { $0.status = .ongoing }
            
            let predicate = NSPredicate(format:"fingerPrint IN %@", onGoingTasks.map { $0.fingerPrint })
            let query = CKQuery(recordType: LMImage.Keys.Images.rawValue, predicate: predicate)
            
            CKContainer.default().privateCloudDatabase.perform(query, inZoneWith: CKRecordZone.default().zoneID) { (records, error) in
                main {
                    if let error = error {
                        onGoingTasks.forEach {
                            $0.status = .failed(error: error)
                            $0.callBack?(.failure(error))
                        }
                    } else if let records = records {
                        onGoingTasks.forEach { (task: Task) in
                            if let record = records.first(where: { (record) -> Bool in
                                task.fingerPrint == record.object(forKey: LMImage.Keys.fingerPrint.rawValue) as? String
                            }) {
                                task.status = .finished
                                
                                if
                                    let imageAsset = record.object(forKey: LMImage.Keys.data.rawValue) as? CKAsset,
                                    let imageFileURL = imageAsset.fileURL,
                                    let imageData = try? Data(contentsOf: imageFileURL),
                                    let fingerPrint = record.object(forKey: LMImage.Keys.fingerPrint.rawValue) as? String {
                                    
                                    self.appContext?.imageService.saveImageToFile(data: imageData, fingerPrint: fingerPrint, completeion: { _ in })
                                    if let image = UIImage(data: imageData) {
                                        self.imageCache[fingerPrint] = image
                                        task.callBack?(.success(image))
                                    }
                                }
                            } else {
                                task.status = .failed(error: LMError.iCloudImageError)
                            }
                        }
                        print("downloadFinished downloadFinished")
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
        guard let data = try? encoder.encode(toBeUploadTasks.map { $0.fingerPrint }) else { return }
        try? data.write(to: uploadingListPath)
    }
    
    func loadToBeUploadTasksFromFile() {
        guard var uploadingListPath = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else { return }
        uploadingListPath.appendPathComponent("uploadingTasks.plist")
        guard let data = try? Data(contentsOf: uploadingListPath) else { return }
        let decoder = PropertyListDecoder()
        guard let tasksFromFile = try? decoder.decode(Set<String>.self, from: data) else { return }

        tasks.append(contentsOf: tasksFromFile.map { Task(fingerPrint: $0, isDownloading: false) })
    }
    
    static func createImageFingerPrint(noteID: String, quality: LMImage.Quality) -> String {
        return "\(noteID)\(quality.rawValue)"
    }
    
    class Task: Hashable {
        static func == (lhs: LMInternetService.Task, rhs: LMInternetService.Task) -> Bool {
            lhs.fingerPrint == rhs.fingerPrint
        }
        func hash(into hasher: inout Hasher) {
            hasher.combine(fingerPrint)
        }
        
        init(fingerPrint: String, isDownloading: Bool, callBack: ResultAsync<UIImage?>? = nil) {
            self.fingerPrint = fingerPrint
            self.isDownloading = isDownloading
            self.callBack = callBack
            created = Date()
        }
        
        var fingerPrint: String
        var isDownloading: Bool
        var callBack: ResultAsync<UIImage?>?
        var status: Status = .requesting
        var created: Date
    }
    
    enum Status: Equatable {
        case requesting
        case ongoing
        case finished
        case failed(error: Error?)
        
        static func == (lhs: LMInternetService.Status, rhs: LMInternetService.Status) -> Bool {
            switch lhs {
            case .requesting:
                switch rhs { case .requesting: return true; default: return false }
            case .ongoing:
                switch rhs { case .ongoing: return true; default: return false }
            case .finished:
                switch rhs { case .finished: return true; default: return false }
            case .failed(_):
                switch rhs { case .failed(_): return true; default: return false }
            }
        }
    }
}
