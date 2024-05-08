
import Foundation
import Alamofire

public protocol CameraApi {
    
    func getCamerasTree(search: String?, completion: @escaping VMSResultBlock<[VMSCameraTree]>)
    
    func getSearchCameras(search: String, completion: @escaping VMSResultBlock<[VMSCamera]>)
    func cancelSearchCamerasRequest()
    
    func getCamera(with cameraId: Int, completion: @escaping VMSResultBlock<VMSCamera>)
    func cancelCameraInfoRequest(with cameraId: Int)
    
    func renameCamera(with id: Int, name: String, completion: @escaping VMSResultBlock<VMSCamera>)
    
    func sendReport(info: VMSReportRequest, completion: @escaping VMSResultBlock<VMSNoReply>)
    
    func getCameraPreviewURL(with cameraId: Int, date: String?, completion: @escaping VMSResultBlock<VMSCameraPreviewResponse>)
    func cancelCameraPreviewURLRequest(with cameraId: Int)
    
    func downloadCameraPreviewFile(url: URL, destinationUrl: URL, completionHandler: @escaping ((URL?, Error?) -> Void))
    func cancelDownloadCameraPreviewRequest(url: URL)
}

extension VMS: CameraApi {
    
    // MARK: - Cameras
    
    public func getCamerasTree(search: String?, completion: @escaping VMSResultBlock<[VMSCameraTree]>) {
        
        var params: Parameters = [:]
        
        if let search = search, !search.isEmpty {
            params["search"] = search
        }
        
        self.request(
            path: ApiPaths.Cameras.FlatTree,
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
    
    public func getSearchCameras(search: String, completion: @escaping VMSResultBlock<[VMSCamera]>) {
        let params: Parameters = [
            "search" : search
        ]
        
        self.request(
            path: ApiPaths.Cameras.FlatTree,
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
    
    public func cancelSearchCamerasRequest() {
        sessionManager.session.getAllTasks { (tasks) in
            tasks.forEach { (task) in
                if task.currentRequest?.url?.absoluteString.contains(self.urlBuilder.build(path: ApiPaths.Cameras.FlatTree)) == true {
                    task.cancel()
                }
            }
        }
    }
    
    public func getCamera(with cameraId: Int, completion: @escaping VMSResultBlock<VMSCamera>) {
        
        self.request(
            path: ApiPaths.Cameras.info(id: cameraId),
            method: .get
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
    
    public func cancelCameraInfoRequest(with cameraId: Int) {
        sessionManager.session.getAllTasks { (tasks) in
            tasks.forEach { (task) in
                if task.currentRequest?.url?.absoluteString.contains(self.urlBuilder.build(path: ApiPaths.Cameras.info(id: cameraId))) == true {
                    task.cancel()
                }
            }
        }
    }
    
    public func renameCamera(with id: Int, name: String, completion: @escaping VMSResultBlock<VMSCamera>) {
        
        let params: Parameters = ["name" : name]
        self.request(
            path: ApiPaths.Cameras.rename(id: id),
            method: .post,
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
    
    public func sendReport(info: VMSReportRequest, completion: @escaping VMSResultBlock<VMSNoReply>) {
        
        self.request(
            path: ApiPaths.Cameras.issue(issueId: info.issueId, cameraId: info.cameraId),
            method: .post
        ) { (response: VMSApiResult<Any>) in
            switch response {
            case .success(_):
                completion(.success(VMSNoReply()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func getCameraPreviewURL(with cameraId: Int, date: String?, completion: @escaping VMSResultBlock<VMSCameraPreviewResponse>) {
        
        var params: Parameters = [
            "type" : "mp4"
        ]
        params["date"] = date
        
        self.request(
            path: ApiPaths.Cameras.preview(id: cameraId),
            method: HTTPMethod.get, parameters: params
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
    
    public func cancelCameraPreviewURLRequest(with cameraId: Int) {
        sessionManager.session.getAllTasks { (tasks) in
            tasks.forEach { (task) in
                if task.currentRequest?.url?.absoluteString.contains(self.urlBuilder.build(path: ApiPaths.Cameras.preview(id: cameraId))) == true {
                    task.cancel()
                }
            }
        }
    }
    
    public func downloadCameraPreviewFile(
        url: URL,
        destinationUrl: URL,
        completionHandler: @escaping ((URL?, Error?) -> Void))
    {
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (destinationUrl, [.removePreviousFile])
        }
        sessionManager.download(url, to: destination).response { response in
            completionHandler(response.destinationURL, response.error)
        }
    }
    
    public func cancelDownloadCameraPreviewRequest(url: URL) {
        sessionManager.session.getAllTasks { (tasks) in
            tasks.forEach { (task) in
                if task.currentRequest?.url?.absoluteString == url.absoluteString {
                    task.cancel()
                }
            }
        }
    }
}
