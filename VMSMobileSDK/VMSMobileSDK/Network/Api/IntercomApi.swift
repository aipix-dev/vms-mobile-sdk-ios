
import Foundation
import Alamofire

public protocol IntercomApi {
    
    func getIntercomsList(page: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSIntercom>>)
    func getIntercomCodesList(page: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSIntercomCode>>)
    func getIntercomEventsList(page: Int, request: VMSIntercomFaceRecognitionRequest, completion: @escaping VMSResultBlock<PaginatedResponse<VMSEvent>>)
    func getIntercomCallsList(page: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSIntercomCall>>)
    
    func getActivateCode(completion: @escaping VMSResultBlock<VMSActivationCode>)
    
    func setIntercomFlat(intercomId: Int, flat: Int, completion: @escaping VMSResultBlock<VMSIntercom>)
    
    func renameIntercom(with id: Int, newName: String, completion: @escaping VMSResultBlock<VMSIntercom>)
    func changeIntercomSettings(with id: Int, isEnabled: Bool?, timetable: VMSTimetable?, isLandlineEnabled: Bool?, isAnalogEnabled: Bool?, completion: @escaping VMSResultBlock<VMSIntercom>)
    
    func openDoor(intercomId: Int, completion: @escaping VMSResultBlock<VMSNoReply>)
    
    func createCode(intercomId: Int, name: String, expiredAt: Date, completion: @escaping VMSResultBlock<VMSIntercomCode>)
    
    func deleteIntercoms(with ids: [Int], completion: @escaping VMSResultBlock<VMSNoReply>)
    func deleteIntercomCodes(with ids: [Int], completion: @escaping VMSResultBlock<VMSNoReply>)
    func deleteCalls(with ids: [Int], completion: @escaping VMSResultBlock<VMSNoReply>)
    
    func createFaceRecognitionAnalyticFile(intercomId: Int, request: VMSIntercomFaceRecognitionResourceRequest, completion: @escaping VMSResultBlock<VMSAnalyticFile>)
    func updateIntercomAnalyticFileName(intercomId: Int, fileId: Int, name: String, completion: @escaping VMSResultBlock<VMSAnalyticFile>)
    func deleteIntercomAnalyticFile(intercomId: Int, fileId: Int, completion: @escaping VMSResultBlock<VMSNoReply>)
    func getIntercomAnalyticFiles(page: Int, intercomId: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSAnalyticFile>>)
}

extension VMS: IntercomApi {
    
    public func getIntercomsList(page: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSIntercom>>) {
        
        self.request(
            path: ApiPaths.Intercom.List,
            method: HTTPMethod.get,
            parameters: ["page" : page]
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
    
    public func getIntercomCodesList(page: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSIntercomCode>>) {
        
        self.request(
            path: ApiPaths.Intercom.Codes,
            method: HTTPMethod.get,
            parameters: ["page" : page]
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
    
    public func getIntercomEventsList(
        page: Int,
        request: VMSIntercomFaceRecognitionRequest,
        completion: @escaping VMSResultBlock<PaginatedResponse<VMSEvent>>
    ) {
        
        var params: Parameters = [
            "page" : page
//            "sort": "created_at",
//            "dir": request.sortDirection.rawValue
        ]
        if let timePeriod = request.timePeriod {
            switch timePeriod {
            case .specific(let period):
                params["timezone"] = TimeZone.current.identifier
                params["date"] = period.rawValue
            case .setManualy(let from, let to):
                params["from"] = serverDateFormatter.string(from: from)
                params["to"] = serverDateFormatter.string(from: to)
            }
        }
        
        self.request(
            path: ApiPaths.Intercom.Events,
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
    
    public func getIntercomCallsList(page: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSIntercomCall>>) {
        
        self.request(
            path: ApiPaths.Intercom.Calls,
            method: .get,
            parameters: ["page" : page]
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
    
    public func getActivateCode(completion: @escaping VMSResultBlock<VMSActivationCode>) {
        
        self.request(
            path: ApiPaths.Intercom.List,
            method: .post
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
    
    public func setIntercomFlat(intercomId: Int, flat: Int, completion: @escaping VMSResultBlock<VMSIntercom>) {
        
        let params: Parameters = [
            "flat" : "\(flat)"
        ]
        self.request(
            path: ApiPaths.Intercom.flat(id: intercomId),
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
    
    public func renameIntercom(with id: Int, newName: String, completion: @escaping VMSResultBlock<VMSIntercom>) {
        
        let params: Parameters = [
            "title" : newName
        ]
        
        self.request(
            path: ApiPaths.Intercom.patch(id: id),
            method: .patch,
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
    
    public func openDoor(intercomId: Int, completion: @escaping VMSResultBlock<VMSNoReply>) {
        
        self.request(
            path: ApiPaths.Intercom.openDoor(id: intercomId),
            method: .post
        ) { (response: VMSApiResult<Any>) in
            switch response {
            case .success:
                completion(.success(VMSNoReply()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func createCode(intercomId: Int, name: String, expiredAt: Date, completion: @escaping VMSResultBlock<VMSIntercomCode>) {
        
        let params: Parameters = [
            "title" : name,
            "expired_at" : serverDateFormatter.string(from: expiredAt)
        ]
        self.request(
            path: ApiPaths.Intercom.code(id: intercomId),
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
    
    public func deleteIntercoms(with ids: [Int], completion: @escaping VMSResultBlock<VMSNoReply>) {
        
        let params: Parameters = [
            "ids" : ids
        ]
        self.request(
            path: ApiPaths.Intercom.List,
            method: .delete,
            parameters: params
        ) { (response: VMSApiResult<Any>) in
            switch response {
            case .success:
                completion(.success(VMSNoReply()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func deleteIntercomCodes(with ids: [Int], completion: @escaping VMSResultBlock<VMSNoReply>) {
        
        let params: Parameters = [
            "ids" : ids
        ]
        
        self.request(
            path: ApiPaths.Intercom.Codes,
            method: .delete,
            parameters: params
        ) { (response: VMSApiResult<Any>) in
            switch response {
            case .success:
                completion(.success(VMSNoReply()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func deleteCalls(with ids: [Int], completion: @escaping VMSResultBlock<VMSNoReply>) {
        
        let params = [
            "ids" : ids
        ]
        
        self.request(
            path: ApiPaths.Intercom.Calls,
            method: .delete,
            parameters: params
        ) { (response: VMSApiResult<Any>) in
            switch response {
            case .success:
                completion(.success(VMSNoReply()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func changeIntercomSettings(with id: Int, isEnabled: Bool?, timetable: VMSTimetable?, isLandlineEnabled: Bool?, isAnalogEnabled: Bool?, completion: @escaping VMSResultBlock<VMSIntercom>) {
        
        var params: Parameters = [:]
        if let isEnabled {
            params["is_enabled"] = isEnabled
        }
        
        if let timetable = timetable {
            params["timetable"] = timetable.toJSON()
        }
        if let isLandlineEnabled {
            params["is_landline_sip_line_available"] = isLandlineEnabled
        }
        if let isAnalogEnabled {
            params["is_analog_line_available"] = isAnalogEnabled
        }
        self.request(
            path: ApiPaths.Intercom.patch(id: id),
            method: .patch,
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
    
    public func createFaceRecognitionAnalyticFile(intercomId: Int, request: VMSIntercomFaceRecognitionResourceRequest, completion: @escaping VMSResultBlock<VMSAnalyticFile>) {
        let params: Parameters = [
            "name": request.name,
            "type": request.type
        ]
        self.uploadRequest(
            path: ApiPaths.Intercom.intercomAnalyticFile(id: intercomId),
            data: request.image,
            name: request.name,
            params: params
        ) { [weak self] response in
            switch response {
            case .success(let data):
                guard let self else { return }
                completion(self.decode(data: data))
            case .failure(let error):
                completion(.failure(error))
            }
        } 
    }
    
    public func updateIntercomAnalyticFileName(intercomId: Int, fileId: Int, name: String, completion: @escaping VMSResultBlock<VMSAnalyticFile>) {
        let params: Parameters = [
            "name": name
        ]
        self.request(
            path: ApiPaths.Intercom.updateAnalyticFile(intercomId: intercomId, fileId: fileId),
            method: .post,
            parameters: params
        ) { [weak self] (response) in
            switch response {
            case .success(let object):
                guard let self else { return }
                completion(self.decode(data: object))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func deleteIntercomAnalyticFile(intercomId: Int, fileId: Int, completion: @escaping VMSResultBlock<VMSNoReply>) {
        let params: Parameters = [
            "resources": [fileId],
            "force": true
        ]
        self.request(
            path: ApiPaths.Intercom.intercomAnalyticFile(id: intercomId),
            method: .delete,
            parameters: params
        ) { (response) in
            switch response {
            case .success:
                completion(.success(VMSNoReply()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func getIntercomAnalyticFiles(page: Int, intercomId: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSAnalyticFile>>) {
        self.request(
            path: ApiPaths.Intercom.intercomAnalyticFile(id: intercomId),
            method: .get,
            parameters: ["page" : page]
        ) { [weak self] (response) in
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
