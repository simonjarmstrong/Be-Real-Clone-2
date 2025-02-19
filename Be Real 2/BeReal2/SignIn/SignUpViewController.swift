//
//  SignUpViewController.swift
//  BeFake App
//
//

import UIKit

class SignUpViewController: UIViewController {

    @IBOutlet weak var usernameLabel: UITextField!
    @IBOutlet weak var emailLabel: UITextField!
    @IBOutlet weak var passwordLabel: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        // Do any additional setup after loading the view.
        
    }
    
    @IBAction func didTapSignUpButton(_ sender: Any) {
        
        guard let username = usernameLabel.text,
                let email = emailLabel.text,
                let password = passwordLabel.text,
              !username.isEmpty,
              !email.isEmpty,
              !password.isEmpty
        else {
            self.showMissingFieldsAlert()
            return
        }
        
        var newUser = User()
        newUser.username = username
        newUser.password = password
        newUser.email = email
 
        newUser.signup { [weak self] result in
            switch result {
            case .success(let user):
                print("User has been signed up \(user)")
                let userInitials = self?.extractInitials(from: username) ?? ""
                
                newUser.userInitials = userInitials
                NotificationCenter.default.post(name: Notification.Name("login"), object: nil)
            case .failure(let error):
                print("SignUp Failed")
            
            }
        }
        
        
    }
    private func extractInitials(from username: String) -> String {
            let words = username.split(separator: " ")
            
            let initials = words.compactMap { $0.first }
            
            let firstTwoInitials = initials.prefix(2)
            
            let capitalizedInitials = firstTwoInitials.map { String($0).uppercased() }
            
            return capitalizedInitials.joined()
    }
    

    
    private func showUnknownErrorAlert(description: String?) {
        let alertController = UIAlertController(title: "Unable to Sign Up", message: "Account already exists with this username. Use a different username.", preferredStyle: .alert)
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
