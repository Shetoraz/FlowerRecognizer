//
//  ViewController.swift
//  coremlWork
//
//  Created by Anton Asetski on 11/27/19.
//  Copyright © 2019 Anton Asetski. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var discriptionField: UITextView!
    @IBOutlet weak var nameLabel: UILabel!
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupImagePicker()
        
    }
    
    @IBAction func cameraButtonPressed(_ sender: UIBarButtonItem) {
        present(imagePicker,animated: true)
    }
    
    func setupImagePicker() {
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let pickedImage = info[.originalImage] as? UIImage else { return }
        guard let ciiImage = CIImage(image: pickedImage) else { print ("Converting to CII problem"); return}
        detect(image: ciiImage)
        getWiki()
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(image: CIImage) {
        
        guard let model = try? VNCoreMLModel(for: ObjectClassifier().model) else { print("Loading Model Error"); return }
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let result = request.results as? [VNClassificationObservation] else { print("Error model processing"); return }
            if let firstPredict = result.first {
                self.navigationItem.prompt = firstPredict.identifier.capitalized
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    func getWiki() {
        guard let title = navigationItem.prompt?.replacingOccurrences(of: " ", with: "%20") else { return }
        let url = "https://en.wikipedia.org/api/rest_v1/page/summary/\(title)"
        Alamofire.request(url, method: .get).responseJSON { result in
            guard let data = result.data else { print("API error"); return }
            
            DispatchQueue.global(qos: .background).async {
                let json = JSON(data)
                let discription = json["extract"].stringValue
                let title = json["title"].stringValue
                let imageURL = json["thumbnail"]["source"].stringValue
                DispatchQueue.main.async {
                    self.imageView.sd_setImage(with: URL(string: imageURL))
                    self.discriptionField.text = discription
                    self.nameLabel.text = title
                }
            }
            
        }
    }
    
}


