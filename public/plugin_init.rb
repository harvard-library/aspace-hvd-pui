# sets up the AppConfig to conform to Harvard's needs
AppConfig[:pui_hide][:subjects] = true
AppConfig[:pui_hide][:agents] = true
AppConfig[:pui_hide][:accessions] = true
AppConfig[:pui_hide][:classifications] = true
AppConfig[:pui_branding_img] = '/assets/hl_logo_alt.png'
AppConfig[:pui_hide][:classification_badge] = true
AppConfig[:pui_hide][:subject_badge] = true
AppConfig[:pui_hide][:agent_badge] = true
AppConfig[:pui_repos] = {'hua' => {:hide => {:subject_badge => false,
                                             :agent_badge => false}}}
AppConfig[:pui_hide][:container_inventory]=true
AppConfig[:pui_page_custom_actions] << {
   'record_type' => ['resource'],
   'erb_partial' => 'shared/csv'
   }
AppConfig[:pui_page_custom_actions] << {
   'record_type' => ['resource', 'archival_object', 'digital_object'], # the jsonmodel type to show for
   'erb_partial' => 'shared/ask'
   }

#AppConfig[:pui_email_enabled] = true

AppConfig[:pui_request_email_fallback_to_address] = 'bobbi_fox@harvard.edu'
AppConfig[:pui_request_email_fallback_from_address] = 'bobbi_fox@harvard.edu'


#AppConfig[:pui_email_delivery_method] = :sendmail
#AppConfig[:pui_email_sendmail_settings] = {
#  location: '/usr/sbin/sendmail',
#  arguments: '-i'
# }

# read in routes
my_routes = File.join(File.dirname(__FILE__), "routes.rb")

Plugins.extend_aspace_routes(my_routes)



## OVERRIDE VARIOUS METHODS/ ADD NEW METHODS
Rails.application.config.after_initialize do

# add "talk directly to solr"
  class ArchivesSpaceClient
    def solr(params)
      url = URI.join(AppConfig[:pui_solr_host], AppConfig[:pui_solr_select])
      url.query = URI.encode_www_form(params)
      do_search(url)
    end
  end
    
# override the resources#index facetting

  Searchable.module_eval do
    def set_up_and_run_search(default_types = [],default_facets=[],default_search_opts={}, params={})
      if default_types.length == 1 && default_types[0] == 'resource'
        default_facets =  %w{repository creators subjects published_agents }
      end
      set_up_advanced_search(default_types, default_facets, default_search_opts, params)
      page = Integer(params.fetch(:page, "1"))
      @results =  archivesspace.advanced_search('/search', page, @criteria)
      if @results['total_hits'].blank? ||  @results['total_hits'] == 0
        raise NoResultsError.new
      else
        process_search_results(@base_search)
      end
    end
  end

# add a digital only action to the resources controller
  class ResourcesController 
    def digital_only
      uri = "/repositories/#{params[:rid]}/resources/#{params[:id]}"
      begin
        @criteria = {}
        @criteria['resolve[]']  = ['repository:id', 'resource:id@compact_resource', 'top_container_uri_u_sstr:id', 'related_accession_uris:id', 'digital_object_uris:id']
        tree_root = archivesspace.get_raw_record(uri + '/tree/root') rescue nil
        @has_children = tree_root && tree_root['child_count'] > 0
        @has_containers = has_containers?(uri)
        @result =  archivesspace.get_record(uri, @criteria)
        @repo_info = @result.repository_information
        @page_title = "#{I18n.t('resource._singular')}: #{strip_mixed_content(@result.display_string)}"
        @context = [{:uri => @repo_info['top']['uri'], :crumb => @repo_info['top']['name']}, {:uri => nil, :crumb => process_mixed_content(@result.display_string)}]
        get_digital_objects(uri, params)
        fill_request_info
      rescue RecordNotFound
        @type = I18n.t('resource._singular')
        @page_title = I18n.t('errors.error_404', :type => @type)
        @uri = uri
        @back_url = request.referer || ''
        render  'shared/not_found', :status => 404
      end
    end

    def get_digital_objects(uri, params)
      page = params.fetch(:page, "1")
      page = Integer(page)
      page_size = Integer(params.fetch(:page_size, AppConfig[:pui_search_results_page_size] ))
      uri_prefix = "/repositories/#{params[:rid]}/archival_objects/"
      r = Regexp.new("#{uri_prefix}(\\d+)")
      @digital_objs = []
      @ids = params.fetch(:ids,'').split(',')
      unless @ids.blank?
      else
        ordered_records = archivesspace.get_record("#{uri}/ordered_records").json.fetch('uris')
        refs = ordered_records.map { |u| u.fetch('ref') }
        dig_results = get_digital_archival_results(uri, refs.length)
        dig_results = dig_results['docs'].map { |doc| doc['uri']}
        dig_results = dig_results.sort_by {|uri| refs.index(uri)}
        @ids = dig_results.grep(r) { |u| r.match(u)[1]}
      end
      slice = @ids[(page - 1) * page_size,page_size]
      search_uris = slice.map{|id| "id:\"#{uri_prefix}#{id}#pui\"" }.join(" OR ")
      begin
        set_up_search(['archival_object'], [], { 'resolve[]' => ['repository:id', 'resource:id@compact_resource', 'ancestors:id@compact_resource', 'top_container_uri_u_sstr:id']}, {}, search_uris)
        @results = archivesspace.search(@query, 1, @criteria)
      rescue Exception => error
        flash[:error] = I18n.t('errors.unexpected_error')
        redirect_back(fallback_location: '/' ) and return
      end
      process_results(@results['results'],false)
      @digital_objs = @results.records.sort_by{ |res| slice.index(r.match(res.uri)[1])}
      @digital_objs.each do |result|
        result['json']['atdig'] = process_digital_instance(result['json']['instances'])
      end
      @pager = Pager.new("/repositories/#{params[:rid]}/resources/#{params[:id]}/digital_only", page, (@ids.length/page_size) + 1)
    end
  end

# add check for digital objects, modified repo name for request

  ResultInfo.module_eval do
    ALEPH_REGEXP =  Regexp.new("^\\d{9}$")
    def fill_request_info
      @request = @result.request_item
# looking for digital objects goes here
      begin
        @digital_count = get_digital_archival_results(@request.request_uri)['numFound'] || 0
      rescue Exception => boom
        STDERR.puts "Error getting digital object count for #{@request.request_uri}: #{boom}"
        @has_digital = false
      end
#Rails.logger.debug("Repo code #{@request['repo_code'] || 'nope!'}")
      @long_repo_name = get_long_repo(@request)
      # extract the aleph_id
      @aleph_id = ''
      resource = ''
      if @result.primary_type == 'resource'
        resource = @result
      else
        resource_uri = @result.breadcrumb.map { |c| c[:uri] if c[:type] == 'resource'}.compact
        unless resource_uri.blank?
          resource =  archivesspace.get_record(resource_uri, {})
        end
      end
      @aleph_id = extract_aleph_id(resource) unless resource.blank?
      @request
    end
    
    def extract_aleph_id(result)
      aleph_id = ''
      unless result.notes['processinfo'].blank?
        notes = result.notes['processinfo']
        label = notes.dig('label') || ''
        if label == 'Aleph ID'
          aleph_id = notes['note_text']
        else notes['subnotes'].each do |sub|
            label = sub['_inline_label'] || ''
            if  label == 'Aleph ID'
              aleph_id = sub['_text']
            end
          end
        end
        if ALEPH_REGEXP.match(aleph_id)
          return aleph_id
        end
      end
      return ''
    end
   # we're going to invert this to get_long_repo, but not yet
   def get_long_repo(request)
     code = request['repo_code']
     long_nm = ""
     if !code.blank?
       code.downcase!
       long_nm = I18n.t("repos.#{code}.long", :default => '' )
#Rails.logger.debug("*** code #{code} yields: #{long_nm} ***")
     end
     long_nm = request['repo_name'] if long_nm.blank?
     long_nm
   end

# this is going to be moved, but I'm putting it here for now
     def get_digital_archival_results(res_id, size = 1)
       solr_params = {'q' => 'digital_object_uris:[\"\" TO *] AND types:pui_archival_object AND publish:true',
         'fq' => "resource:\"#{res_id}\"",
         'rows' => size,
         'fl' => 'id,uri',
         'wt' => 'json' }
       solr_results = archivesspace.solr(solr_params)
       results = solr_results['response']
     end

  end

end 

