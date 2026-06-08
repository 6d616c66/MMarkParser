import UIKit
import MMarkParser

class ViewController: UIViewController {
    private var textView: MMarkTextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        if #available(iOS 15.0, *) {
            textView = MMarkTextView()
            textView.bounds = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width - 32, height: UIScreen.main.bounds.size.height)
            textView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(textView)
        } else {
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
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    private func loadMarkdown() {
        if #available(iOS 15.0, *) {
            let fullMarkdown = sampleMarkdown
            textView.setMarkdown(fullMarkdown)
        }
    }

}
