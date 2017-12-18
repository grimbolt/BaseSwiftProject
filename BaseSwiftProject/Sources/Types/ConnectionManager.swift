//
//  ConnectionManager.swift
//  BaseSwiftProject
//
//  Created by Grimbolt on 07.01.2017.
//
//

import Foundation
import Alamofire
import AlamofireObjectMapper
import ObjectMapper

public class ConnectionManager {
    
    enum PareseError: Error {
        case invalid
    }
    
    static let lock = NSLock()
    
    static var _sessionManager: SessionManager?
    public static var sessionManager: SessionManager {
        get {
            if let sessionManager = ConnectionManager._sessionManager {
                return sessionManager;
            } else {
                let configuration = URLSessionConfiguration.default
                configuration.timeoutIntervalForRequest = 20
                configuration.timeoutIntervalForResource = 20
                
                configuration.urlCache = nil
                
                ConnectionManager._sessionManager = SessionManager(configuration: configuration)
                return ConnectionManager._sessionManager!
            }
        }
        set {
            ConnectionManager._sessionManager = newValue
        }
    }
    
    public static func request<T: BaseMappable> (
        _ url: URLConvertible,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil,
        preloaderType: PreloaderType = .small,
        withSaveContext: Bool = true,
        beforeMapping: ((DefaultDataResponse) -> Void)? = nil,
        completionHandler: ((DataResponse<T>) -> Void)? = nil
        ) {
        
        let request = sessionManager.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers)
        let uuid = UUID().uuidString
        showPreloader(uuid, type: preloaderType)
        
        request
            .response { response in
                beforeMapping?(response)
            }
            .responseObject { (response: DataResponse<T>) in
                commonResponse(preloader: uuid, preloaderType: preloaderType, response: response, completionHandler: completionHandler, withSaveContext: withSaveContext)
            }
            .validate { request, response, data in
                return validate(request: request, response: response, data: data)
        }
    }
    
    public static func requestArray<T: BaseMappable> (
        _ url: URLConvertible,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil,
        preloaderType: PreloaderType = .small,
        withSaveContext: Bool = true,
        beforeMapping: ((DefaultDataResponse) -> Void)? = nil,
        completionHandler: ((DataResponse<[T]>) -> Void)? = nil
        ) {
        
        let request = sessionManager.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers)
        let uuid = UUID().uuidString
        showPreloader(uuid, type: preloaderType)

        request
            .response { response in
                beforeMapping?(response)
            }
            .responseArray { (response: DataResponse<[T]>) in
                commonResponse(preloader: uuid, preloaderType: preloaderType, response: response, completionHandler: completionHandler, withSaveContext: withSaveContext)
            }
            .validate { request, response, data in
                return validate(request: request, response: response, data: data)
        }
    }
    
    public static func simpleRequestWithHttpBody<T: BaseMappable> (
        url:URL,
        httpBody:Data?,
        method: HTTPMethod = .get,
        headers: HTTPHeaders? = nil,
        preloaderType: PreloaderType = .small,
        withSaveContext: Bool = true,
        beforeMapping: ((DefaultDataResponse) -> Void)? = nil,
        completionHandler: @escaping (DataResponse<[T]>) -> Void
        ) {

        var urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        urlRequest.httpBody = httpBody
        urlRequest.httpMethod = method.rawValue
        
        if let _ = headers {
            for header in headers! {
                urlRequest.setValue(header.value, forHTTPHeaderField: header.key)
            }
        }
        
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let request = sessionManager.request(urlRequest)
        let uuid = UUID().uuidString
        showPreloader(uuid, type: preloaderType)

        request
            .response { response in
                beforeMapping?(response)
            }
            .responseArray { (response: DataResponse<[T]>) in
                commonResponse(preloader: uuid, preloaderType: preloaderType, response: response, completionHandler: completionHandler, withSaveContext: withSaveContext)
            }
            .validate { (requst, response, data) -> Request.ValidationResult in
                return validate(request: requst, response: response, data: data)
        }
    }
    
    public static func simpleRequestWithHttpBody<T: BaseMappable> (
        url:URL,
        httpBody:Data?,
        method: HTTPMethod = .get,
        headers: HTTPHeaders? = nil,
        preloaderType: PreloaderType = .small,
        withSaveContext: Bool = true,
        beforeMapping: ((DefaultDataResponse) -> Void)? = nil,
        completionHandler: @escaping (DataResponse<T>) -> Void
        ) {

        var urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        urlRequest.httpBody = httpBody
        urlRequest.httpMethod = method.rawValue
        
        if let _ = headers {
            for header in headers! {
                urlRequest.setValue(header.value, forHTTPHeaderField: header.key)
            }
        }
        
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let request = sessionManager.request(urlRequest)
        let uuid = UUID().uuidString
        showPreloader(uuid, type: preloaderType)

        request
            .response { response in
                beforeMapping?(response)
            }
            .responseObject { (response: DataResponse<T>) in
                commonResponse(preloader: uuid, preloaderType: preloaderType, response: response, completionHandler: completionHandler, withSaveContext: withSaveContext)
            }
            .validate { (requst, response, data) -> Request.ValidationResult in
                return validate(request: requst, response: response, data: data)
        }
    }
    
    public static func cancelAllTasks(whiteList: [String] = []) {
        sessionManager.session.getTasksWithCompletionHandler { (sessionDataTask, sessionUploadTask, sessionDownloadTask) in
            func forEach(_ task: URLSessionTask) {
                if let url = task.currentRequest?.url?.absoluteString {
                    var onWhiteList = false;
                    whiteList.forEach({
                        if url.hasPrefix($0) {
                            onWhiteList = true
                        }
                    })
                    
                    if !onWhiteList {
                        task.cancel()
                    }
                    
                } else {
                    task.cancel()
                }
            }
            
            sessionDataTask.forEach({ forEach($0) })
            sessionUploadTask.forEach({ forEach($0) })
            sessionDownloadTask.forEach({ forEach($0) })
        }
    }

    private static func commonResponse<T>(
        preloader uuid: String,
        preloaderType: PreloaderType,
        response: DataResponse<T>,
        completionHandler: ((DataResponse<T>) -> Void)?, withSaveContext: Bool
        ) {
        
        hidePreloader(uuid, type: preloaderType)
        switch response.result {
        case .failure(let error):
            print("error \(error)")
            if (error as NSError).code == NSURLErrorCancelled {
                // nothing
            } else {
                completionHandler?(response)
            }
            break
        default:
            completionHandler?(response)
        }
        
        if withSaveContext {
            switch response.result {
            case .success:
                DatabaseHelper.sharedInstance.saveContext()
            case .failure: break
            }
        }
    }
    
    private static func validate(request: URLRequest?, response: HTTPURLResponse, data: Data?) -> DataRequest.ValidationResult {
        if
            let data = data,
            response.statusCode >= 200,
            response.statusCode < 300
        {
            do {
                try JSONSerialization.jsonObject(with: data, options: [])
                return DataRequest.ValidationResult.success
            } catch {
            }
        }
        return DataRequest.ValidationResult.failure(PareseError.invalid)
    }
    
}
