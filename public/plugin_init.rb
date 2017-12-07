# sets up the AppConfig to conform to Harvard's needs
AppConfig[:pui_hide][:accessions] = true
AppConfig[:pui_hide][:classifications] = true
AppConfig[:pui_branding_img] = '/assets/hl_logo_alt.png'
AppConfig[:pui_hide][:classification_badge] = true
AppConfig[:pui_page_custom_actions] << {
   'record_type' => ['resource'], # the jsonmodel type to show for
   'erb_partial' => 'shared/test'
   }
#AppConfig[:pui_email_enabled] = true

AppConfig[:pui_request_email_fallback_to_address] = 'bobbi_fox@harvard.edu'
AppConfig[:pui_request_email_fallback_from_address] = 'bobbi_fox@harvard.edu'


#AppConfig[:pui_email_delivery_method] = :sendmail
#AppConfig[:pui_email_sendmail_settings] = {
#  location: '/usr/sbin/sendmail',
#  arguments: '-i'
# }
AppConfig[:pui_solr_host] = 'http://172.31.28.91:8090'
AppConfig[:pui_solr_select] = '/collection1/select'

# read in routes
my_routes = File.join(File.dirname(__FILE__), "routes.rb")
Pry::ColorPrinter.pp my_routes
Plugins.extend_aspace_routes(my_routes)



## OVERRIDE VARIOUS METHODS/ ADD NEW METHODS
Rails.application.config.after_initialize do

# add "talk directly to solr"
  class ArchivesSpaceClient
    def solr(params)
      url = URI.join(AppConfig[:pui_solr_host], AppConfig[:pui_solr_select])
      url.query = URI.encode_www_form(params)
Pry::ColorPrinter.pp "SOLR SEARCH URL: #{url}"
      do_search(url)
    end
  end
    
# override the resources#index facetting

  Searchable.module_eval do
    def set_up_and_run_search(default_types = [],default_facets=[],default_search_opts={}, params={})
      if default_types.length == 1 && default_types[0] == 'resource'
        default_facets =  %w{primary_type creators subjects published_agents }
        Pry::ColorPrinter.pp ["FACETS:", default_facets]
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
      @digital_objs = []
      if params.fetch(:ids, false)
Pry::ColorPrinter.pp "have ids"
      else
Pry::ColorPrinter.pp "dont have ids"
        ordered_records = archivesspace.get_record("#{uri}/ordered_records").json.fetch('uris')
Pry::ColorPrinter.pp ordered_records[0]
        refs = ordered_records.map { |u| u.fetch('ref') }
Pry::ColorPrinter.pp "REFS: #{refs}"
        dig_results = get_digital_archival_results(uri, refs.length)
        dig_results = dig_results['docs'].map { |doc| doc['uri']}
Pry::ColorPrinter.pp dig_results
        dig_results = dig_results.sort_by {|uri| refs.index(uri)}
Pry::ColorPrinter.pp "DIG : #{dig_results}"
      end

    end
  end

# add check for digital objects

  ResultInfo.module_eval do
    def fill_request_info
      @request = @result.request_item
# looking for digital objects goes here
      begin
        @digital_count = get_digital_archival_results(@request.request_uri)['numFound'] || 0
      rescue Exception => boom
        STDERR.puts "Error getting digital object count for #{@request.request_uri}: #{boom}"
        @has_digital = false
      end
      Pry::ColorPrinter.pp  @has_digital 
      @request
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

