require 'ostruct'

class MapsController < ApplicationController

  def show
    @body_class = 'nearby'

    if params[:idea_ids]
      idea_ids = params[:idea_ids].split(/\s+|,/)
      @body_class = nil  # These ideas aren't necessarily nearby
    elsif search = params[:search]
      idea_ids = geo_search_ideas(search)
    else
      @map = 'ideax.map.showGeolocatedMap()'
    end
    
    if idea_ids
      ideas = Idea.find(idea_ids, :include => [{:inventor => :postal_code}, :tags])
      Idea.populate_comment_counts(ideas)
      @map = map_ideas(ideas)
    end
    
    respond_to do |format|
      format.html do
        if ajax_request?
          render :text => @map
        end
      end
    end
  end
  
  def page_title
    "Idea Map"
  end
  
  include ApplicationHelper
  
private
  
  # Returns javascript to populate a map in a div named 'map' with the given ideas.
  def map_ideas(ideas, default_center = DEFAULT_MAP_CENTER)
    js = []
    js << "var map = ideax.map.newMap('map', #{default_center[0]}, #{default_center[1]}, #{DEFAULT_MAP_ZOOM})"
    
    marker_lats, marker_lons = [], []
    ideas.each do |idea|
      zip = idea.inventor && idea.inventor.postal_code
      if zip
        popup_content = render_to_string(
          :partial => 'maps/idea_popup',
          :locals => { :idea => idea })
        
        lat = zip.lat + rand * 0.012
        lon = zip.lon + rand * 0.030
        marker_lats << lat
        marker_lons << lon
        
        js << "ideax.map.addIdea(
          map, #{lat}, #{lon},
          '#{escape_javascript(popup_content)}')"
      end
    end
    
    if !marker_lats.empty?
      js << "map.fitBounds(
        new google.maps.LatLngBounds(
          new google.maps.LatLng(#{marker_lats.min}, #{marker_lons.min}),
          new google.maps.LatLng(#{marker_lats.max}, #{marker_lons.max})))"
    end
    
    js.join("\n")
  end
  
end
