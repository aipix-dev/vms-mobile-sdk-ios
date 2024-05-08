
import UIKit


class PlayerNoDataView: UIView {
    
    @IBOutlet weak var noDataLabel: UILabel!
    @IBOutlet weak var noDataLabelDescription: UILabel!
    @IBOutlet weak var noDataImageView: UIImageView!
    
    typealias NoDataInfo = (label: String?, description: String?)
    
    public func configureView(info: NoDataInfo, image: UIImage? = nil) {
        self.isHidden = info.label == nil
        noDataLabel.text = info.label
        noDataLabelDescription.text = info.description
        noDataImageView.image = image ?? UIImage(named: "no_data_image", in: Bundle(for: VMSPlayerController.self), with: nil)
    }
    
}
