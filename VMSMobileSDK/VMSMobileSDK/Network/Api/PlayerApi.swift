
import Foundation
import Alamofire

public protocol PlayerApi {
    func isNoWiFiConnected() -> Bool
    func getStream(by cameraId: Int, quality: VMSStream.QualityType, completion: @escaping VMSResultBlock<VMSUrlStringResponse>)
    func cancelStreamRequest(by cameraId: Int)
    
    func getArchive(by cameraId: Int, start: Date, completion: @escaping VMSResultBlock<VMSUrlStringResponse>)
    func cancelArchiveRequest(by cameraId: Int)
    
    func getArchiveLink(cameraId: Int, from: Date, to: Date, completion: @escaping VMSResultBlock<VMSNoReply>)
    
    func moveCamera(with id: Int, direction: VMSPTZDirection, completion: @escaping VMSResultBlock<VMSNoReply>)
    func moveCameraHome(with id: Int, completion: @escaping VMSResultBlock<VMSNoReply>)
}

extension VMS: PlayerApi {
    public func isNoWiFiConnected() -> Bool {
        return VMS.isNoWiFiConnection
    }
    
    public func getStream(by cameraId: Int, quality: VMSStream.QualityType, completion: @escaping VMSResultBlock<VMSUrlStringResponse>) {
        let params: Parameters = [
            "type" : quality.rawValue,
            "source" : "rtsp"
        ]
        
        self.request(
            path: ApiPaths.Cameras.streams(id: cameraId),
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
    
    public func cancelStreamRequest(by cameraId: Int) {
        sessionManager.session.getAllTasks { (tasks) in
            tasks.forEach { (task) in
                if task.currentRequest?.url?.absoluteString.contains(self.urlBuilder.build(path: ApiPaths.Cameras.streams(id: cameraId))) == true {
                    task.cancel()
                }
            }
        }
    }
    
    
    public func getArchive(by cameraId: Int, start: Date, completion: @escaping VMSResultBlock<VMSUrlStringResponse>) {
        let params: Parameters = [
            "start" : serverDateFormatter.string(from: start),
            "duration" : 25000,
            "source" : "rtsp"
        ]
        
        self.request(
            path: ApiPaths.Cameras.archive(id: cameraId),
            method: .get,
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
    
    public func cancelArchiveRequest(by cameraId: Int) {
        sessionManager.session.getAllTasks { (tasks) in
            tasks.forEach { (task) in
                if task.currentRequest?.url?.absoluteString.contains(self.urlBuilder.build(path: ApiPaths.Cameras.archive(id: cameraId))) == true {
                    task.cancel()
                }
            }
        }
    }
    
    public func getArchiveLink(cameraId: Int, from: Date, to: Date, completion: @escaping VMSResultBlock<VMSNoReply>) {
        
        let formatter = serverDateFormatter
        let params: Parameters = [
            "from": formatter.string(from: from),
            "to": formatter.string(from: to)
        ]
        self.request(
            path: ApiPaths.Cameras.archiveLink(id: cameraId),
            method: .get,
            parameters: params
        ) { (response: VMSApiResult<Any>) in
            switch response {
            case .success(_):
                completion(.success(VMSNoReply()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func moveCamera(with id: Int, direction: VMSPTZDirection, completion: @escaping VMSResultBlock<VMSNoReply>) {
        let params: Parameters = [
            direction.rawValue : true
        ]
        self.request(
            path: ApiPaths.Cameras.move(id: id),
            method: HTTPMethod.post,
            parameters: params
        ) { (response: VMSApiResult<Any>) in
            switch response {
            case .success(_):
                completion(.success(VMSNoReply()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func moveCameraHome(with id: Int, completion: @escaping VMSResultBlock<VMSNoReply>) {
        self.request(
            path: ApiPaths.Cameras.moveHome(id: id),
            method: HTTPMethod.post
        ) { (response: VMSApiResult<Any>) in
            switch response {
            case .success(_):
                completion(.success(VMSNoReply()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
