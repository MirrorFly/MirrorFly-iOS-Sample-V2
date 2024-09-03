//
//  LocationViewController.swift
//  MirrorflyUIkit
//
//  Created by User on 02/09/21.
//
 
import Foundation
import UIKit
import CoreLocation
import MapKit
import GoogleMaps
import SwiftUI
 
 
protocol LocationDelegate : NSObjectProtocol {
    func didSendPressed(latitude: Double, longitude: Double,jid: String?)
    func goBackLocationRefreshData()
}
 
class LocationViewController: BaseViewController, GMSMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var googleMapView: GMSMapView?
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var streetLabel: UILabel!
    @IBOutlet weak var address1Label: UILabel!
    @IBOutlet weak var navigationView: UIView!
    
    @IBOutlet weak var sendThisLocationLabel: UILabel!
    var locationManager = CLLocationManager()
    var marker: GMSMarker?
    weak var locationDelegate: LocationDelegate?
 
    var latitude : Double?
    var longitude : Double?
    var isForView = false
    var isMapZoomed = false
    var mapZoomLevel: Float?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bottomView.addTopShadow(shadowColor: UIColor.lightGray)
        handleBackgroundAndForground()
        sendButton.layer.shadowColor = Color.senderBubbleColor.cgColor
        sendButton.layer.shadowOffset = CGSize(width: 0, height: 15.0)
        sendButton.layer.shadowOpacity = 25.0
        sendButton.layer.shadowRadius = 25.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        setUpStatusBar()
        initializeLocationManager()
        hideSendButton(hide: false)
        setForView()
        ChatViewParentController.receiveCallModeDelegate = nil
        CallUIViewController.pipModeDelegate = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationView.isHidden = true
        googleMapView = nil
    }
    
    @objc override func willCometoForeground() {
        print("LocationViewController appComestoForeground")
        switch CLLocationManager.authorizationStatus() {
            case .notDetermined:
                executeOnMainThread {
                    self.initializeLocationManager()
                }
                break
            case .restricted:
                enableLocationPermissionInSettings()
                break
            case .denied:
                let isFirstTime = Utility.getBoolFromPreference(key: isLocationDenied)
                if !isFirstTime {
                    Utility.saveInPreference(key: isLocationDenied, value: true)
                    goPrevious()
                } else {
                    enableLocationPermissionInSettings()
                }
                break
            case .authorizedAlways, .authorizedWhenInUse, .authorized:
                locationManager.startUpdatingLocation()
                break
             default:
                locationManager.stopUpdatingLocation()
        }
    }
    
    func initializeLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            if !isForView {
                locationManager.startUpdatingLocation()
            }
        }
        
        self.googleMapView?.delegate = self
        self.googleMapView?.isMyLocationEnabled = true
        self.googleMapView?.settings.myLocationButton = true
        mapZoomLevel = self.googleMapView?.camera.zoom
    }
}
 
//MARK - Actions
extension LocationViewController {
    @IBAction func onBack(_ sender: Any) {
        self.locationDelegate?.goBackLocationRefreshData()
        goPrevious()
    }
    
    @IBAction func onSend(_ sender: Any) {
        emptyViewingData()
        navigationController?.popViewController(animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.locationDelegate?.didSendPressed(latitude: self?.marker?.position.latitude ?? 0.0,
                                                   longitude: self?.marker?.position.longitude ?? 0.0, jid: "")
        }
    }
    
    func goPrevious() {
        emptyViewingData()
        self.navigationController?.popViewController(animated: true)
    }
}
   
//MARK - Location Delegate
extension LocationViewController {
   func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
       print("locationManager didUpdateLocations")
       if !isForView {
           let location = locationManager.location?.coordinate
           print("locationManager didUpdateLocations \(String(describing: location?.latitude)) ** \(location?.longitude)")
           latitude = location?.latitude
           longitude = location?.longitude
           setMarkerForLocationMsg()
           cameraMoveToLocation(toLocation: location)
           locationManager.stopUpdatingLocation()
       }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("locationManager didFailWithError")
        print("error::: \(error)")
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("locationManager didChangeAuthorization")
        switch status {
        case .notDetermined:
            locationManager.stopUpdatingLocation()
            break
        case .restricted:
            enableLocationPermissionInSettings()
            break
        case .denied:
            let isFirstTime = Utility.getBoolFromPreference(key: isLocationDenied)
            if !isFirstTime {
                Utility.saveInPreference(key: isLocationDenied, value: true)
                goPrevious()
            } else {
                enableLocationPermissionInSettings()
            }
            break
        case .authorizedAlways, .authorizedWhenInUse, .authorized:
            if !isForView {
                print("locationManager location permission")
                locationManager.startUpdatingLocation()
            }
            break
        @unknown default:
            locationManager.stopUpdatingLocation()
        }
    }
    
    func enableLocationPermissionInSettings(){
        let alert = UIAlertController(title: settings.localized, message: allowLocation.localized, preferredStyle: UIAlertController.Style.alert)
        self.present(alert, animated: true, completion: nil)
        if
            let settings = URL(string: UIApplication.openSettingsURLString),
            UIApplication.shared.canOpenURL(settings) {
            alert.addAction(UIAlertAction(title: okayButton.localized, style: .default) { action in
                    UIApplication.shared.open(settings)
                })
         }
        alert.addAction(UIAlertAction(title: cancel.localized, style: .cancel) { [weak self] action in
            self?.goPrevious()
        })
    }
    
    func cameraMoveToLocation(toLocation: CLLocationCoordinate2D?) {
          if toLocation != nil {
              googleMapView?.camera = GMSCameraPosition.camera(withTarget: toLocation!, zoom: 15)
              if(isForView){
              setMarkerForLocationMsg()
              }
              mapZoomLevel = self.googleMapView?.camera.zoom
              print("Location called at cameraMove \(toLocation!.latitude) ** \(toLocation!.latitude)")
              getAddressFromCoordinates(pdblLatitude: Double(toLocation!.latitude), withLongitude: Double(toLocation!.longitude))
          }
          
      }

    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        if(!isForView){
            googleMapView?.isMyLocationEnabled = true
        let coordinate = position.target
            print("Location called at idleA \(coordinate.latitude) ** \(coordinate.longitude)t")
        getAddressFromCoordinates(pdblLatitude: coordinate.latitude, withLongitude: coordinate.longitude)
        updateLocationoordinates(coordinates: coordinate)
        }
    }
    
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
            isMapZoomed = false
        googleMapView?.isMyLocationEnabled = true
            if (gesture) {
                mapView.selectedMarker = nil
            }
    if(mapZoomLevel != mapView.camera.zoom){
                isMapZoomed = true
                mapZoomLevel = mapView.camera.zoom
            }
        }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        mapView.isMyLocationEnabled = true
        print("Location called at didTap")
        getAddressFromCoordinates(pdblLatitude: marker.position.latitude, withLongitude: marker.position.longitude)
        return false
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
           print("COORDINATE \(coordinate)") // when you tapped coordinate
   if(!isForView){
       print("Location called at didTapAt")
   getAddressFromCoordinates(pdblLatitude: coordinate.latitude, withLongitude: coordinate.longitude)
           updateLocationoordinates(coordinates: coordinate)
       }
   }
 
    
    func updateLocationoordinates(coordinates:CLLocationCoordinate2D) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.5)
        marker?.position =  coordinates
        CATransaction.commit()
    }
    
    func didTapMyLocationButton(for mapView: GMSMapView) -> Bool {
        mapView.isMyLocationEnabled = true
        mapView.selectedMarker = nil
        marker?.map = mapView
        print("Location called at TapMyLocation")
        getAddressFromCoordinates(pdblLatitude: marker?.position.latitude ?? 0.0, withLongitude: marker?.position.longitude ?? 0.0)
        return false
    }
    
    //draggable ->>> marker move
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
           if(isForView){
               setMarkerForLocationMsg()
           }
           else{
           if(!isMapZoomed){
               mapView.clear()
               marker = GMSMarker(position: position.target)
               marker?.map = mapView
           }
           }
       }
       
       func setMarkerForLocationMsg(){
           marker = GMSMarker(position: CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!))
           marker?.map = googleMapView
       }

    
    func getAddressFromCoordinates(pdblLatitude: Double, withLongitude pdblLongitude: Double) {
        var center : CLLocationCoordinate2D = CLLocationCoordinate2D()
        let ceo: CLGeocoder = CLGeocoder()
        center.latitude = pdblLatitude
        center.longitude = pdblLongitude
        let loc: CLLocation = CLLocation(latitude:center.latitude, longitude: center.longitude)
        ceo.cancelGeocode()
        ceo.reverseGeocodeLocation(loc, completionHandler:
                    {(placemarks, error) in
                        if (error != nil)
                        {
                            print("reverse geodcode fail: \(error!.localizedDescription)")
                        }
                        guard let pm = placemarks else {
                            return
                        }
 
                        if pm.count > 0 {
                            let pm = placemarks![0]
                            var addressString : String = ""
                            var streetName = ""
                            if let street = pm.postalAddress?.value(forKey: "street") as? String{
                                print("Location Address street \(street)")
                                self.streetLabel.text = street
                                streetName = street
                            }
                            
                            if let subLocality = pm.postalAddress?.value(forKey: "subLocality") as? String{
                                if streetName.isEmpty {
                                    self.streetLabel.text = subLocality
                                }
                                addressString = addressString + subLocality + ", "
                            }
                            
                            if let city = pm.postalAddress?.value(forKey: "city") as? String {
                                addressString = addressString + city + ", "
                            }
                            
                            if let subAdministrativeArea = pm.postalAddress?.value(forKey: "subAdministrativeArea") as? String {
                                addressString = addressString + subAdministrativeArea + ", "
                            }
                            
                            if let state = pm.postalAddress?.value(forKey: "state") as? String {
                                addressString = addressString + state + ", "
                            }
                            
                            if let postalCode = pm.postalAddress?.value(forKey: "postalCode") as? String {
                                addressString = addressString + postalCode + ", "
                            }
                            
                            if let country = pm.postalAddress?.value(forKey: "country") as? String {
                                addressString = addressString + country
                            }
                            
                            print("Location Address \(addressString)")
                            self.address1Label.text = addressString
            
                      }
                })
        
        }
}
// for viewing location
extension  LocationViewController {
    func setForView() {
        if isForView && latitude != nil && longitude != nil{
            hideSendButton(hide: true)
            let cLLocationCoordinate2DMake = CLLocationCoordinate2DMake(latitude ?? 0.0 , longitude ?? 0.0)
            cameraMoveToLocation(toLocation: cLLocationCoordinate2DMake)
            googleMapView?.animate(toLocation: cLLocationCoordinate2DMake)
 
        }
    }
    
    func emptyViewingData() {
        isForView = false
        latitude = nil
        longitude = nil
    }
    
    func hideSendButton(hide : Bool) {
        sendButton.isHidden = hide
        sendThisLocationLabel.isHidden = hide
    }
}
   

