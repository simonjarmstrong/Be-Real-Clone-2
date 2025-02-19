//
//  LogInViewController.swift
//  BeFake App
//
//

import UIKit
import ParseSwift

class LogInViewController: UIViewController {

    @IBOutlet weak var beRealLabel: UILabel!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        beRealLabel.textColor = .white
        

        // Do any additional setup after loading the view.
    }
    
    @IBAction func didTapLogInButton(_ sender: Any) {
        
        guard let username = usernameTextField.text,
              let password = passwordTextField.text,
              !username.isEmpty,
              !password.isEmpty else {
            self.showMissingFieldsAlert()
            return
        }
        
        User.login(username: username, password: password) { [weak self] result in
            switch result {
            case .success(let user):
                    print("Logged in as \(user)")
                NotificationCenter.default.post(name: Notification.Name("login"), object: nil)
            case .failure(let error):
                self?.showUnknownErrorAlert(description: error.localizedDescription)
                
            }
        }
        
    }

    
    private func showUnknownErrorAlert(description: String?) {
        let alertController = UIAlertController(title: "Unable to Log in", message: "LogIn Credentials are incorrect.", preferredStyle: .alert)
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
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "SignUpSegue" {
//            guard let destinationVC = segue.destination as? SignUpViewController else { return }
//            destinationVC.title = "Hello"
//        }
//    }
//    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
