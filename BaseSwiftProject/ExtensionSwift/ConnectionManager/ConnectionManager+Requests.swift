//
//  ConnectionManager+Requests.swift
//  BaseSwiftProject
//
//  Created by Grimbolt on 09.01.2017.
//
//

import Foundation
import Alamofire
import AlamofireObjectMapper
import ObjectMapper
import BaseSwiftProject

private protocol FakeRequestsProtocol {}

extension ConnectionManager: FakeRequestsProtocol {
    
    static func login(completionHandler: @escaping (DataResponse<String>) -> Void) {
        let urlString = ConnectionManager.SAMPLE_LOGIN_URL
        
        let parameters: Parameters = [
            "api_dev_key":          ConnectionManager.API_DEV_KEY,
            "api_user_name":        ConnectionManager.API_USER_NAME,
            "api_user_password":    ConnectionManager.API_USER_PASSWORD
        ]
        
        sessionManager.request(urlString, method: .post, parameters: parameters).responseString { response in
            completionHandler(response)
        }

    }
    
    static func syncSamplePersons() {
        let parameters: Parameters = [
            "api_dev_key":      "010679309007042ca809a7171a59eccc",
            "api_paste_key":    "NefBMSk7",
            "api_option":       "show_paste"
        ]
        
        ConnectionManager.request(ConnectionManager.SAMPLE_POST_URL, method: .post, parameters: parameters) { (response: DataResponse<SampleUsersResponse>) in
            
            switch response.result {
            case .success:
                DatabaseHelper.sharedInstance.saveContext()
            case .failure: break
            }
            
        }
    }
}
