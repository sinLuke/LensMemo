////
////  LMPhotoPreparingViewController.swift
////  LensMemo
////
////  Created by Luke Yin on 2020-09-01.
////
//
//import UIKit
//
//class LMPhotoPreparingViewController: UIViewController {
//    
//    @IBOutlet weak var tableView: UITableView!
//    @IBOutlet weak var finishButton: UIButton!
//    
//    weak var appContext: LMAppContext?
//    var dismissHandler: ([UIImage]) -> () = { _ in }
//    var timer: Timer?
//    var tasks: [SubTask] = []
//    
//    var finishedWithError = false {
//        didSet {
//            configureView()
//        }
//    }
//    
//    func prepareImages(completion: @escaping ([UIImage]) -> ()) {
//        let group = DispatchGroup()
//        var images: [UIImage] = []
//        group.enter()
//        self.tasks.forEach { (task) in
//            group.enter()
//            task.delegate?.isTaskFinished(of: task, completion: { (image) in
//                if let image = image {
//                    images.append(image)
//                }
//                group.leave()
//            })
//        }
//        group.leave()
//        group.notify(queue: .main) {
//            completion(images)
//        }
//    }
//    
//    @IBAction func cancelButtonTapped(_ sender: Any) {
//        cancelButtonAction()
//    }
//    
//    func cancelButtonAction() { }
//    func configureView() { }
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        tableView.delegate = self
//        tableView.dataSource = self
//        tableView.register(UINib(nibName: String(describing: LMPhotoPreparingTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: LMPhotoPreparingTableViewCell.self))
//        tableView.register(UINib(nibName: String(describing: AlertHeaderTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: AlertHeaderTableViewCell.self))
//    }
//    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        timer = Timer(timeInterval: 1.3, repeats: true, block: { [weak self] _ in
//            var indexPathChanged: [IndexPath] = []
//            self?.tasks.indices.forEach { index in
//                guard let task = self?.tasks[index] else { return }
//                var changed = false
//                if task.status != .finish, let status = task.delegate?.status(of: task) {
//                    if task.status != status {
//                        task.status = status
//                        changed = true
//                    }
//                }
//                
//                task.delegate?.isTaskFinished(of: task, completion: { (image) in
//                    if image != nil {
//                        task.status = .finish
//                    }
//                })
//                
//                if let statusDescription = task.delegate?.statusDescription(of: task) {
//                    if task.statusDescription != statusDescription {
//                        task.statusDescription = statusDescription
//                        changed = true
//                    }
//                }
//                
//                if let image = task.delegate?.image(of: task) {
//                    if task.image != image {
//                        task.image = image
//                        changed = true
//                    }
//                }
//                
//                if changed {
//                    indexPathChanged.append(IndexPath(row: index, section: 0))
//                }
//            }
//            
//            if !indexPathChanged.isEmpty {
//                self?.tableView.reloadRows(at: indexPathChanged, with: .fade)
//            }
//            
//            if (self?.tasks ?? []).reduce(true, { (result, nextTask) -> Bool in
//                return result && nextTask.status == .finish
//            }) {
//                self?.prepareImages { (images) in
//                    self?.dismissHandler(images)
//                    self?.dismiss(animated: true, completion: nil)
//                }
//            }
//            
//            if (self?.tasks ?? []).reduce(true, { (result, nextTask) -> Bool in
//                return result && (nextTask.status == .finish || nextTask.status == .error)
//            }) {
//                self?.finishedWithError = true
//            }
//        })
//        timer!.tolerance = 0.5
//        main {
//            RunLoop.current.add(self.timer!, forMode: .default)
//        }
//    }
//    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        timer?.invalidate()
//    }
//    
//    class SubTask {
//        var title: String = ""
//        var image: UIImage?
//        var statusDescription: String = ""
//        var fingerPrint: String = ""
//        var status: Status = .queue
//        var note: LMNote
//        weak var delegate: TaskDelegate?
//        
//        init(note: LMNote, delegate: TaskDelegate) {
//            self.note = note
//            self.delegate = delegate
//        }
//        
//        enum Status {
//            case finish
//            case queue
//            case loading
//            case error
//        }
//    }
//}
//
//extension LMPhotoPreparingViewController: UITableViewDelegate, UITableViewDataSource {
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return 1
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        if indexPath.row == 0 {
//            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: AlertHeaderTableViewCell.self), for: indexPath)
//            (cell as? AlertHeaderTableViewCell)?.configure(title: "preparingImage", icon: UIImage(systemName: "icloud.and.arrow.down"), color: .systemBlue)
//            return cell
//        } else {
//            let task = tasks[indexPath.row - 1]
//            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LMPhotoPreparingTableViewCell.self), for: indexPath)
//            (cell as? LMPhotoPreparingTableViewCell)?.update(data: task)
//            return cell
//        }
//    }
//    
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return tasks.count + 1
//    }
//}
//    
//protocol TaskDelegate: class {
//    func status(of task: LMPhotoPreparingViewController.SubTask) -> LMPhotoPreparingViewController.SubTask.Status?
//    func statusDescription(of task: LMPhotoPreparingViewController.SubTask) -> String?
//    func image(of task: LMPhotoPreparingViewController.SubTask) -> UIImage?
//    func isTaskFinished(of task: LMPhotoPreparingViewController.SubTask, completion: @escaping (UIImage?) -> ())
//    func cancelTasks(completion: @escaping () -> ())
//}
//
//class LMDownloadPhotoPreparingViewController: LMPhotoPreparingViewController, TaskDelegate {
//    class func getInstance(appContext: LMAppContext) -> LMDownloadPhotoPreparingViewController {
//        let controller = LMDownloadPhotoPreparingViewController.init(nibName: String(describing: LMPhotoPreparingViewController.self), bundle: nil)
//        controller.appContext = appContext
//        return controller
//    }
//    
//    func configueAsImageDownloading(notes: [LMNote], completion: @escaping ([UIImage]) -> ()) {
//        tasks = notes.map { note in
//            let task = SubTask(note: note, delegate: self)
//            task.image = appContext?.imageService.getImage(for: note, quality: .original, source: .local, completion: { (result) in
//                result.see(ifSuccess: { (image) in
//                    task.image = image
//                    task.status = .finish
//                }) { _ in }
//            })
//            return task
//        }
//        dismissHandler = completion
//    }
//    
//    func isTaskFinished(of task: SubTask, completion: @escaping (UIImage?) -> ()) {
//        _ = appContext?.imageService.getImage(for: task.note, quality: .original, source: .local, completion: { (result) in
//            result.see(ifSuccess: { image in
//                completion(image)
//            }) { _ in
//                completion(nil)
//            }
//        })
//    }
//    
//    func status(of task: LMPhotoPreparingViewController.SubTask) -> LMPhotoPreparingViewController.SubTask.Status? {
//        if LMInternetService.shared.downloadingTasks.contains(task.fingerPrint) {
//            return .loading
//        }
//        
//        if LMInternetService.shared.failedTasks.contains(task.fingerPrint) {
//            return .error
//        }
//        
//        if LMInternetService.shared.requestingTasks.contains(task.fingerPrint) {
//            return .queue
//        }
//        
//        return nil
//    }
//    
//    func statusDescription(of task: LMPhotoPreparingViewController.SubTask) -> String? {
//        if LMInternetService.shared.downloadingTasks.contains(task.fingerPrint) {
//            return "downloading"
//        }
//        
//        if LMInternetService.shared.failedTasks.contains(task.fingerPrint) {
//            return "network_error"
//        }
//        
//        if LMInternetService.shared.requestingTasks.contains(task.fingerPrint) {
//            return "waiting"
//        }
//        
//        return nil
//    }
//        
//    func image(of task: LMPhotoPreparingViewController.SubTask) -> UIImage? {
//        if let image = appContext?.imageService.getImage(for: task.note, quality: .original, source: .memory, completion: { _ in
//            return
//        }) {
//            return image
//        }
//        return nil
//    }
//    
//    func cancelTasks(completion: @escaping () -> ()) {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//            completion()
//        }
//    }
//    
//    override func configureView() {
//        finishButton.setTitle(finishedWithError ? "finish" : "cancel", for: .normal)
//    }
//    
//    override func cancelButtonAction() {
//        if let delegate = tasks.first?.delegate {
//            delegate.cancelTasks {
//                self.prepareImages { (images) in
//                    self.dismissHandler(images)
//                    self.dismiss(animated: true, completion: nil)
//                }
//            }
//        } else {
//            self.prepareImages { (images) in
//                self.dismissHandler(images)
//                self.dismiss(animated: true, completion: nil)
//            }
//        }
//    }
//}
