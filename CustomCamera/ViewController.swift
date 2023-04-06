//
//  ViewController.swift
//  CustomCamera
//
//  Created by Alex Barbulescu on 2020-05-21.
//  Copyright © 2020 ca.alexs. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary
import Photos

class ViewController: UIViewController {
    //MARK:- Vars
    var captureSession : AVCaptureSession!
    var backCamera : AVCaptureDevice!
    var frontCamera : AVCaptureDevice!
    var previewLayer : AVCaptureVideoPreviewLayer!
    var videoOutput : AVCaptureVideoDataOutput!
    private let cameraQueue = DispatchQueue(label: "com.swiftgrade.CapturingModelQueue")
    var takePicture = false
    
    var lastSampleDate = Date.distantPast
    let sampleInterval: TimeInterval = 1 // 1 seconds
    var countFrames = 0
    var frames: [UIImage]? = nil
    
    //MARK:- View Components
    let switchCameraButton : UIButton = {
        let button = UIButton()
      //  let image = UIImage(named: "switchcamera")?.withRenderingMode(.alwaysTemplate)
      //  button.setImage(image, for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let captureImageButton : UIButton = {
        let button = UIButton()
        button.backgroundColor = .white
        button.tintColor = .white
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
        
    let openCVWrapper = OpenCVWrapper()
    
    //MARK:- Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        openCVWrapper.isThisWorking()
        setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkCameraPermissions()
        if #available(iOS 14, *) {
            checkPhotoLibraryPermission()
        } else {
            // Fallback on earlier versions
        }
        setupAndStartCaptureSession()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopSession()
    }
    
    //MARK:- Camera Setup
    func setupAndStartCaptureSession(){
        DispatchQueue.global(qos: .userInitiated).async{
            //init session
            self.captureSession = AVCaptureSession()
            //start configuration
            self.captureSession.beginConfiguration()
            
            //session specific configuration
            if self.captureSession.canSetSessionPreset(.hd4K3840x2160) {
                self.captureSession.sessionPreset = .hd4K3840x2160
            }
            self.captureSession.automaticallyConfiguresCaptureDeviceForWideColor = true
            
            //setup inputs
            self.setupInputs()
            
            DispatchQueue.main.async {
                //setup preview layer
                self.setupPreviewLayer()
            }
            
            //setup output
            self.setupOutput()
            
            //commit configuration
            self.captureSession.commitConfiguration()
            //start running it
            self.startSession()
           
        }
    }
    
    func startSession() {
    cameraQueue.async { [weak self] in
        self?.captureSession.startRunning()
    }
 
    }
    func stopSession() {
        cameraQueue.async { [weak self] in
            self?.captureSession.stopRunning()
        }
        
    }
    
    func setupInputs(){
        //get back camera
        guard let captureDevice = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInTripleCamera, .builtInDualWideCamera, .builtInDualCamera, .builtInWideAngleCamera],
            mediaType: .video,
            position: .back).devices.first else {
            fatalError("No back camera device found!")
        }
        backCamera = captureDevice
         
        //now we need to create an input objects from our devices
        guard let bInput = try? AVCaptureDeviceInput(device: backCamera) else {
            fatalError("could not create input device from back camera")
        }
        //connect back camera input to session
        captureSession.addInput(bInput)
    
        do {
            try captureDevice.lockForConfiguration()
            if captureDevice.isFocusModeSupported(.autoFocus) {
               captureDevice.focusMode = .continuousAutoFocus
            }
            if captureDevice.isExposureModeSupported(.continuousAutoExposure) {
               captureDevice.exposureMode = .continuousAutoExposure
            }
            if captureDevice.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
               captureDevice.whiteBalanceMode = .continuousAutoWhiteBalance
            }
            
            captureDevice.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 30)
            captureDevice.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: 30)
            
            captureDevice.unlockForConfiguration()
        } catch {
            print(error.localizedDescription)
        }
        
     }
    
    func setupOutput(){
        videoOutput = AVCaptureVideoDataOutput()
        let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInteractive)
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            fatalError("could not add video output")
        }
        
        videoOutput.connections.first?.videoOrientation = .portrait
    }
    
    func setupPreviewLayer(){
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.insertSublayer(previewLayer, below: switchCameraButton.layer)
        previewLayer.frame = self.view.layer.frame
    }
    
    //MARK:- Actions
    @objc func captureFrames(_ sender: UIButton?){
        frames = nil
        countFrames = 0
        takePicture = true
        lastSampleDate = Date()
        print("-- capture start = \(lastSampleDate)")
    }
    

}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if !takePicture { return }
    //    print("timeIntervalSinceNow = \(lastSampleDate.timeIntervalSinceNow)")
        
        let currentDate = Date()
        if (currentDate.timeIntervalSince(lastSampleDate) >= 1.0) {
            self.takePicture = false
            print("-- capture finish = \(currentDate)")
            print("-- countFrames = \(countFrames)")
           
            return
        }
        //try and get a CVImageBuffer out of the sample buffer
        guard let cvBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        //get a CIImage out of the CVImageBuffer
        let ciImage = CIImage(cvImageBuffer: cvBuffer)
        //get UIImage out of CIImage
        let uiImage = UIImage(ciImage: ciImage)
        frames?.append(uiImage)
        countFrames += 1
  
        print("countFrames = \(countFrames)")
       // print("Blur frame? = \(openCVWrapper.isImageBlurry(uiImage))")
        print("Blur frame? = \(openCVWrapper.check(forBlurryImage: uiImage))")
        
        
        let resultImage = openCVWrapper.check(forBlurryImage: uiImage)
        UIImageWriteToSavedPhotosAlbum(resultImage, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
 
}
