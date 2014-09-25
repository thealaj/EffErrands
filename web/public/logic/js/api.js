var service = new google.maps.DistanceMatrixService();
service.getDistanceMatrix(
  {
    origins: [], // Origin values from Kizzle array
    destinations: [], // Destination values from Kizzle array
    travelMode: google.maps.TravelMode.WAKLING,
    unitSystem: UnitSystem,
    durationInTraffic: Boolean,
  }, callback);

function callback(response, status) {
  if (status == google.maps.DistanceMatrixStatus.OK) {
    var origins = response.originAddresses;
    var destinations = response.destinationAddresses;

    for (var i = 0; i < origins.length; i++) {
      var results = response.rows[i].elements;
      for (var j = 0; j < results.length; j++) {
        var element = results[j];
        var distance = element.distance.text;
        var duration = element.duration.text;
        var from = origins[i];
        var to = destinations[j];
      }
    }
  }
}