import UIKit
import MMarkParser

// Test ViewController to verify NSTextAttachmentViewProvider basic functionality
class TestViewController: UIViewController {

    private var textView: MMarkTextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        // Register our test view provider
        NSTextAttachment.registerViewProviderClass(MyViewProvider.self, forFileType: "public.data")

        // Create attachments
        let firstAttachment = NSTextAttachment.init(data: nil, ofType: "public.data")
        firstAttachment.allowsTextAttachmentView = true

        let secondAttachment = NSTextAttachment.init(data: nil, ofType: "public.data")
        secondAttachment.allowsTextAttachmentView = true
//        secondAttachment.bounds = CGRect(x: 0, y: 0, width: 20, height: 20)

        // Build attributed string
        let string = NSMutableAttributedString()
        string.append(NSAttributedString(string: "This is the 1st attachment: "))
        string.append(NSAttributedString(attachment: firstAttachment))
        string.append(NSAttributedString(string: "\nThis is the 2nd attachment: "))
        string.append(NSAttributedString(attachment: secondAttachment))

        // Setup text view
        textView = MMarkTextView()
        textView.layer.borderColor = UIColor.red.cgColor
        textView.layer.borderWidth = 1.0
        textView.attributedText = string
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60)
        ])
    }
}

// MARK: - Test ViewProvider
class MyViewProvider: NSTextAttachmentViewProvider {

    override func loadView() {
        let view = UIView()
        view.backgroundColor = .blue
        self.view = view
        self.tracksTextAttachmentViewBounds = true
    }

    override func attachmentBounds(for attributes: [NSAttributedString.Key: Any], location: any NSTextLocation, textContainer: NSTextContainer?, proposedLineFragment: CGRect, position: CGPoint) -> CGRect {
        return CGRect(x: 0, y: 0, width: 100, height: 100)
    }
}
