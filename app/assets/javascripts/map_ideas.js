ideax = {
  map: {
    newMap: function(divId, lat, lon, zoom) {
      ideax.map.geolocating = false  // prevent geoloc callback from overriding user zip entry
      return new google.maps.Map(
        document.getElementById(divId),
        {
          zoom: zoom,
          center: new google.maps.LatLng(lat, lon),
          mapTypeId: google.maps.MapTypeId.ROADMAP
        }
      )
    },

    addIdea: function(map, ideaLat, ideaLon, popupContent) {
      var markerIcon = new google.maps.MarkerImage(
        '/images/idea-marker.png',
        new google.maps.Size(14,19), // size
        new google.maps.Point(0,0),  // origin
        new google.maps.Point(7,16)  // anchor
      )
      var markerShadow = new google.maps.MarkerImage(
        '/images/idea-shadow.png',
        new google.maps.Size(30, 19), // size
        new google.maps.Point(0,0),   // origin
        new google.maps.Point(7,16)   // anchor
      )

      var ideaLoc = new google.maps.LatLng(ideaLat, ideaLon)
      var marker = new google.maps.Marker({
          position:   ideaLoc,
          map:        map, 
          icon:       markerIcon,
          shadow:     markerShadow,
          animation:  google.maps.Animation.DROP
      })
      
      google.maps.event.addListener(marker, 'click', function() {
        if(map.openInfoWindow)
          map.openInfoWindow.close()
        
        var infoWindow = new google.maps.InfoWindow({
          content: popupContent
        })
        infoWindow.open(map, marker)
        map.openInfoWindow = infoWindow
      })
    },
    
    showGeolocatedIdeas: function(ideasRequestCallback) {
      var searchIdeasNearLoc = function(lat, lon) {
        if(ideax.map.geolocating)
          ideasRequestCallback('search[loc]=' + lat + ',' + lon)
      }
      var searchIdeasNearDefault = function () {
        if(ideax.map.geolocating)
          ideasRequestCallback('search[postal_code]=user')
      }
      
      // Adapted from http://code.google.com/apis/maps/documentation/javascript/basics.html#DetectingUserLocation
      var userLocation = null
      ideax.map.geolocating = true
      if(navigator.geolocation) {
        // W3C Geolocation (Preferred)
        navigator.geolocation.getCurrentPosition(function(position) {
          searchIdeasNearLoc(position.coords.latitude, position.coords.longitude)
        }, function() {
          searchIdeasNearDefault()
        }, {
          enableHighAccuracy: false,
          timeout: 15*1000, // 15 sec
          maximumAge: 30*60*1000 // half an hour
        })
      } else if (typeof google != 'undefined' && google.gears) {
        // Google Gears Geolocation
        var geo = google.gears.factory.create('beta.geolocation')
        geo.getCurrentPosition(function(position) {
          searchIdeasNearLoc(position.latitude, position.longitude)
        }, function() {
          searchIdeasNearDefault()
        })
      } else {
        // Browser doesn't support Geolocation
        searchIdeasNearDefault()
      }
    },
    
    showGeolocatedMap: function() {
      ideax.map.showGeolocatedIdeas(
        function(params) {
          new Ajax.Request(
            '/map',
            {
              asynchronous: true,
              evalScripts: true,
              method: 'get',
              parameters: params
            })
        }
      )
    }
  }
}
