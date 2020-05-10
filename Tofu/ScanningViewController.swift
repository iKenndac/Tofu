import UIKit
import AVFoundation

class ScanningViewController: UIViewController,
AVCaptureMetadataOutputObjectsDelegate {
    @IBOutlet weak var allowCameraAccessView: UIView!
    var delegate: AccountCreationDelegate?
    private var session = AVCaptureSession()
    private let output = AVCaptureMetadataOutput()
    private var layer: AVCaptureVideoPreviewLayer?
    
    @IBAction func didPressCancel(_ sender: UIBarButtonItem) {
        output.setMetadataObjectsDelegate(nil, queue: nil)
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
            startScanning()
        } else {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                guard granted else { return }
                DispatchQueue.main.async {
                    self.startScanning()
                }
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateLayerFrameAndOrientation()
    }
    
    private func startScanning() {
        if let device = AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: device) {
            allowCameraAccessView.isHidden = true
            navigationItem.prompt = "Point your camera at a QR code to scan it."
            session.addInput(input)
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            output.metadataObjectTypes = [.qr]
            layer = AVCaptureVideoPreviewLayer(session: session)
            layer!.videoGravity = .resizeAspectFill
            view.layer.addSublayer(layer!)
            updateLayerFrameAndOrientation()
            session.startRunning()
        }
    }
    
    private func updateLayerFrameAndOrientation() {
        layer?.frame = view.layer.bounds
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            layer?.connection?.videoOrientation = .landscapeRight
        case .landscapeRight:
            layer?.connection?.videoOrientation = .landscapeLeft
        default:
            layer?.connection?.videoOrientation = .portrait
        }
    }
    
    // MARK: AVCaptureMetadataOutputObjectsDelegate
    
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection) {
        guard metadataObjects.count > 0,
            let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject, metadataObject.type == AVMetadataObject.ObjectType.qr,
            let url = URL(string: metadataObject.stringValue!),
            let account = Account(url: url) else {
                presentingViewController?.dismiss(animated: true) {
                    OperationQueue.main.addOperation {
                        self.delegate?.rejectAccount()
                    }
                }
                return
            }
        output.setMetadataObjectsDelegate(nil, queue: nil)
        delegate?.createAccount(account)
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
