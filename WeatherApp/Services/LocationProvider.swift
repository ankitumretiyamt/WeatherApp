//
//  LocationProvider.swift
//  WeatherApp
//
//  Created by Ankit Umretiya on 30/10/26.
//

import CoreLocation
import Foundation

enum LocationAccessError: Error, Equatable {
    case denied
    case unavailable
}

@MainActor
final class LocationProvider: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    private var authorizationContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
    private var inFlight: Task<CLLocation, Error>?
    private var fixID = 0

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = kCLDistanceFilterNone
    }

    func requestCurrentLocation() async throws -> CLLocation {
        if let inFlight {
            return try await inFlight.value
        }
        let task = Task<CLLocation, Error> { @MainActor in
            try await self.acquireFix()
        }
        inFlight = task
        do {
            let location = try await task.value
            inFlight = nil
            return location
        } catch {
            inFlight = nil
            throw error
        }
    }

    func describe(_ location: CLLocation) async -> (name: String, country: String, admin: String?) {
        do {
            let marks = try await CLGeocoder().reverseGeocodeLocation(location)
            let mark = marks.first
            let name = mark?.locality
                ?? mark?.subAdministrativeArea
                ?? mark?.administrativeArea
                ?? "Current location"
            return (name, mark?.country ?? "", mark?.administrativeArea)
        } catch {
            return ("Current location", "", nil)
        }
    }

    private func acquireFix() async throws -> CLLocation {
        let status = try await authorize()
        guard status == .authorizedAlways || status == .authorizedWhenInUse else {
            throw LocationAccessError.denied
        }

        fixID += 1
        let id = fixID
        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            manager.startUpdatingLocation()
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(12))
                guard self.fixID == id else { return }
                self.finishLocation(.failure(LocationAccessError.unavailable))
            }
        }
    }

    private func authorize() async throws -> CLAuthorizationStatus {
        let current = manager.authorizationStatus
        let resolved: CLAuthorizationStatus
        if current == .notDetermined {
            resolved = await requestAuthorization()
        } else {
            resolved = current
        }
        guard resolved == .authorizedAlways || resolved == .authorizedWhenInUse else {
            throw LocationAccessError.denied
        }
        return resolved
    }

    private func requestAuthorization() async -> CLAuthorizationStatus {
        await withCheckedContinuation { continuation in
            authorizationContinuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    private func finishLocation(_ result: Result<CLLocation, Error>) {
        guard let continuation = locationContinuation else { return }
        locationContinuation = nil
        fixID += 1
        manager.stopUpdatingLocation()
        continuation.resume(with: result)
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            guard status != .notDetermined, let continuation = authorizationContinuation else { return }
            authorizationContinuation = nil
            continuation.resume(returning: status)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, location.horizontalAccuracy >= 0 else { return }
        Task { @MainActor in
            self.finishLocation(.success(location))
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let code = (error as? CLError)?.code
        Task { @MainActor in
            // The first callback is often "location unknown" while GPS locks on.
            if code == .locationUnknown { return }
            if code == .denied {
                self.finishLocation(.failure(LocationAccessError.denied))
            } else {
                self.finishLocation(.failure(LocationAccessError.unavailable))
            }
        }
    }
}
