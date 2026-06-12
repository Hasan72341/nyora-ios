import SwiftUI
import UIKit

/// A pinch/pan/double-tap zoomable page image.
///
/// Backed by a `UIScrollView` + `UIImageView` (`UIViewRepresentable`) so that zoom and pan
/// don't fight SwiftUI's paged `TabView`: the scroll view only intercepts pan when zoomed in
/// (panGestureRecognizer is disabled at 1x), so horizontal swipes still flip pages.
///
/// - Double-tap toggles 1x / 2.5x (zoomed to the tapped point).
/// - Pinch zooms 1x – 4x.
/// - Pan is available only when zoomed past 1x.
/// - A single tap at 1x calls `onTap` (so the reader can toggle chrome).
struct ZoomableImage: View {
    let url: URL?
    var headers: [String: String] = [:]
    var contentMode: ContentMode = .fit
    /// Called on a single tap while at the base (1x) zoom level.
    var onTap: () -> Void = {}

    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        ZStack {
            if let image {
                ZoomScrollView(image: image, contentMode: contentMode, onTap: onTap)
            } else {
                Rectangle()
                    .fill(.quaternary)
                    .overlay {
                        if failed {
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        } else {
                            ProgressView()
                        }
                    }
                    // Keep chrome-toggle working even before/without an image.
                    .contentShape(Rectangle())
                    .onTapGesture { onTap() }
            }
        }
        .task(id: url) { await load() }
    }

    private func load() async {
        guard let url else { failed = true; return }
        image = nil; failed = false
        if let cached = ImageLoader.shared.cached(url) {
            image = cached
            return
        }
        do {
            let img = try await ImageLoader.shared.load(url, headers: headers)
            if !Task.isCancelled { image = img }
        } catch {
            if !Task.isCancelled { failed = true }
        }
    }
}

// MARK: - UIScrollView-backed zoom

private struct ZoomScrollView: UIViewRepresentable {
    let image: UIImage
    let contentMode: ContentMode
    let onTap: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onTap: onTap) }

    func makeUIView(context: Context) -> FittingScrollView {
        let scroll = FittingScrollView()
        scroll.delegate = context.coordinator
        scroll.maximumZoomScale = 4.0
        scroll.minimumZoomScale = 1.0
        scroll.bouncesZoom = true
        scroll.showsHorizontalScrollIndicator = false
        scroll.showsVerticalScrollIndicator = false
        scroll.backgroundColor = .clear
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.decelerationRate = .fast
        scroll.fillWidth = (contentMode == .fill)
        scroll.imageView.image = image
        context.coordinator.scrollView = scroll
        context.coordinator.imageView = scroll.imageView

        // Double-tap: toggle zoom.
        let doubleTap = UITapGestureRecognizer(target: context.coordinator,
                                               action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scroll.addGestureRecognizer(doubleTap)

        // Single-tap: pass through (chrome toggle). Must wait for double-tap to fail.
        let singleTap = UITapGestureRecognizer(target: context.coordinator,
                                               action: #selector(Coordinator.handleSingleTap(_:)))
        singleTap.numberOfTapsRequired = 1
        singleTap.require(toFail: doubleTap)
        scroll.addGestureRecognizer(singleTap)

        // At 1x the pan gesture is disabled so the parent TabView keeps paging swipes.
        scroll.panGestureRecognizer.isEnabled = false

        return scroll
    }

    func updateUIView(_ scroll: FittingScrollView, context: Context) {
        context.coordinator.onTap = onTap
        scroll.fillWidth = (contentMode == .fill)
        if scroll.imageView.image !== image {
            scroll.setZoomScale(1.0, animated: false)
            scroll.imageView.image = image
            scroll.needsRefit = true
            scroll.setNeedsLayout()
        }
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        var onTap: () -> Void
        weak var imageView: UIImageView?
        weak var scrollView: FittingScrollView?

        init(onTap: @escaping () -> Void) { self.onTap = onTap }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            (scrollView as? FittingScrollView)?.centerImage()
            // Only allow pan once zoomed in, so paging isn't hijacked at 1x.
            scrollView.panGestureRecognizer.isEnabled = scrollView.zoomScale > scrollView.minimumZoomScale + 0.001
        }

        @objc func handleSingleTap(_ gr: UITapGestureRecognizer) {
            guard let scrollView else { onTap(); return }
            // Only treat as a chrome toggle when not zoomed in.
            if scrollView.zoomScale <= scrollView.minimumZoomScale + 0.001 {
                onTap()
            }
        }

        @objc func handleDoubleTap(_ gr: UITapGestureRecognizer) {
            guard let scrollView else { return }
            if scrollView.zoomScale > scrollView.minimumZoomScale + 0.001 {
                scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            } else {
                let target: CGFloat = 2.5
                let point = gr.location(in: imageView)
                let size = scrollView.bounds.size
                let w = size.width / target
                let h = size.height / target
                let rect = CGRect(x: point.x - w / 2, y: point.y - h / 2, width: w, height: h)
                scrollView.zoom(to: rect, animated: true)
            }
        }
    }
}

/// A `UIScrollView` that fits + centres its single image view in `layoutSubviews` — which,
/// unlike a `UIViewRepresentable`'s `updateUIView`, reliably fires once the view receives its
/// real (non-zero) bounds from SwiftUI. (The previous `updateUIView`-driven layout never ran
/// because SwiftUI didn't re-invoke it after the first zero-bounds pass → blank pages.)
final class FittingScrollView: UIScrollView {
    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.isUserInteractionEnabled = true
        return iv
    }()
    /// When true, fit the image to the viewport width (allowing vertical scroll) instead of
    /// fitting the whole page on screen.
    var fillWidth = false
    /// Set when the image changes so the next layout pass re-fits even if bounds are unchanged.
    var needsRefit = false
    private var lastFitSize: CGSize = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let image = imageView.image, bounds.width > 0, bounds.height > 0 else { return }
        if bounds.size != lastFitSize || needsRefit {
            lastFitSize = bounds.size
            needsRefit = false
            fit(to: image.size)
        }
        centerImage()
    }

    private func fit(to imgSize: CGSize) {
        guard imgSize.width > 0, imgSize.height > 0 else { return }
        zoomScale = 1.0
        let scale: CGFloat = fillWidth
            ? bounds.width / imgSize.width
            : min(bounds.width / imgSize.width, bounds.height / imgSize.height)
        let fitted = CGSize(width: imgSize.width * scale, height: imgSize.height * scale)
        imageView.frame = CGRect(origin: .zero, size: fitted)
        contentSize = fitted
    }

    func centerImage() {
        let insetX = max(0, (bounds.width - imageView.frame.width) / 2)
        let insetY = max(0, (bounds.height - imageView.frame.height) / 2)
        contentInset = UIEdgeInsets(top: insetY, left: insetX, bottom: insetY, right: insetX)
    }
}
