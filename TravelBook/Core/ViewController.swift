//
//  ViewController.swift
//  TravelBook
//
//  Created by Mustafa Çiçek on 17.07.2022.
//

import UIKit
import MapKit
// kullanıcının konumunu almak için kullanıyoruz
import CoreLocation
import CoreData



class ViewController: UIViewController{

    @IBOutlet weak var nameText: UITextField!
    
    @IBOutlet weak var commentText: UITextField!
    
    @IBOutlet weak var mapView : MKMapView!
    // kullanıcının konumunu alıcaksam ve bununla ilgili işlemler yapacaksam CLLocationManager'i kullanmam gerekiyor
    var locationManager = CLLocationManager()
    
    var choosenLatitude : Double?
    var choosenLongitude : Double?
    
    var selectedTitle = ""
    var selectedTitleID : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        // neden bunu yapıyoruz bu sınıflardan bazı fonksiyonlarını çağıracağımız için bu sınıfımıza kullanma hakkı veriyoruz gibi bir şey
        
        locationManager.delegate = self
        // konumu ne kadar kesinkinlikle bulunacak
        // en iyi şekilde konumu getirecektir ama cihazın pilini çok yer
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // kullanıcının iznini aldık
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        
        // long diyoruz ama kaç saniye basması gerektiğini de belirtebiliriz.
        // genelde 2-3 gibi kullanılır. 1 yazınca elini hemen basmış gibi algılanır
        gestureRecognizer.minimumPressDuration = 1
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if selectedTitle != "" {
           
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequeset = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedTitleID!.uuidString
            
            fetchRequeset.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequeset.returnsObjectsAsFaults = false
            do{
                let results = try context.fetch(fetchRequeset)
                if results.count > 0 {
                    for result in results as!  [NSManagedObject] {
                        if let title = result.value(forKey: "title") as? String{
                            annotationTitle = title
                            
                            if let subtitle = result.value(forKey: "subtitle") as? String{
                                annotationSubtitle = subtitle
                                
                                if let latitude = result.value(forKey: "latitude") as? Double {
                                    annotationLatitude = latitude
                                    
                                    if let longitude = result.value(forKey: "longitude") as? Double{
                                        annotationLongitude = longitude
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubtitle
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        
                                        annotation.coordinate = coordinate
                                        
                                        mapView.addAnnotation(annotation)
                                        
                                        nameText.text = annotationTitle
                                        commentText.text = annotationSubtitle
                                            
                                        // kullanıcının konumu değişince değişmesin istiyorsan
                                        // konum güncellemesini durdurman gerek
                                        locationManager.stopUpdatingLocation()
                                        
                                        // tıklanılan yer nere ise oraya götürsün
                                        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        
                                        mapView.setRegion(region, animated: true)
                                        
                                    }
                                }
                            }
                            
                        }
                        
                        
                        
                       
                       
                        
                    }
                }
                
            }
            catch {
                    print("error ")
            }

        }
        else {
            
        }
    }
    // burada içine parametre olarak vermemizin amacı gestureRecognizer'ın fonksionlarını kullanabilmemiz için
    @objc func chooseLocation(gestureRecognizer: UILongPressGestureRecognizer){
        // dokunma işlemi başladıysa demek bu
        if gestureRecognizer.state == .began {
            let touchedPoint = gestureRecognizer.location(in: self.mapView)
            // dokunulan noktayı coordinate'a çevirmem gerekiyor
            
            let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
            // dokunulan kordinatlara şimdi pin ekliyoruz
            // annotation
            
            // CoreData icin
            self.choosenLatitude = touchedCoordinates.latitude
            self.choosenLongitude = touchedCoordinates.longitude
            
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = nameText.text
            annotation.subtitle = commentText.text
            self.mapView.addAnnotation(annotation)
        }
    }
    
    // delegate'yi yaptığımız için şimdi fonksiyonlarına erişebilir hale geldik
    // güncellenen locationları bana sürekli dizi içerisinde veriyor
    // yürüdükçe location'un değişecek mesela
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
       // konumumuuzu alıyoruz
        if selectedTitle == ""{
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            // konumumuzun yakınlaştırılması için
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }
       
    }
    
    // annotation'umuzu özelleştirip yol tarifi verme butonu olusturacağız
     func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
         
         // kullanıcımın yerini anotation ile göstermeyeceğim
         // sadece işaretlediğim yer anotation ile görünsün
         if annotation is MKUserLocation {
             return nil
         }
         
        let reuserID = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuserID) as? MKPinAnnotationView
         
         if pinView == nil {
             pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuserID)
             pinView?.canShowCallout = true
             pinView?.tintColor = UIColor.blue
             
             let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
             pinView?.rightCalloutAccessoryView = button
             
         }
         else{
             pinView?.annotation = annotation
             
         }
        
        return pinView
    }
    
    // butona tıklandığını anlamamız için yani inkwell gibi bir şey
     func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedTitle != "" {
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            // callback fonksiyonu gibi closure
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks , error) in
                if let placemark = placemarks {
                    if placemark.count > 0 {
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        // closure içinde self kullanın
                        item.name = self.annotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        
                        item.openInMaps(launchOptions: launchOptions)
                        
                    }
                    
                }
              
            }
        }
    }

    @IBAction func saveButton(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        
        newPlace.setValue(nameText.text, forKey: "title")
        newPlace.setValue(commentText.text, forKey: "subtitle")
        
        newPlace.setValue(choosenLatitude, forKey: "latitude")
        newPlace.setValue(choosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID() , forKey: "id")
         
        do{
            try context.save()
            print("success")
        }catch{
            print("error")
        }
        
        // observer yolluyor ve bu newPlace mesajı gelince ne yapacağını söylüyor
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        // yakalayacağın sayfada view will Appear yap
        navigationController?.popViewController(animated: true)
        
        
    }
    
}

extension UIViewController :  MKMapViewDelegate , CLLocationManagerDelegate, UIApplicationDelegate{

  
}
