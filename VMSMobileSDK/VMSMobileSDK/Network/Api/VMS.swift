
import Foundation
import Alamofire

public protocol VMSDelegate: AnyObject {
    
    /// Handle errors that happened in VMSMobileSDK
    /// Additionally errors 400, 403, 404, 422 and 419 can be handled inside api request methods in completion handlers
    func apiDidReceiveError(_ error: VMSApiError, request: VMSRequest)
    
    func apiRequestSucceed(_ request: VMSRequest)
}

/// Responsible for creating main entry point for working with `VMSMobileSDK` and  making requests
/// Use `Alamofire` framework to work
open class VMS {
    
    open var headersBuilder: HeadersBuilder
    open var urlBuilder: URLBuilder
    
    /// Return true if Alamofire NetworkReachabilityManager is reachable
    static var isConnected: Bool {
        return NetworkReachabilityManager()!.isReachable
    }
    
    /// Return true if Alamofire NetworkReachabilityManager is eachable on WWAN and is not reachable in Ethernet or WiFi
    static var isNoWiFiConnection: Bool {
        return NetworkReachabilityManager()!.isReachableOnWWAN && !NetworkReachabilityManager()!.isReachableOnEthernetOrWiFi
    }
    
    open var sessionManager: SessionManager = {
        let conf = URLSessionConfiguration.default
        conf.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        return SessionManager(
            configuration: conf,
            serverTrustPolicyManager: nil
        )
    }()
    
    private var decoder: JSONDecoder
    
    public weak var delegate: VMSDelegate?
    
    open var serverDateFormatter: DateFormatter = DateFormatter.serverUTC
    
    private var currentDownloadRequest: DownloadRequest?
    
    /// Initialize SDK to work with api
    /// 
    /// - parameter baseUrl: Should be a string of type `https://example.com`
    ///
    /// - parameter language: current language. Available options can be received from `VMSBasicStatic` object
    /// 
    /// - parameter accessToken: if user already login set this parameter. Otherwise it will be set by VMSMobileSDK after successfull login
    public init(baseUrl: String, language: String?, accessToken: String?) {
        self.headersBuilder = HeadersBuilderImpl(language: language, accessToken: accessToken)
        self.urlBuilder = URLBuilderImpl(baseUrl: baseUrl)
        
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    public func setLanguage(_ language: String) {
        self.headersBuilder.setLanguage(language)
    }
    
    public func getLanguage() -> String {
        return self.headersBuilder.getLanguage()
    }
    
    public func setSocketId(socketId: String?) {
        self.headersBuilder.setSocketId(socketId)
    }
    
    @discardableResult
    open func request(
        url: String,
        method: Alamofire.HTTPMethod,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding? = nil,
        completion: @escaping VMSResultDataBlock
    ) -> DataRequest? {
        
        if !VMS.isConnected {
            let failedRequest = VMSRequest(url: url, method: method, parameters: parameters, completion: completion)
            self.delegate?.apiDidReceiveError(.init(statusCode: nil, type: .noConnection), request: failedRequest)
            return nil
        }
        
        let request = sessionManager.request(
            url,
            method: method,
            parameters: parameters,
            encoding: encoding ?? VMS.encoding(for: method),
            headers: headersBuilder.getHeaders())
        .validate().responseJSON { [weak self] response in
            
                
            switch response.result {
            case .success(let data):
                
                let request = VMSRequest(url: url, method: method, parameters: parameters, completion: completion)
                self?.delegate?.apiRequestSucceed(request)
                
                completion(.success(data))
                
            case .failure(let error):
                
                let failedRequest = VMSRequest(url: url, method: method, parameters: parameters, completion: completion)
                
                let er = error as NSError
                if er.code == NSURLErrorCancelled {
                    self?.delegate?.apiDidReceiveError(VMSApiError.init(statusCode: nil, type: .requestCanceled, message: "\(response.request?.url?.absoluteString ?? "Unknown") request was canceled"), request: failedRequest)
                    return
                }
                
                var errorString: String? = nil
                if let responseData = response.data {
                    errorString = self?.getErrorFromData(data: responseData)
                }
                
                if let statusCode = response.response?.statusCode {
                    
                    switch statusCode {
                    case 401:
                        self?.delegate?.apiDidReceiveError(VMSApiError(statusCode: statusCode, type: .unathorised), request: failedRequest)
                    case 403:
                        let apiError = VMSApiError(statusCode: statusCode, type: .forbidden)
                        self?.delegate?.apiDidReceiveError(apiError, request: failedRequest)
                        completion(.failure(apiError))
                    case 404:
                        let apiError = VMSApiError(statusCode: statusCode, type: .notFound)
                        self?.delegate?.apiDidReceiveError(apiError, request: failedRequest)
                        completion(.failure(apiError))
                    case 409:
                        self?.delegate?.apiDidReceiveError(VMSApiError(statusCode: statusCode, type: .forceUpdate), request: failedRequest)
                    case 419:
                        var sessions: VMSSessionResponse? = nil
                        if let data = response.data {
                            sessions = try? self?.decoder.decode(VMSSessionResponse.self, from: data)
                        }
                        let apiError = VMSApiError(statusCode: statusCode, type: .sessionExpired(sessions), message: errorString)
                        self?.delegate?.apiDidReceiveError(apiError, request: failedRequest)
                        completion(.failure(apiError))
                    case 429:
                        self?.delegate?.apiDidReceiveError(VMSApiError(statusCode: statusCode, type: .requestLimit), request: failedRequest)
                    case 503:
                        self?.delegate?.apiDidReceiveError(VMSApiError(statusCode: statusCode, type: .technical), request: failedRequest)
                    case 400, 422:
                        var serverError: VMSServerError? = nil
                        if let responseData = response.data {
                            serverError = try? self?.decoder.decode(VMSServerError.self, from: responseData)
                        }
                        let apiError = VMSApiError(statusCode: statusCode, type: .incorrectData(serverError), message: errorString)
                        self?.delegate?.apiDidReceiveError(apiError, request: failedRequest)
                        completion(.failure(apiError))
                    case 500...502, 504...600:
                        self?.delegate?.apiDidReceiveError(VMSApiError(statusCode: statusCode, type: .serverError, message: errorString), request: failedRequest)
                    default:
                        self?.delegate?.apiDidReceiveError(VMSApiError(statusCode: statusCode, type: .unknown, message: errorString), request: failedRequest)
                    }
                } else {
                    self?.delegate?.apiDidReceiveError(VMSApiError(statusCode: nil, type: .unknown, message: errorString), request: failedRequest)
                    let apiError = VMSApiError(statusCode: nil, type: .unknown, message: errorString)
                    completion(.failure(apiError))
                }
            @unknown default:
                break
            }
        }
        return request
    }
    
    
    @discardableResult
    open func request(
        path: String,
        version: Int? = nil,
        method: Alamofire.HTTPMethod,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding? = nil,
        completion: @escaping VMSResultDataBlock
    ) -> DataRequest? {
        
        return request(url: self.urlBuilder.build(path: path, version: version),
                       method: method,
                       parameters: parameters,
                       encoding: encoding,
                       completion: completion)
    }
    
    func decode<T: Decodable>(data: Any) -> VMSApiResult<T> {
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            let decodeResult = try self.decoder.decode(T.self, from: jsonData)
            
            return .success(decodeResult)
        } catch let DecodingError.dataCorrupted(context) {
            return .failure(.init(statusCode: nil, type: .decode, message: "Data corrupted: \(context)"))
        } catch let DecodingError.keyNotFound(key, context) {
            return .failure(VMSApiError.init(statusCode: nil, type: .decode, message: "Key '\(key)' not found: \(context.debugDescription)\nCodingPath: \(context.codingPath)"))
        } catch let DecodingError.valueNotFound(value, context) {
            return .failure(VMSApiError.init(statusCode: nil, type: .decode, message: "Value '\(value)' not found: \(context.debugDescription)\nCodingPath: \(context.codingPath)"))
        } catch let DecodingError.typeMismatch(type, context)  {
            return .failure(VMSApiError.init(statusCode: nil, type: .decode, message: "Type '\(type)' mismatch: \(context.debugDescription)\nCodingPath: \(context.codingPath)"))
        } catch {
            return .failure(VMSApiError.init(statusCode: nil, type: .decode, message: "Unknown decoding error"))
        }
    }
    
    public func repeatRequest(_ request: VMSRequest) {
        self.request(url: request.url, method: request.method, parameters: request.parameters, completion: request.completion)
    }
    
    open func downloadArchiveRequest(
        url: URL,
        destinationUrl: URL,
        progressHandler: @escaping ((Progress) -> Void),
        completionHandler: @escaping ((Error?) -> Void)
    ) {
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (destinationUrl, [.removePreviousFile, .createIntermediateDirectories])
        }
        currentDownloadRequest = sessionManager.download(URLRequest(url: url), to: destination).downloadProgress(closure: { progress in
            progressHandler(progress)
        }).responseData { [weak self] response in
            completionHandler(response.error)
            self?.currentDownloadRequest = nil
        }
    }
    
    func uploadRequest(
        path: String,
        data: Data,
        name: String,
        params: Parameters,
        completion: @escaping VMSResultDataBlock
    ) {
         
        sessionManager.upload(multipartFormData: { (multipart: MultipartFormData) in
            guard let params = params as? [String: String] else { return }
            
            for (key, value) in params {
                if let keyData = value.data(using: .utf8) {
                    multipart.append(keyData, withName: key)
                }
            }
            
            multipart.append(data, withName: "image", fileName: name, mimeType: "image/jpeg")
        },usingThreshold: UInt64.init(),
            to: self.urlBuilder.build(path: path),
            method: .post,
            headers: headersBuilder.getHeaders(),
            encodingCompletion: { (result) in
            
            switch result {
            case .success(let upload, _, _):
                upload.responseJSON { uploadResponse in
                    switch uploadResponse.result {
                    case .success(let data):
                        completion(.success(data))
                    case .failure(let error):
                        var errorString: String? = error.localizedDescription
                        if let responseData = uploadResponse.data {
                            errorString = self.getErrorFromData(data: responseData)
                        }
                        let apiError = VMSApiError(statusCode: uploadResponse.response?.statusCode, type: .unknown, message: errorString)
                        completion(.failure(apiError))
                    @unknown default:
                        break
                    }
                }
            case .failure(let encodingError):
                let apiError = VMSApiError(statusCode: nil, type: .decode, message: encodingError.localizedDescription)
                completion(.failure(apiError))
            @unknown default:
                break
            }
        })
    }

    public func cancelDownloadArchiveRequest() {
        currentDownloadRequest?.cancel()
        currentDownloadRequest = nil
    }
    
    open func getErrorFromData(data: Data) -> String? {
        var errorString = ""
        do {
            if let jsonArray = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
                for (key,value) in jsonArray {
                    if key == "errors" {
                        if let error = value as? String {
                            return error
                        } else if let errors = value as? [String: Any] {
                            for error in errors {
                                if let errorArray = error.value as? [String] {
                                    errorString = errorArray.joined(separator: "\n")
                                }
                            }
                            return errorString
                        } else {
                            return nil
                        }
                    }
                }
            }
        } catch _  {
            return nil
        }
        
        return nil
    }
    
    public static func encoding(for method: HTTPMethod) -> ParameterEncoding {
        if method == .get {
            return URLEncoding.queryString
        }
        return JSONEncoding.prettyPrinted
    }
    
}

public struct VMSRequest {
    
    public let url: String
    public let method: Alamofire.HTTPMethod
    public let parameters: Alamofire.Parameters?
    public let completion: VMSResultDataBlock
    
    init(url: String, method: Alamofire.HTTPMethod, parameters: Parameters?, completion: @escaping VMSResultDataBlock) {
        self.url = url
        self.method = method
        self.parameters = parameters
        self.completion = completion
    }
}
