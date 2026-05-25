import UIKit
import MMarkParser


/// Streaming demo view controller - demonstrates markdown streaming rendering
class StreamViewController: UIViewController {

    // MARK: - Subviews

    private var streamTextView: MMarkStreamTextView!
    private let progressLabel = UILabel()

    // Streaming control buttons
    private let startButton = UIButton(type: .system)
    private let pauseButton = UIButton(type: .system)
    private let resumeButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)
    private let appendButton = UIButton(type: .system)
    private let onceButton = UIButton(type: .system)

    // Speed control
    private let speedSlider = UISlider()
    private let speedLabel = UILabel()
    private let chunkSlider = UISlider()
    private let chunkLabel = UILabel()

    // MARK: - Test content

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "流式"
        view.backgroundColor = .systemBackground
        setupUI()
        setupStreamTextView()
        setupSpeedControls()
    }

    // MARK: - UI Setup

    private func setupUI() {
        let margin: CGFloat = 16
        let btnW = (view.bounds.width - margin * 2 - 10 * 6) / 7

        // Speed
        speedLabel.translatesAutoresizingMaskIntoConstraints = false
        speedLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        speedLabel.textColor = .secondaryLabel
        speedLabel.text = "Speed: 0.03s"
        view.addSubview(speedLabel)

        speedSlider.translatesAutoresizingMaskIntoConstraints = false
        speedSlider.minimumValue = 0.005
        speedSlider.maximumValue = 0.15
        speedSlider.value = 0.03
        speedSlider.tintColor = .systemBlue
        speedSlider.addTarget(self, action: #selector(speedChanged), for: .valueChanged)
        view.addSubview(speedSlider)

        chunkLabel.translatesAutoresizingMaskIntoConstraints = false
        chunkLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        chunkLabel.textColor = .secondaryLabel
        chunkLabel.text = "Chunk: 3"
        view.addSubview(chunkLabel)

        chunkSlider.translatesAutoresizingMaskIntoConstraints = false
        chunkSlider.minimumValue = 1
        chunkSlider.maximumValue = 20
        chunkSlider.value = 3
        chunkSlider.tintColor = .systemGreen
        chunkSlider.addTarget(self, action: #selector(chunkChanged), for: .valueChanged)
        view.addSubview(chunkSlider)

        // Progress
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        progressLabel.textColor = .secondaryLabel
        progressLabel.textAlignment = .center
        progressLabel.text = "Idle  |  Displayed: 0/0"
        view.addSubview(progressLabel)

        // Buttons
        let buttons: [(String, UIButton)] = [
            ("Start", startButton), ("Pause", pauseButton),
            ("Resume", resumeButton), ("Stop", stopButton),
            ("Append", appendButton), ("Once", onceButton)
        ]
        for (title, btn) in buttons {
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.setTitle(title, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
            btn.backgroundColor = .systemGray6
            btn.layer.cornerRadius = 8
            btn.layer.borderWidth = 0.5
            btn.layer.borderColor = UIColor.systemGray4.cgColor
            view.addSubview(btn)
        }
        startButton.tintColor = .systemBlue
        pauseButton.tintColor = .systemOrange
        resumeButton.tintColor = .systemGreen
        stopButton.tintColor = .systemRed
        appendButton.tintColor = .systemPurple
        onceButton.tintColor = .darkGray

        startButton.addTarget(self, action: #selector(didTapStart), for: .touchUpInside)
        pauseButton.addTarget(self, action: #selector(didTapPause), for: .touchUpInside)
        resumeButton.addTarget(self, action: #selector(didTapResume), for: .touchUpInside)
        stopButton.addTarget(self, action: #selector(didTapStop), for: .touchUpInside)
        appendButton.addTarget(self, action: #selector(didTapAppend), for: .touchUpInside)
        onceButton.addTarget(self, action: #selector(didTapOnce), for: .touchUpInside)

        NSLayoutConstraint.activate([
            speedLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            speedLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),

            speedSlider.centerYAnchor.constraint(equalTo: speedLabel.centerYAnchor),
            speedSlider.leadingAnchor.constraint(equalTo: speedLabel.trailingAnchor, constant: 6),
            speedSlider.widthAnchor.constraint(equalToConstant: 120),
            speedSlider.heightAnchor.constraint(equalToConstant: 24),

            chunkLabel.centerYAnchor.constraint(equalTo: speedLabel.centerYAnchor),
            chunkLabel.leadingAnchor.constraint(equalTo: speedSlider.trailingAnchor, constant: 12),

            chunkSlider.centerYAnchor.constraint(equalTo: speedLabel.centerYAnchor),
            chunkSlider.leadingAnchor.constraint(equalTo: chunkLabel.trailingAnchor, constant: 6),
            chunkSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),
            chunkSlider.heightAnchor.constraint(equalToConstant: 24),

            progressLabel.topAnchor.constraint(equalTo: speedLabel.bottomAnchor, constant: 4),
            progressLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            progressLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),
            progressLabel.heightAnchor.constraint(equalToConstant: 20),

            startButton.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 4),
            startButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            startButton.widthAnchor.constraint(equalToConstant: max(btnW, 48)),
            startButton.heightAnchor.constraint(equalToConstant: 32),

            pauseButton.centerYAnchor.constraint(equalTo: startButton.centerYAnchor),
            pauseButton.leadingAnchor.constraint(equalTo: startButton.trailingAnchor, constant: 8),
            pauseButton.widthAnchor.constraint(equalToConstant: max(btnW, 48)),
            pauseButton.heightAnchor.constraint(equalToConstant: 32),

            resumeButton.centerYAnchor.constraint(equalTo: startButton.centerYAnchor),
            resumeButton.leadingAnchor.constraint(equalTo: pauseButton.trailingAnchor, constant: 8),
            resumeButton.widthAnchor.constraint(equalToConstant: max(btnW, 48)),
            resumeButton.heightAnchor.constraint(equalToConstant: 32),

            stopButton.centerYAnchor.constraint(equalTo: startButton.centerYAnchor),
            stopButton.leadingAnchor.constraint(equalTo: resumeButton.trailingAnchor, constant: 8),
            stopButton.widthAnchor.constraint(equalToConstant: max(btnW, 48)),
            stopButton.heightAnchor.constraint(equalToConstant: 32),

            appendButton.centerYAnchor.constraint(equalTo: startButton.centerYAnchor),
            appendButton.leadingAnchor.constraint(equalTo: stopButton.trailingAnchor, constant: 8),
            appendButton.widthAnchor.constraint(equalToConstant: max(btnW, 48)),
            appendButton.heightAnchor.constraint(equalToConstant: 32),

            onceButton.centerYAnchor.constraint(equalTo: startButton.centerYAnchor),
            onceButton.leadingAnchor.constraint(equalTo: appendButton.trailingAnchor, constant: 8),
            onceButton.widthAnchor.constraint(equalToConstant: max(btnW, 48)),
            onceButton.heightAnchor.constraint(equalToConstant: 32),
            ])
    }

    private func setupStreamTextView() {
        streamTextView = MMarkStreamTextView()
        var style = MMarkStyleConfiguration.defaultStyle

        // 1. 有序列表左侧序号 — 棕色
        style.orderedListStyle.textColor = .brown

        // 2. 无序列表图标 — 一级实心圆，二级及以上空心圆
        style.unorderedListStyle.mode = .image
        style.unorderedListStyle.image = UIImage(named: "solid_circle")
        style.unorderedListStyle.secondaryImage = UIImage(named: "hollow_circle")

        // 3. 任务列表图标 — 已完成 selected，未完成 unselected
        style.taskListStyle.mode = .image
        style.taskListStyle.checkedImage = UIImage(named: "selected")
        style.taskListStyle.uncheckedImage = UIImage(named: "unselected")

        streamTextView.styleConfiguration = style
        streamTextView.streamDelegate = self
        streamTextView.translatesAutoresizingMaskIntoConstraints = false
        streamTextView.layer.borderColor = UIColor.systemGray5.cgColor
        streamTextView.layer.borderWidth = 1
        streamTextView.layer.cornerRadius = 8
        view.addSubview(streamTextView)

        let margin: CGFloat = 16
        NSLayoutConstraint.activate([
            streamTextView.topAnchor.constraint(equalTo: startButton.bottomAnchor, constant: 8),
            streamTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            streamTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),
            streamTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -margin),
        ])
    }

    private func setupSpeedControls() {
        speedLabel.text = String(format: "Speed: %.3fs", speedSlider.value)
        chunkLabel.text = "Chunk: \(Int(chunkSlider.value))"
    }

    // MARK: - Actions

    @objc private func didTapStart() {
        updateStreamConfig()
        streamTextView.startStreaming(markdown: sampleMarkdown)
    }

    @objc private func didTapPause() {
        streamTextView.pauseStreaming()
    }

    @objc private func didTapResume() {
        streamTextView.resumeStreaming()
    }

    @objc private func didTapStop() {
        streamTextView.stopStreaming()
    }

    @objc private func didTapAppend() {
        streamTextView.appendStreamContent(sampleMarkdown)
    }

    @objc private func didTapOnce() {
        updateStreamConfig()
        streamTextView.renderComplete(sampleMarkdown)
    }

    @objc private func speedChanged() {
        speedLabel.text = String(format: "Speed: %.3fs", speedSlider.value)
    }

    @objc private func chunkChanged() {
        chunkLabel.text = "Chunk: \(Int(chunkSlider.value))"
    }

    private func updateStreamConfig() {
        streamTextView.typingSpeed = TimeInterval(speedSlider.value)
        streamTextView.chunkSize = Int(chunkSlider.value)
    }

    /// Format progress state for display
    private func stateText(_ state: MMarkStreamTextView.StreamState) -> String {
        switch state {
        case .idle:      return "Idle"
        case .streaming: return "Streaming"
        case .paused:    return "Paused"
        case .stopped:   return "Stopped"
        }
    }
}

// MARK: - MMarkStreamDelegate

@available(iOS 15.0, *)
extension StreamViewController: MMarkStreamDelegate {

    func onSizeChange(_ size: CGSize) {
        // Auto-scroll to bottom
        let offsetY = streamTextView.contentSize.height - streamTextView.bounds.height
        if offsetY > 0 {
            streamTextView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: false)
        }
    }

    func didChangeState(_ state: MMarkStreamTextView.StreamState) {
        progressLabel.text = "\(stateText(state))  |  Displayed: \(streamTextView.displayedLength)/\(streamTextView.totalLength)"
    }

    func didFinishStreaming() {
        progressLabel.text = "Finished!  |  Total: \(streamTextView.totalLength) chars"
    }
}
