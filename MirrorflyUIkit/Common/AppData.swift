//
//  AppData.swift
//  commonDemo
//
//  Created by User on 13/08/21.
//

import Foundation

//Access : AppConstant.baseUrl
let googleApiKey = getkey().0
let googleApiKey_Translation = getkey().1

struct AppConstant {
    //App Detail
    static let appName = "MirrorFly"
}

func getkey() -> (String, String) {
    var keys:(String, String)!
    if let path = Bundle.main.path(forResource: "MirrorflyUIkit-info", ofType: "plist"){
        if let dict = NSDictionary(contentsOfFile: path) as? Dictionary<String, AnyObject> {
            keys = (dict["googleApiKey"] as! String,dict["googleApiKey_Translation"] as! String)
        }
    }
    return keys
}
