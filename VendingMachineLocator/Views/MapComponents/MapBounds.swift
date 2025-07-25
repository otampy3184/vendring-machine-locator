import MapKit
import CoreLocation

// MARK: - Map Bounds Extensions
struct MapBounds {
    let northEast: CLLocationCoordinate2D
    let southWest: CLLocationCoordinate2D
    
    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        return coordinate.latitude >= southWest.latitude &&
               coordinate.latitude <= northEast.latitude &&
               coordinate.longitude >= southWest.longitude &&
               coordinate.longitude <= northEast.longitude
    }
}

extension MKCoordinateRegion {
    var bounds: MapBounds {
        let northEast = CLLocationCoordinate2D(
            latitude: center.latitude + span.latitudeDelta / 2,
            longitude: center.longitude + span.longitudeDelta / 2
        )
        let southWest = CLLocationCoordinate2D(
            latitude: center.latitude - span.latitudeDelta / 2,
            longitude: center.longitude - span.longitudeDelta / 2
        )
        return MapBounds(northEast: northEast, southWest: southWest)
    }
}