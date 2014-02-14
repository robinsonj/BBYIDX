class HomeController < ApplicationController

  def show
    @@verified_installation ||= false
    unless @@verified_installation
      if PostalCode.count == 0
        render :text =>
          "<h1>Database not seeded</h1>
           <p>To initialize the database, please run:</p>
           <blockquote><tt>rake db:seed</tt></blockquote>"
        return
      end
      if User.count == 0
        logger.info "No users found. Redirecting to create first user: " + new_user_path
        redirect_to new_user_path
        return
      end
      @@verified_installation = true
    end

    @body_class = params[:page].nil? ? 'home' : params[:page]
    render :action => params[:page] || 'show'
  end

  def nearby_ideas
    ideas = Idea.find(geo_search_ideas(params[:search], :limit => 5))
    render :partial => 'idea', :collection => ideas
  end

  # Experimental wacky fractal tag cloud (currently unused):

  def render_idea_cloud(opts)
    logger.warn("selecting idea cloud!")
    @cloud_layout = nil
    opts[:searches].each do |search|
      new_ideas = search_ideas(:page_size => opts[:count], :search => search)
      new_cloud = cloud(new_ideas, opts.merge(:search => search))
      if @cloud_layout
        @cloud_layout.merge!(new_cloud)
      else
        @cloud_layout = new_cloud
      end
    end
    render :partial => 'cloud', :locals => opts.merge(:boxes => @cloud_layout.boxes)
  end
  helper_method :render_idea_cloud

  def cloud(ideas, opts = {})
    top_rated = opts[:search].include?('hot')
    opts.reverse_merge!(
      :density           => 0.5,
      :favor_largest     => 0.4,
      :placements        => [0, 1, 0, 1],
      :initial_placement => top_rated ? [0, 0] : [1, 1],
      :color_scheme      => Layout::GradientColorScheme.new(
                              if top_rated
                                ['ff2d16', 'ff7600', 'ffb46e', 'ffffff']
                              else
                                ['152333', '005f86', '85dfe2', 'ffffff']
                              end))
    idea_sizer = if top_rated
      lambda { |idea| (idea.rating + 1) ** 0.5 }
    else
      lambda { |idea| (ideas.size / (ideas.index(idea) + 1.0) - 0.9) ** 1 }
    end
    Layout::FractalScatter.new(ideas, opts, &idea_sizer)
  end

  def cloud_style(boxes)
    idea = boxes.object
    " font-size: #{Math.sqrt(boxes.area / (idea.title.size + 1)) * 0.9}px;
      line-height: 0.9em;
      text-align: center;
      /*overflow: hidden;
      text-overflow: ellipsis;*/

      color: #{boxes.color};

      position: absolute;
      left:   #{boxes.left}px;
      top:    #{boxes.top}px;
      width:  #{boxes.width}px;
      height: #{boxes.height}px
    ".gsub(/[\r\n]/, '')
  end
  helper_method :cloud_style

  include ApplicationHelper

end

