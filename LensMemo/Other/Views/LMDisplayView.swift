//
//  LMDisplayView.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-25.
//

import UIKit

class LMDisplayView: UIView {
    
    private var scrollView = UIScrollView()
    private var contentView = UIView()
    private var imageViews: [LMImageView] = []
    weak var dataSource: LMDisplayViewDataSource?
    weak var delegate: LMDisplayViewDelegate?
    private var lastViewedIndex: Int?
    private var lastViewedCounter = 0
    private var trailingAdditionalInset: CGFloat = 0
    weak var appContext: LMAppContext?
    
    var timer: Timer? = nil
    
    func startTimer() {
        timer = Timer(timeInterval: 0.5, repeats: true, block: { [weak self] _ in
            self?.timerBlock()
        })
        timer!.tolerance = 1
        main {
            RunLoop.current.add(self.timer!, forMode: .default)
        }
    }
    
    func timerBlock() {
        if delegate?.shouldUseTimmer() == false { return }
        main {
            guard self.scrollView.zoomScale > self.scrollView.minimumZoomScale * 1.8 else { return }

            let centerPoint = CGPoint(x: self.scrollView.contentOffset.x + self.scrollView.bounds.width / 2, y: self.scrollView.contentOffset.y + self.scrollView.bounds.height / 2)
            let centerInContent = CGPoint(x: centerPoint.x / self.scrollView.zoomScale, y: centerPoint.y / self.scrollView.zoomScale)
            for index in self.imageViews.indices {
                let imageView = self.imageViews[index]
                self.loadImage(at: index)
                guard self.scrollView.panGestureRecognizer.state != .changed else { return }
                if imageView.frame.contains(centerInContent) {
                    if self.lastViewedIndex == index {
                        self.delegate?.displayViewDidFocusOnNote(index)
                    } else {
                        self.lastViewedCounter = (self.lastViewedCounter + 1)%10
                        if self.lastViewedCounter == 5 {
                            self.lastViewedIndex = index
                        }
                    }
                    self.delegate?.displayViewDidScrollTo(index)
                    return
                }
            }
        }
    }
    
    func setTrailingAdditionalInset(inset: CGFloat) {
        trailingAdditionalInset = inset
        scrollView.contentInset = UIEdgeInsets(top: scrollView.contentInset.top, left: scrollView.contentInset.left, bottom: scrollView.contentInset.bottom, right: scrollView.contentInset.right + inset)
        adjustScrollableContent()
    }
    
    func adjustScrollableContent() {
        let offsetX = max(((scrollView.bounds.width - trailingAdditionalInset) - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: 0, right: trailingAdditionalInset)
    }
    
    func configure(dataSource: LMDisplayViewDataSource, delegate: LMDisplayViewDelegate) {
        self.dataSource = dataSource
        self.delegate = delegate
        timer?.invalidate()
        startTimer()
        configureImages()

        addSubview(scrollView)
        let tapGesture = LMTapGestureRecognizer(target: self, action: #selector(scrollViewTapped))
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(scrollViewDoubleTapped))

        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(scrollViewLongPress))
        doubleTapGesture.numberOfTapsRequired = 2
        longPressGesture.minimumPressDuration = 0.1
        tapGesture.require(toFail: doubleTapGesture)
        tapGesture.require(toFail: longPressGesture)
        doubleTapGesture.require(toFail: longPressGesture)
        scrollView.addGestureRecognizer(tapGesture)
        scrollView.addGestureRecognizer(doubleTapGesture)
        scrollView.addGestureRecognizer(longPressGesture)
        scrollView.frame = self.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.delegate = self
        scrollView.alwaysBounceHorizontal = false
        
        scrollView.addSubview(contentView)
    }
    
    @objc func scrollViewTapped(_ sender: LMTapGestureRecognizer) {
        switch sender.state {
        case .recognized:
            let centerInContent = CGPoint(x: sender.location(in: sender.view).x / self.scrollView.zoomScale, y: sender.location(in: sender.view).y / self.scrollView.zoomScale)
            for index in self.imageViews.indices {
                let imageView = self.imageViews[index]
                if imageView.frame.contains(centerInContent) {
                    delegate?.displayViewDidRecievedTap(index)
                    return
                }
            }
        default: return
        }
        
    }
    
    @objc func scrollViewDoubleTapped(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: contentView)
        let locationInContainer = sender.location(in: self)
        
        if isRegularZoom() {
            let xLocation = location.x - scrollView.bounds.width
            let xOffset = max(0, min(xLocation, contentView.bounds.width - scrollView.bounds.width))
            let yLocation = location.y - scrollView.bounds.height
            let yOffset = max(0, min(yLocation, contentView.bounds.height - scrollView.bounds.height))
            let targetRect = CGRect(x: xOffset, y: yOffset, width: scrollView.bounds.width * 2, height: scrollView.bounds.height * 2)
            
            scrollView.zoom(to: targetRect, animated: true)
        } else {
            resetZoomLevel(animated: true)
            let yLocation = (location.y) * scrollView.zoomScale - locationInContainer.y
            scrollView.setContentOffset(CGPoint(x: 0, y: yLocation), animated: true)
        }
    }

    @objc func scrollViewLongPress(_ sender: UITapGestureRecognizer) {
        if delegate?.shouldUseTimmer() == false { return }
        switch sender.state {
        case .began:
            UIImpactFeedbackGenerator().impactOccurred()
            let centerInContent = CGPoint(x: sender.location(in: sender.view).x / self.scrollView.zoomScale, y: sender.location(in: sender.view).y / self.scrollView.zoomScale)
            for index in self.imageViews.indices {
                let imageView = self.imageViews[index]
                if imageView.frame.contains(centerInContent) {
                    delegate?.displayViewShowNoteDetail(index)
                    return
                }
            }
        default:
            return
        }
    }
    
    func isRegularZoom() -> Bool {
        let scaleOffset = scrollView.zoomScale - scrollView.minimumZoomScale * 2
        return scaleOffset < scrollView.minimumZoomScale * 0.2 && scaleOffset > -(scrollView.minimumZoomScale * 0.2)
    }
    
    func configureImages() {
        guard let dataSource = self.dataSource, dataSource.needReloadData() else { return }
        
        imageViews.forEach { (imageView) in
            imageView.removeFromSuperview()
        }
        imageViews = []
        
        var totalHeight: CGFloat = 0
        var maxiumWidth: CGFloat = 0
        
        for index in 0 ..< dataSource.numberOfImages() {
            let size = dataSource.displayView(self, sizeOfImageAt: index)
            if size.width > maxiumWidth {
                maxiumWidth = size.width
            }
        }
        
        for index in 0 ..< dataSource.numberOfImages() {
            var size = dataSource.displayView(self, sizeOfImageAt: index)
            if size.height == 0 || size.width == 0 {
                size = CGSize(width: 100, height: 100)
            }
            
            let imageView = LMImageView(image: nil)
            imageViews.append(imageView)
            imageView.frame = CGRect(x: 0, y: totalHeight, width: maxiumWidth, height: (size.height / size.width) * maxiumWidth)
            totalHeight += imageView.frame.height
            contentView.addSubview(imageView)
        }
        
        contentView.frame = CGRect(x: 0, y: 0, width: maxiumWidth * scrollView.zoomScale, height: totalHeight * scrollView.zoomScale)
        scrollView.zoomScale = 1.0
        scrollView.contentSize = contentView.frame.size
    }
    
    func loadImage(at index: Int) {
        guard let dataSource = self.dataSource, imageViews.indices.contains(index) else { return }
        
        let imageView = imageViews[index]
        
        if let note = dataSource.displayView(self, noteAt: index), let appContext = appContext {
            imageView.setImage(note: note, quality: .original, appContext: appContext)
        }
    }
    
    func loadImagesAtScroll() {
        imageViews.indices.forEach { (index) in
            let imageView = imageViews[index]
            let viewFinder = CGRect(x: scrollView.contentOffset.x / scrollView.zoomScale, y: scrollView.contentOffset.y / scrollView.zoomScale, width: scrollView.bounds.width / scrollView.zoomScale, height: scrollView.bounds.height / scrollView.zoomScale)
            guard imageView.frame.intersects(viewFinder) else {
                return
            }
            loadImage(at: index)
        }
    }
    
    func resetZoomLevel(animated: Bool = true) {
        scrollView.setZoomScale(scrollView.minimumZoomScale * 2, animated: animated)
    }
    
    func scrollTo(item index: Int) {
        if imageViews.indices.contains(index) {
            let targetImageView = imageViews[index]
            let targetCenter = CGPoint(x: (targetImageView.frame.origin.x + targetImageView.frame.width / 2) * scrollView.zoomScale, y: (targetImageView.frame.origin.y + targetImageView.frame.height / 2) * scrollView.zoomScale)
            scrollView.setContentOffset(CGPoint(x: targetCenter.x - (scrollView.bounds.width - scrollView.adjustedContentInset.right) / 2, y: targetCenter.y - scrollView.bounds.height / 2), animated: true)
        }
    }
    
    func reloadData() {
        configureImages()
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard scrollView.contentSize.width > 0 else { return }
        
        scrollView.minimumZoomScale = 0.5 * (scrollView.frame.width / contentView.bounds.width)
        scrollView.maximumZoomScale = 1.0
    }
}

extension LMDisplayView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        contentView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        adjustScrollableContent()
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.displayViewDidRecievedUserInteractive()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        loadImagesAtScroll()
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        if isRegularZoom() {
            resetZoomLevel(animated: true)
            
        }
    }
}

protocol LMDisplayViewDataSource: class {
    func numberOfImages() -> Int
    func displayView(_ displayView: LMDisplayView, sizeOfImageAt index: Int) -> CGSize
    func displayView(_ displayView: LMDisplayView, noteAt index: Int) -> LMNote?
    func displayView(_ displayView: LMDisplayView, compactColorOfImageAt index: Int) -> UIColor
    func needReloadData() -> Bool
}

protocol LMDisplayViewDelegate: class {
    func displayViewDidRecievedUserInteractive()
    func displayViewDidRecievedTap(_ index: Int)
    func shouldUseTimmer() -> Bool
    func displayViewDidScrollTo(_ index: Int)
    func displayViewDidFocusOnNote(_ index: Int)
    func displayViewShowNoteDetail(_ index: Int)
}
