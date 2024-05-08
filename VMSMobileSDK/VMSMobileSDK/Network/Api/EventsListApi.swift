
import Foundation
import Alamofire

public protocol EventsListApi {
    
    func getCamerasWithAnalytics(page: Int, search: String?, completion: @escaping VMSResultBlock<PaginatedResponse<VMSCamera>>)
    
    func getEventsSystem(page: Int, request: VMSEventsRequest, completion: @escaping VMSResultBlock<PaginatedResponse<VMSEvent>>)
    
    func getEventsMarks(page: Int, request: VMSEventsRequest, completion: @escaping VMSResultBlock<PaginatedResponse<VMSEvent>>)
    
    func getEventsAnalytic(page: Int, request: VMSEventsAnalyticRequest, completion: @escaping VMSResultBlock<PaginatedResponse<VMSEvent>>)
    
    func getEventsAnalyticCases(page: Int, analyticCasesTypes: [String], completion: @escaping  VMSResultBlock<PaginatedResponse<VMSAnalyticCase>>)
}

extension VMS: EventsListApi {
    
    public func getCamerasWithAnalytics(
        page: Int,
        search: String?,
        completion: @escaping VMSResultBlock<PaginatedResponse<VMSCamera>>
    ) {
        var params: Parameters = [
            "page" : page,
            "filter": "analytics"
        ]
        if let search = search, !search.isEmpty {
            params["search"] = search
        }
        self.request(
            path: ApiPaths.Cameras.List,
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
    
    public func getEventsSystem(
        page: Int,
        request: VMSEventsRequest,
        completion: @escaping VMSResultBlock<PaginatedResponse<VMSEvent>>
    ) {
        var params: Parameters = [
            "page" : page,
            "types": request.types,
            "cameras": request.cameraIds,
            "sort": "created_at",
            "dir": request.sortDirection.rawValue
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
            path: ApiPaths.Events.Events,
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
    
    public func getEventsMarks(
        page: Int,
        request: VMSEventsRequest,
        completion: @escaping VMSResultBlock<PaginatedResponse<VMSEvent>>
    ) {
        var params: Parameters = [
            "page" : page,
            "types": request.types,
            "sort": "created_at",
            "dir": request.sortDirection.rawValue
        ]
        if !request.cameraIds.isEmpty {
            params["cameras"] = request.cameraIds
        }
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
            path: ApiPaths.Events.Marks,
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
    
    public func getEventsAnalytic(
        page: Int,
        request: VMSEventsAnalyticRequest,
        completion: @escaping VMSResultBlock<PaginatedResponse<VMSEvent>>
    ) {
        var params: Parameters = [
            "page" : page,
            "events": request.eventNames,
            "analytic_types": request.analyticEventTypes,
            "ids": request.caseIds,
            "cameras": request.cameraIds,
            "sort": "created_at",
            "dir": request.sortDirection.rawValue
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
            path: ApiPaths.Events.AnalyticsEvents,
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
    
    public func getEventsAnalyticCases(page: Int, analyticCasesTypes: [String], completion: @escaping VMSResultBlock<PaginatedResponse<VMSAnalyticCase>>) {
        let params: Parameters = [
            "page" : page,
            "types": analyticCasesTypes
        ]
        self.request(
            path: ApiPaths.Events.AnalyticsCases,
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
