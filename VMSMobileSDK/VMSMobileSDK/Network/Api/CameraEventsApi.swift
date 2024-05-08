
import Foundation
import Alamofire

public protocol CameraEventsApi {
    
    func getCameraEvents(with cameraId: Int, from: Date, to: Date, types: [String]?, completion: @escaping VMSResultBlock<[VMSEvent]>)
    
    func getNearestEvent(with cameraId: Int, from date: Date, types: [String]?, direction: VMSRewindDirection, completion: @escaping VMSResultBlock<VMSRewindEventResponse>)
    
    func createEvent(cameraId: Int, eventName: String, from: Date, completion: @escaping VMSResultBlock<VMSEvent>)
    
    func updateEvent(with id: Int, cameraId: Int, eventName: String, from: Date, completion: @escaping VMSResultBlock<VMSEvent>)
    
    func deleteEvent(with id: Int, cameraId: Int, completion: @escaping VMSResultBlock<VMSNoReply>)
}

extension VMS: CameraEventsApi {
    
    public func getCameraEvents(with cameraId: Int, from: Date, to: Date, types: [String]?, completion: @escaping VMSResultBlock<[VMSEvent]>) {
        let formatter = serverDateFormatter
        let fromString = formatter.string(from: from)
        let toString = formatter.string(from: to)
        
        var params: Parameters = [
            "from": fromString,
            "to" : toString
        ]
        params["types"] = types
        
        self.request(
            path: ApiPaths.Cameras.marks(id: cameraId),
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
    
    public func getNearestEvent(with cameraId: Int, from date: Date, types: [String]?, direction: VMSRewindDirection, completion: @escaping VMSResultBlock<VMSRewindEventResponse>) {
        
        let formatter = serverDateFormatter
        let dateString = formatter.string(from: date)
        
        var params: Parameters = [
            "from": dateString,
            "rewind": direction.rawValue
        ]
        params["types"] = types
        
        self.request(
            path: ApiPaths.Cameras.nearestMark(id: cameraId),
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
    
    public func createEvent(cameraId: Int, eventName: String, from: Date, completion: @escaping VMSResultBlock<VMSEvent>) {
        
        let params: Parameters = [
            "from" : serverDateFormatter.string(from: from),
            "title" : eventName
        ]
        
        self.request(
            path: ApiPaths.Cameras.marks(id: cameraId),
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
    
    public func updateEvent(with id: Int, cameraId: Int, eventName: String, from: Date, completion: @escaping VMSResultBlock<VMSEvent>) {
        
        let params: Parameters = [
            "from" : serverDateFormatter.string(from: from),
            "title" : eventName
        ]
        
        self.request(
            path: ApiPaths.Cameras.accessMark(id: cameraId, bookmarkId: id),
            method: .put,
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
    
    public func deleteEvent(with id: Int, cameraId: Int, completion: @escaping VMSResultBlock<VMSNoReply>) {
        
        self.request(
            path: ApiPaths.Cameras.accessMark(id: cameraId, bookmarkId: id),
            method: .delete
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
