//
//  APIService.swift
//  MirrorFly
//
//  Created by User on 19/05/21.
//
import Alamofire
import Foundation
import MirrorFlySDK

class ApiService
{
    
    let manager = Alamofire.Session.default
    init() {
        manager.session.configuration.timeoutIntervalForRequest = 300
    }
    
    public static let shared : ApiService = ApiService()
    
    func get(withEndPoint endpoint: String, params: Parameters? = nil) -> DataRequest {
        // Get base url and combine with end points
        let Baseurl = Bundle.main.object(forInfoDictionaryKey: BaseURL) as! String
        let url = Baseurl + endpoint
        return request(
            at: url,
            method: .get,
            params: params,
            encoding: URLEncoding.default)
    }
    
    func post(withEndPoint url: String, params: Parameters? = nil, headers:HTTPHeaders?) -> DataRequest {
        return AF.request(url, method: .post,
                            parameters: params,
                            encoding: JSONEncoding.default,
                            headers: headers)
    }
    
//    func post(restEnd: String, headers:HTTPHeaders?, method: HTTPMethod , params: Parameters?, interceptor: RequestInterceptor? = nil, completionHandler : @escaping FlyCompletionHandler) -> DataRequest{
//        let request = dataTaskManager?.request(restEnd, method: method, parameters: params, encoding: JSONEncoding.default, headers: headers, interceptor: nil, requestModifier: nil).validate().responseJSON { response in
//            switch response.result
//            {
//            case .success(let JSON):
//                guard let responseDictionary = JSON as?[String : Any]  else{
//                    return
//                }
//                completionHandler(true, nil, responseDictionary)
//                break
//            case .failure( _):
//                print(response)
//                break
//            }
//        }
//        return request!
//    }
//
    
    func put(withEndPoint endpoint: String, params: Parameters? = nil) -> DataRequest {
        // Get base url and combine with end points
        let Baseurl = Bundle.main.object(forInfoDictionaryKey: BaseURL) as! String
        let url = Baseurl + endpoint
        return request(
            at: url,
            method: .put,
            params: params,
            encoding: JSONEncoding.default)
    }
    
    func request(at url: String, method: HTTPMethod, params: Parameters?, encoding: ParameterEncoding) -> DataRequest {
        return manager.request(
            url,
            method: method,
            parameters: params,
            encoding: encoding)
            .validate()
    }
    
    func requestPost(at url: String, json: String) -> DataRequest {
        let urlData = URL(string: url)!
        let jsonData = json.data(using: .utf8, allowLossyConversion: false)!
        var request = URLRequest(url: urlData)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        return AF.request(request).validate()
    }
    

    func refreshToken(completionHandler : @escaping FlyCompletionHandler) {
        ChatManager.refreshToken(completionHandler: completionHandler)
    }


    func refreshRequest(url:String, headers:HTTPHeaders?, method: HTTPMethod , params: [String: String],  completionHandler : @escaping FlyCompletionHandler) {
        
        guard let postUrl = URL(string: url) else {
            completionHandler(false, nil,[:])
            return
        }
        do {
            let postData =  try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        var request = URLRequest(url: postUrl)
        request.httpMethod = HTTPMethod.post.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = postData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
          guard let data = data else {
            completionHandler(false, nil, [:])
            return
          }
            do {
                if  let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] {
                completionHandler(true, nil, json)
                }else {
                    completionHandler(false, nil, [:])
                }
                    } catch {
                        print(error.localizedDescription)
                        completionHandler(false, nil, [:])
                    }
        }
        task.resume()
        } catch {
            completionHandler(false, nil, [:])
        }
    }

    
}
