import UIKit
import MMarkParser

class ViewController: UIViewController {
    private var textView: MMarkTextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        if #available(iOS 15.0, *) {
            // Use custom MMarkTextView
            textView = MMarkTextView()
            textView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(textView)

            print("[ViewController] Created MMarkTextView")
        } else {
            // Fallback for iOS < 15
            print("[ViewController] iOS 15.0+ is required")
            return
        }

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        loadMarkdown()

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

//        // 检查并修正 contentOffset
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
//            guard let textView = self?.textView else { return }
//            print("[ViewController] viewDidAppear - contentOffset: \(textView.contentOffset), contentSize: \(textView.contentSize), bounds: \(textView.bounds)")
//
//            // 如果 contentOffset 不正确，重置它
//            if textView.contentOffset.y < 0 {
//                print("[ViewController] Fixing negative contentOffset.y to 0")
//                textView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
//            }
//
//            // 打印文本内容的前 100 个字符，用于调试
//            if let attributedText = textView.attributedText {
//                let text = attributedText.string
//                let preview = String(text.prefix(100))
//                print("[ViewController] Text preview: \(preview)")
//                print("[ViewController] Text length: \(text.count)")
//            }
//
//            // 尝试滚动到顶部，看看标题是否可见
//            print("[ViewController] Attempting to scroll to top...")
//            textView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
//            print("[ViewController] After scroll to top - contentOffset: \(textView.contentOffset)")
//            print("[ViewController] bounds after scroll: \(textView.bounds)")
//            print("[ViewController] textContainerInset: \(textView.textContainerInset)")
//            print("[ViewController] frame: \(textView.frame)")
//            print("[ViewController] safeAreaInsets: \(self?.view.safeAreaInsets ?? .zero)")
//        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("[ViewController] viewDidLayoutSubviews - frame: \(textView.frame), bounds: \(textView.bounds)")
    }

    private func loadMarkdown() {
        if #available(iOS 15.0, *) {
            print("[ViewController] Loading markdown...")
            let fullMarkdown = sampleMarkdown
            textView.setMarkdown(fullMarkdown)
            print("[ViewController] Markdown loaded")
        }
    }

}
