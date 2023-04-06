//
//  ViewController+Extras.swift
//  CustomCamera
//
//  Created by Alex Barbulescu on 2020-05-23.
//  Copyright © 2020 ca.alexs. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import AssetsLibrary

extension ViewController {
    //MARK:- View Setup
    func setupView(){
       view.backgroundColor = .black
       view.addSubview(switchCameraButton)
       view.addSubview(captureImageButton)
       
       NSLayoutConstraint.activate([
           switchCameraButton.widthAnchor.constraint(equalToConstant: 30),
           switchCameraButton.heightAnchor.constraint(equalToConstant: 30),
           switchCameraButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
           switchCameraButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),

           captureImageButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
           captureImageButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
           captureImageButton.widthAnchor.constraint(equalToConstant: 50),
           captureImageButton.heightAnchor.constraint(equalToConstant: 50),
           
       ])
       
       captureImageButton.addTarget(self, action: #selector(captureFrames(_:)), for: .touchUpInside)
    }
    
    //MARK:- Permissions
    func checkCameraPermissions() {
        let cameraAuthStatus =  AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch cameraAuthStatus {
          case .authorized: return
          case .denied: abort()
          case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler:
            { (authorized) in
              if(!authorized) { abort() }
            })
          case .restricted:
            abort()
          @unknown default:
            fatalError()
        }
    }
    
    @available(iOS 14, *)
    func checkPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [unowned self] (status) in
            DispatchQueue.main.async { [unowned self] in
                showUI(for: status)
            }
        }
        
        
//            let status = PHPhotoLibrary.authorizationStatus()
//            switch status {
//            case .authorized: return
//            case .denied, .restricted: abort()
//            case .notDetermined:
//                // ask for permissions
//                PHPhotoLibrary.requestAuthorization { status in
//                    switch status {
//                    case .authorized: return
//                    case .denied, .restricted:
//                        abort()
//                    case .limited:
//                        print("limited")
//                    case .notDetermined:
//                        print("Not Determined")
//                    @unknown default:
//                        fatalError()
//                    }
//                }
//            case .limited:
//                print("limited")
//            @unknown default:
//              fatalError()
//            }
    }
    
    func showUI(for status: PHAuthorizationStatus) {
        switch status {
        case .authorized:
            return
        case .limited:
            return

        case .restricted:
            abort()

        case .denied:
            abort()

        case .notDetermined:
            break

        @unknown default:
            break
        }
    }
    
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
}
