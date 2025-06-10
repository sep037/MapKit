//
//  ContentView.swift
//  MyLocationMap
//
//  Created by Seungeun Park on 6/10/25.
//


import SwiftUI
import MapKit

struct FavoriteLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

func searchLocation(named name: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = name

    let search = MKLocalSearch(request: request)
    search.start { response, error in
        guard let coordinate = response?.mapItems.first?.placemark.coordinate, error == nil else {
            print("검색 실패 또는 결과 없음: \(error?.localizedDescription ?? "알 수 없음")")
            completion(nil)
            return
        }
        completion(coordinate)
    }
}

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var searchText: String = ""
    @State private var favoriteLocations: [FavoriteLocation] = []
    @State private var currentSearchCoordinate: CLLocationCoordinate2D?

    var body: some View {
        ZStack(alignment: .top) {
            Map(coordinateRegion: $locationManager.region, showsUserLocation: true, annotationItems: favoriteLocations) { location in
                MapAnnotation(coordinate: location.coordinate) {
                    Image(systemName: "star.circle.fill")
                        .foregroundColor(.yellow)
                        .font(.title)
                }
            }
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                locationManager.requestPermission()
            }
            .onChange(of: locationManager.region) { newRegion in
                print("지도 중심 이동됨: \(newRegion.center.latitude), \(newRegion.center.longitude)")
            }

            VStack(spacing: 10) {
                HStack {
                    TextField("가게 이름 검색", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    Button("검색") {
                        searchLocation(named: searchText) { coordinate in
                            if let coordinate = coordinate {
                                locationManager.region = MKCoordinateRegion(
                                    center: coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                )
                                currentSearchCoordinate = coordinate
                            }
                        }
                    }
                }

                Spacer()

                HStack {
                    Spacer()

                    VStack(spacing: 10) {
                        Button(action: {
                            locationManager.region.span.latitudeDelta /= 2
                            locationManager.region.span.longitudeDelta /= 2
                        }) {
                            Image(systemName: "plus.magnifyingglass")
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                        }

                        Button(action: {
                            locationManager.region.span.latitudeDelta *= 2
                            locationManager.region.span.longitudeDelta *= 2
                        }) {
                            Image(systemName: "minus.magnifyingglass")
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                }
            }
            if let coord = currentSearchCoordinate {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            let newFavorite = FavoriteLocation(coordinate: coord)
                            if let index = favoriteLocations.firstIndex(where: { $0.coordinate.latitude == coord.latitude && $0.coordinate.longitude == coord.longitude }) {
                                favoriteLocations.remove(at: index)
                            } else {
                                favoriteLocations.append(newFavorite)
                            }
                        }) {
                            Image(systemName: "star.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(
                                    favoriteLocations.contains(where: { $0.coordinate.latitude == coord.latitude && $0.coordinate.longitude == coord.longitude }) ? .pink : .gray
                                )
                                .shadow(radius: 5)
                        }
                        .padding()
                        Spacer()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
