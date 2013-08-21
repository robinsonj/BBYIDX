# Search logic shared by public & admin UIs. If you make changes to this code, be sure to test it
# on both the public and admin sides!

module SearchHelper
  
  # Performs a search for ideas based on a set of URL params, dispatching to the SQL or full-text
  # search as appropriate.
  def search_ideas(params)
    unless params[:search_text].blank?
      @body_class = "search"
      @query_title = "Search for \"#{params[:search_text]}\""
      search(Idea, params) do |results|
        results.select { |idea| idea.visible? }
      end
    else
      search_ideas_sql params
    end
  end
  
  # Handles SQL-based (i.e. not full-text) idea searches. Takes an array of search parameters
  # (which typically come from a URL path). For example: ["tag", "kumquats", "recent"]
  def search_ideas_sql(params)
    query_opts = {
      :page => params[:page] || 1,
      :per_page => params[:page_size] || 20,
      :include => [{:inventor => :postal_code}, :tags],
      :conditions => ['users.state = ? and ideas.hidden = ?', 'active', false] }
    @query_title = "Ideas"
    
    search_params = (params[:search] || 'recent').split('/')
    while !search_params.empty? do
      case param = search_params.shift
      when 'recent'
        query_opts[:order] = 'ideas.created_at DESC'
        query_opts[:conditions][0] += ' and ideas.duplicate_of_id is null'
        @query_title = "Recent " + @query_title
        @body_class ||= 'recent'
      when 'hot', 'top-rated'
        query_opts[:order] = 'ideas.rating DESC, ideas.created_at DESC'
        query_opts[:conditions][0] += ' and ideas.duplicate_of_id is null'
        @query_title = "Hot " + @query_title
        @body_class ||= 'top-rated'
      when 'top-voted'
        query_opts[:order] = 'ideas.vote_count DESC, ideas.created_at DESC'
        query_opts[:conditions][0] += ' and ideas.duplicate_of_id is null'
        @query_title = "All-Time Top Voted " + @query_title
        @body_class ||= 'top-rated'
      when 'tag'
        @body_class = "tag"
        tag_name = search_params.shift
        if tag_name
          query_opts[:conditions][0] += ' and ideas.duplicate_of_id is null'
          query_opts[:conditions][0] += ' and tags.name = ?'
          query_opts[:conditions] << tag_name
          @query_title += " Tagged \"#{tag_name}\""
          query_opts[:order] ||= if params[:format] == 'rss'
            'ideas.created_at DESC'
          else
            'ideas.rating DESC, ideas.created_at DESC'
          end
        end
      when 'current'
        current_id = search_params.shift
        query_opts[:conditions][0] += ' and ideas.current_id = ?'
        query_opts[:conditions] << current_id
        @query_title = "Currents " + @query_title
        @body_class ||= 'currents'
      else
        raise "Unknown search parameter \"#{param}\""
      end
    end
    
    Idea.paginate(query_opts)
  end
  
  def geo_search_ideas(search, opts = {})
    if search[:loc]
      latlon = search[:loc].split(/\s*,\s*/).map { |x| x.to_f }
      search_idea_ids_near_loc(latlon[0], latlon[1], opts)
    elsif search[:postal_code]
      if search[:postal_code] == 'user'
        search_idea_ids_near_user(opts)
      else
        postal_code = PostalCode.find_by_text(search[:postal_code])
        return [] unless postal_code
        @search = OpenStruct.new(:postal_code => postal_code.code)
        search_idea_ids_near_postal_code(postal_code, opts)
      end
    end
  end
  
private
  
  # Handles geography-based searches
  def search_idea_ids_near_user(opts = {})
    postal_code = current_user.postal_code if logged_in?
    postal_code ||= PostalCode.find_by_text DEFAULT_ZIP_CODE
    search_idea_ids_near_postal_code(postal_code, opts)
  end
  
  def search_idea_ids_near_postal_code(postal_code, opts = {})
    return search_ideas_near_user(opts) if postal_code == 'user'
    
    if postal_code
      search_idea_ids_near_loc(postal_code.lat, postal_code.lon, opts)
    else
      raise "You probably need to load your postal code seed data"
    end
  end
  
  def search_idea_ids_near_loc(lat, lon, opts = {})
    # This code uses a cheap flat earth distance formula, which is probably fine since it's only
    # used for sorting -- we never display the distance to the user. If we decide we actually care,
    # we can change it to use the more DB-taxing trig ... or even better, use a GIS plugin. -PPC
    Idea.find(:all,
      opts.reverse_merge(
        :select =>
        "ideas.id,
        pow(lat - (#{lat}), 2) + pow(lon - (#{lon}), 2) as distance",
      :conditions => [
        'lat > ? and lat < ? and lon > ? and lon < ? and users.state = ? and ideas.hidden = ? and ideas.marked_spam = ?',
        lat - 4.0, lat + 4.0,
        lon - 4.6, lon + 4.6,
        'active', false, false],
      :joins => {:inventor => :postal_code},
      :limit => 60,
      :order => 'distance, ideas.created_at desc'))
  end

public
  
  # Searches for an arbitrary model using a full-text tsearch query. Shared by public & admin UI.
  def search(current_model, params, sort = nil, order = true, &filter)
    page = (params[:page] || 1).to_i
    page_size = (params[:per_page] || 30).to_i
    
    @search = current_model.find_by_tsearch(params[:search_text] || params[:search])
  
    WillPaginate::Collection.create(page, page_size, @search.size) do |pager|
      pager.replace(yield(@search))
    end
  end
  
end
