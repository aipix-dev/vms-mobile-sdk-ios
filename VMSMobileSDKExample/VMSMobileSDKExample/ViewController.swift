

import UIKit
import VMSMobileSDK

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var mainTrees: [VMSCameraTree]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.tabBarController?.tabBar.isHidden = false
        
        if ApiManager.shared.userToken == nil {
            performSegue(withIdentifier: "showLogin", sender: nil)
        } else {
            getCameras()
            getSockets()
        }
    }
    
    private func getCameras() {
        ApiManager.shared.api.getCamerasTree(search: nil) { [weak self] response in
            switch response {
            case .success(let result):
                self?.mainTrees = result
                self?.tableView.reloadData()
            case .failure(_):
                break
            }
        }
    }
    
    private func getSockets() {
        ApiManager.shared.api.getSocketUrl { response in
            switch response {
            case .success(let result):
                ApiManager.shared.initSocket(response: result)
            case .failure(_):
                break
            }
        }
    }
    
    private func connectSocket() {
        
    }
    
    private func gotoCamera(camera: VMSCamera, group: [VMSCamera]?) {
        ApiManager.shared.api.getCamera(with: camera.id) { [weak self] response in
            switch response {
            case .success(let camObject):
                guard let user = ApiManager.shared.user,
                    let translations = ApiManager.shared.translations,
                    let language = ApiManager.shared.currentLanguage else {
                    return
                }
                let modelTranslations = VMSPlayerTranslations.init(translations: translations)
                let options = VMSPlayerOptions.init(
                    language: language,
                    allowVibration: true,
                    allowSoundOnStart: true,
                    markTypes: [],
                    videoRates: [0.5, 1.0, 2.0, 4.0, 8.0],
                    defaultPlayerType: .rtspH264
                )
                
                let model = VMSPlayerViewModel(
                    camera: camObject,
                    groupCameras: nil,
                    user: user,
                    translations: modelTranslations,
                    playerApi: ApiManager.shared.api,
                    options: options
                )
                let openOptions = VMSOpenPlayerOptions(
                    event: nil,
                    archiveDate: nil,
                    showEventEdit: false,
                    popNavigationAfterEventEdit: false,
                    pushEventsListAfterEventEdit: false,
                    openPlayerType: .live,
                    markOptions: nil,
                    isLiveRestricted: (camera.isRestrictedLive ?? false)
                )
                let vc = VMSPlayerController.initialization(viewModel: model, delegate: self, openOptions: openOptions)
                self?.navigationController?.pushViewController(vc, animated: true)
            case .failure(_):
                break
            }
        }
    }
    
    @IBAction func logout(_ sender: Any?) {
        ApiManager.shared.api.logout { [weak self] response in
            switch response {
            case .success(_):
                ApiManager.shared.pusher?.disconnect()
                self?.performSegue(withIdentifier: "showLogin", sender: nil)
            case .failure(_):
                break
            }
        }
    }

}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return mainTrees?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard mainTrees?.count ?? 0 > section else {
            return 0
        }
        return mainTrees?[section].cameras.count ?? 0
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let camera = mainTrees?[indexPath.section].cameras[indexPath.row] else {
            return UITableViewCell()
        }
        let cell = UITableViewCell()
        var content = UIListContentConfiguration.cell()
        content.text = camera.name
        content.secondaryText = camera.prettyText
        cell.contentConfiguration = content
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard let camera = mainTrees?[indexPath.section].cameras[indexPath.row] else {
            return
        }
        gotoCamera(camera: camera, group: mainTrees?[indexPath.section].cameras)
    }
    
}

extension ViewController: VMSPlayerDelegate {
    func playerTypeChanged(type: VMSMobileSDK.VMSPlayerOptions.VMSPlayerType) {
        
    }
    
    
    func isUserAllowForNet() {
        
    }
    
    
    func logPlayerEvent(event: String) {
        print("Player event: \(event)")
    }
    
    func gotoEventsList(camera: VMSCamera) {
        
    }
    
    func screenshotCreated(image: UIImage, cameraName: String, date: Date) {
        
    }
    
    func playerDidReceiveError(message: String) {
        
    }
    
    func dismissPlayerErrors() {
        
    }
    
    func playerDidEnd() {
        print("")
    }
    
    func playerDidAppear() {
        print("")
    }
    
}
