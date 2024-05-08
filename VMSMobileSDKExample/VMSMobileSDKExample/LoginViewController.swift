

import UIKit
import VMSMobileSDK

class LoginViewController: UIViewController {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func loginAction(_ sender: Any?) {
        self.view.endEditing(true)
        
        self.errorLabel.text = nil
        
        let loginRequest = VMSLoginRequest(
            login: usernameTextField.text ?? "",
            password: passwordTextField.text ?? "",
            captcha: nil,
            captchaKey: nil,
            sessionId: nil
        )
        ApiManager.shared.api.login(with: loginRequest) { [weak self] response in
            switch response {
            case .success(let user):
                ApiManager.shared.user = user.user
                ApiManager.shared.userToken = user.accessToken
                ApiManager.shared.getTranslations()
                self?.dismiss(animated: true)
            case .failure(let error):
                self?.errorLabel.text = error.message ?? error.type.description
            }
            
        }
    }

}
