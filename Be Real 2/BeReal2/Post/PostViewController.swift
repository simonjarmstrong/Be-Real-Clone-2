//
//  PostViewController.swift
//  BeFake App
//
//

import UIKit
import PhotosUI
import ParseSwift
import CoreLocation

class PostViewController: UIViewController{
    

    private var locationManager = CLLocationManager()
    @IBOutlet weak var captionTextField: UITextField!
    
    @IBOutlet weak var postImageView: UIImageView!
    
    private var imagePicked: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        // Do any additional setup after loading the view.
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    @IBAction func didTapOpenCamera(_ sender: Any) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            return
        }

        let imagePicker = UIImagePickerController()

        imagePicker.sourceType = .camera


        imagePicker.allowsEditing = true

        imagePicker.delegate = self

        present(imagePicker, animated: true)
    }
    
    @IBAction func didTapPostButton(_ sender: Any) {
        view.endEditing(true)
        
        guard let image = imagePicked,
        let imageData = image.jpegData(compressionQuality: 0.1)
        else {
            return
        }
        
        let imageFile = ParseFile(name: "image1.jpg", data: imageData)
        
        var post = Post()
        post.image = imageFile
        post.caption = captionTextField.text
        post.user = User.current
        
        if let location = locationManager.location {
            do {
                let geoPoint = try ParseGeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                post.locationCoordinates = geoPoint
            } catch {
    
                post.locationCoordinates = nil
                print("Error capturing location: \(error)")
            }
        } else {
            post.locationCoordinates = nil
        }

        
        post.save { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let savedPost):
                    print("Saved post successfuly: \(savedPost)")
                    
                    if var currentUser = User.current {

                        currentUser.lastAdded = Date()

                        currentUser.save { [weak self] result in
                            switch result {
                            case .success:

                                DispatchQueue.main.async {
        
                                    self?.navigationController?.popViewController(animated: true)
                                }

                            case .failure(let error):
                                self?.showUnknownErrorAlert(description: error.localizedDescription)
                            }
                        }
                    }
        
                case .failure(let error):
                    self?.showUnknownErrorAlert(description: error.localizedDescription)
                
                }
            }
        }
        
    }
    
    @IBAction func didTapSelectPhotoButton(_ sender: Any) {
        if PHPhotoLibrary.authorizationStatus(for: .readWrite) != .authorized {
            PHPhotoLibrary.requestAuthorization { [weak self ] status in
                switch status {
                case .authorized:
                    DispatchQueue.main.async {
                        self?.presentPhotoPicker()
                    }
                default:
                    self?.presentGoToSettingsAlert()
                }
            }
        }
        else{
            presentPhotoPicker()
        }
        
        
        
    }
    private func presentGoToSettingsAlert() {
        let alert = UIAlertController(title: "Photos Access Required", message: "Please go to Settings > Privacy > Photos to allow this app to access your photos.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    private func presentPhotoPicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        config.preferredAssetRepresentationMode = .compatible
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    

    private func showUnknownErrorAlert(description: String?) {
        let alertController = UIAlertController(title: "Unable to Sign Up", message: description ?? "An unknown error occurred.", preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(alertAction)
        present(alertController, animated: true)
    }
    
    private func showMissingFieldsAlert() {
        let alertController = UIAlertController(title: "Missing Fields", message: "Please fill in all fields", preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(alertAction)
        present(alertController, animated: true)
    }
    
    
    @IBAction func didTapViewArea(_ sender: Any) {
        view.endEditing(true)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension PostViewController: PHPickerViewControllerDelegate, CLLocationManagerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true)

        guard let image = info[.editedImage] as? UIImage else {
            return
        }

        postImageView.image = image

        imagePicked = image
       
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else {
            print("Got Error 1: Cannot load image from picker.")
            self.showUnknownErrorAlert(description: "Failed to load image. Try again.")
            return
        }

        provider.loadObject(ofClass: UIImage.self) { [weak self] obj, error in
            // First, check if there's an error
            if let error = error {
                print("Got Error 2: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.showUnknownErrorAlert(description: error.localizedDescription)
                }
                return
            }

            // Ensure the object is a UIImage
            guard let image = obj as? UIImage else {
                print("Got Error 3: Failed to convert object to UIImage.")
                DispatchQueue.main.async {
                    self?.showUnknownErrorAlert(description: "Selected file is not an image.")
                }
                return
            }

            // Convert image to data and back to avoid loading issues
            if let imageData = image.jpegData(compressionQuality: 1.0),
               let processedImage = UIImage(data: imageData) {
                DispatchQueue.main.async {
                    print("Image successfully selected and processed.")
                    self?.postImageView.image = processedImage
                    self?.imagePicked = processedImage
                }
            } else {
                print("Got Error 4: Could not process image.")
                DispatchQueue.main.async {
                    self?.showUnknownErrorAlert(description: "Could not process selected image.")
                }
            }
        }
    }
}
