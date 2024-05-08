
import Foundation
import Alamofire

extension ApiPaths {
    static let CamerasExisted = "cameras/shows"
    static let IntercomExisted = "intercom/shows"
}

public protocol WidgetApi {
    
    func getWidgetCameras(ids: [String], completion: @escaping VMSResultBlock<[VMSWidgetCamera]>)
    func getWidgetCameraPreviewURL(cameraId: Int, completion: @escaping VMSResultBlock<VMSCameraPreviewResponse>)
    func getWidgetIntercoms(ids: [String], completion: @escaping VMSResultBlock<[VMSWidgetIntercom]>)
}

extension VMS: WidgetApi {
    
    public func getWidgetCameras(ids: [String], completion: @escaping VMSResultBlock<[VMSWidgetCamera]>) {
        
        let params: Parameters = [
            "ids" : ids
        ]
        
        self.request(
            path: ApiPaths.CamerasExisted,
            method: HTTPMethod.get,
            parameters: params
        ) { [weak self] (response: VMSApiResult<Any>) in
            
            switch response {
            case .success(let object):
                guard let self else { return }
                completion(self.decode(data: object))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func getWidgetCameraPreviewURL(cameraId: Int, completion: @escaping VMSResultBlock<VMSCameraPreviewResponse>) {
        
        let params: [String : Any] = ["type" : "mp4"]
        
        self.request(
            path: ApiPaths.Cameras.preview(id: cameraId),
            method: HTTPMethod.get,
            parameters: params
        ) { [weak self] (response: VMSApiResult<Any>) in
            
            switch response {
            case .success(let object):
                guard let self else { return }
                completion(self.decode(data: object))
            case .failure(let error):
                completion(.failure(error))
            }
        }
     }
    
    public func getWidgetIntercoms(ids: [String], completion: @escaping VMSResultBlock<[VMSWidgetIntercom]>) {
        
        let params: Parameters = [
            "ids" : ids
        ]
        
        self.request(
            path: ApiPaths.IntercomExisted,
            method: HTTPMethod.get,
            parameters: params
        ) { [weak self] (response: VMSApiResult<Any>) in
            
            switch response {
            case .success(let object):
                guard let self else { return }
                completion(self.decode(data: object))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
