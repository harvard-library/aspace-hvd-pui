# sets up the AppConfig to conform to Harvard's needs
AppConfig[:pui_hide][:subjects] = true
AppConfig[:pui_hide][:agents] = true
AppConfig[:pui_hide][:accessions] = true
AppConfig[:pui_hide][:classifications] = true
AppConfig[:pui_branding_img] = '/assets/hl_logo_alt.png'
AppConfig[:digital_accessibility_link] = 'https://accessibility.huit.harvard.edu/digital-accessibility-policy'
AppConfig[:harmful_language_statement_link] = 'http://nrs.harvard.edu/URN-3:HUL.OIS:ASPACEPUI-LANGUAGE'
AppConfig[:privacy_link] = 'https://library.harvard.edu/privacy-terms-use-copyright-information'
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

  ##### BEGIN BLOCK TO FIX BUG IN ASPACE CORE #####
  # The code in this section is related to this issue in core ASpace: https://github.com/archivesspace/archivesspace/issues/2177
  # The issue has been resolved, but as of the 3.0.2RC on 8/9/21 has not made it into a release
  # When the commits listed in that issue have made it into the release that this plugin is running on
  # this code block can be removed

  module I18n
    def self.prioritize_plugins!
        self.load_path = self.load_path.reject { |p| p.match /plugins\// } + self.load_path.reject { |p| !p.match /plugins\// }
    end
  end

  I18n.prioritize_plugins!
  I18n.load_path = I18n.load_path.reject { |p| !p.match /frontend\// } + I18n.load_path.reject { |p| p.match /frontend\// }

  ##### END BLOCK TO FIX BUG IN ASPACE CORE #####

# add "talk directly to solr"
  class ArchivesSpaceClient
    def solr(params)
      url = URI.join(AppConfig[:pui_solr_host], AppConfig[:pui_solr_select])
      url.query = URI.encode_www_form(params)
      do_search(url)
    end
    # do an internal redirect? from https://coderwall.com/p/gghtkq/rails-internal-requests
    # commenting that out for now; just doing a redirect
    def internal_request(path, params={})
#      request_env = Rack::MockRequest.env_for(path, params: params.to_query) #.merge({
#                                      'rack.session' => session  # remove if session is unavailable/undesired in request
#                                                                                   })
      # Returns: [ status, headers, body ]
#      Rails.application.routes.call(request_env)
      ActionController::Redirecting.redirect_to(path)
    end

    # This method is intended to duplicate the functionality of search_records from aspace core, with the
    # only difference being that the sort in core was updated to sort by 'uri' instead of 'id'
    # This broke the order of our csv downloads. This new method has been created rather than overwriting
    # the one in core to avoid unintended side effects
    def search_and_sort_records(record_list, search_opts = {}, full_notes = false)
      search_opts = DEFAULT_SEARCH_OPTS.merge(search_opts)

      url = build_url('/search/records', search_opts.merge("uri[]" => record_list))
      results = do_search(url)

      # Ensure that the order of our results matches the order of `record_list`
      results['results'] = results['results'].sort_by {|result| record_list.index(result.fetch('id'))}

      SolrResults.new(results, search_opts, full_notes)
    end
  end
# override the citation construction
  class Resource
    def reset_cite
      @cite = redo_cite
    end
    def cite_url_and_timestamp
      "#{AppConfig[:pui_perma]}/ead/#{@json['ead_id']}/catalog  #{I18n.t('accessed')}  #{Time.now.strftime("%B %d, %Y")}"
    end
    def redo_cite
      cite = note('prefercite')
      unless cite.blank?
        cite = strip_mixed_content(cite['note_text'])
      else
        cite =  strip_mixed_content(display_string) +  '.'
        unless repository_information['top']['code'].blank?
          cite  += " #{get_long_repo(repository_information['top'])}."
        end
      end
      cite += " #{cite_url_and_timestamp}"
      cite
    end
  end

  class Record
    def get_this_components_id
      # We want the component_id for this specific object, and do not want to return it if
      # it's using an inherited id
      if json.include?('component_id_inherited')
        return ''
      end
      json.fetch('component_id', '')
    end
  end


  class ArchivalObject
    include ResultInfo
    attr_reader :cite

    def reset_cite
      @cite = redo_cite
    end
    def cite_url_and_timestamp
      "#{AppConfig[:pui_perma]}/ead/c/#{@json['ref_id']}/catalog  #{I18n.t('accessed')}  #{Time.now.strftime("%B %d, %Y")}"
    end

    def redo_cite
      cite = note('prefercite')
      unless cite.blank?
        cite = strip_mixed_content(cite['note_text'])
      else
        cite = strip_mixed_content(display_string) +   "."
        if resolved_resource
          ttl = resolved_resource.dig('title')
          cite  += " #{strip_mixed_content(ttl)}" unless !ttl
          cite  += "," unless cite.end_with?(',')
          cite  += " #{identifier}"
          cite  += "."
        end
        cite  +=  " #{get_long_repo(repository_information['top'])}. " unless !repository_information['top']
      end
      cite += " #{ cite_url_and_timestamp}"
      cite
    end
  end


  class DigitalObject
    include ResultInfo
#    require 'pp'
    def reset_cite
      @cite = redo_cite


    end
    def cite_url_and_timestamp
      "#{AppConfig[:pui_perma]}/ead/d/#{@identifier}/catalog  #{I18n.t('accessed')}  #{Time.now.strftime("%B %d, %Y")}"
    end

    def redo_cite
#   Rails.logger.debug(repository_information['top'].pretty_inspect) unless repository_information.blank?
     cite = note('prefercite')
      unless cite.blank?
        cite = strip_mixed_content(cite['note_text'])
      else
        cite = strip_mixed_content(display_string) +   "."
        if resolved_resource
          ttl = resolved_resource.dig('title')
          cite  += " #{strip_mixed_content(ttl)}" unless !ttl
          cite  += "." unless cite.end_with?('.')
        end
        cite  +=  " #{get_long_repo(repository_information['top'])}. " unless repository_information['top'].blank?
      end
      cite += " #{ cite_url_and_timestamp}"
      cite
    end
  end


# Override some assumed defaults in the core code
  Searchable.module_eval do
    alias_method :core_set_up_and_run_search, :set_up_and_run_search
    alias_method :core_set_up_advanced_search, :set_up_advanced_search
    alias_method :core_process_search_results, :process_search_results

    # if a digital object is returned, replace with archival object
    def process_search_results(base="/search")
#      Rails.logger.debug("*** In plugin process search results")
      record_crit  = {"resolve[]"=>   ["repository:id", "resource:id@compact_resource",
                                        "ancestors:id@compact_resource",
                                        "top_container_uri_u_sstr:id"]}
      unless @results.records.blank?
        @results.records.each_with_index do |result, inx|
          if result['primary_type'] == 'digital_object'
            unless result['linked_instance_uris'].blank?
              link = "#{result['linked_instance_uris'][0]}#pui"
              begin
                arch_obj = archivesspace.get_record(link, record_crit)
                @results.records[inx] = arch_obj
              rescue  Exception => error
                Rails.logger.debug("**** Unable to find archival object #{link} for #{result['uri']} [with message #{error.message}")
              end
            end
          end
        end
      end
      core_process_search_results(base)
    end

    # override the resources#index faceting
    def set_up_and_run_search(default_types = [],default_facets=[],default_search_opts={}, params={})

      if default_types.length == 1 && default_types[0] == 'resource'
        default_facets =  %w{repository creators subjects published_agents }

      end
      unless default_types.blank?
        default_types.delete('agent')
        default_types.delete('subject')
      end
      core_set_up_and_run_search(default_types, default_facets, default_search_opts, params)
    end
  # we don't want to see agents or subjects in the search results, only in facets
   def set_up_advanced_search(default_types = [],default_facets=[],default_search_opts={}, params={})
     unless default_types.blank?
       default_types.delete('agent')
       default_types.delete('subject')
     end
     core_set_up_advanced_search(default_types, default_facets, default_search_opts, params)
   end
  end

# fix multiple facets problem?
  class FacetFilter
    def get_facet_types
      self.facet_types.uniq!
       Rails.logger.debug("hvd returning facets #{self.facet_types}")
      self.facet_types
    end
  end

# reassign page numbers for pagination
  class Pager
    Pager::PAGE_NUMBERS_TO_SHOW
    Pager::PAGE_NUMBERS_TO_SHOW = 5
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
      if @ids.blank?
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
      @pager = Pager.new("/repositories/#{params[:rid]}/resources/#{params[:id]}/digital_only", page, ((@ids.length % page_size == 0) ? @ids.length/page_size : (@ids.length/page_size) + 1))
    end
  end

# add check for digital objects, modified repo name for request

  ResultInfo.module_eval do
    ALEPH_REGEXP =  /\A\d{9}\z/
    ALMA_REGEXP = /\A99\d+3941\z/
    def fill_request_info
      @request = @result.request_item
# looking for digital objects goes here
      begin
        @digital_count = get_digital_archival_results(@request.request_uri)['numFound'] || 0
      rescue Exception => boom
        STDERR.puts "Error getting digital object count for #{@request.request_uri}: #{boom}"
        @has_digital = false
      end
      @long_repo_name = get_long_repo(@request)
      # extract the aleph_id and alma ids
      @aleph_id = ''
      @alma_id = ''
      resource = ''
      @result.reset_cite if @result.respond_to? :reset_cite
      if @result.primary_type == 'resource'
        resource = @result
      else @result.primary_type == 'resource'
        resource_uri = @result.breadcrumb.map { |c| c[:uri] if c[:type] == 'resource'}.compact
        unless resource_uri.blank?
          resource =  archivesspace.get_record(resource_uri, {})
        end
      end
      extract_hollis_ids(resource) unless resource.blank?
      @request
    end

    # yes, this is very clumsy
    def extract_hollis_ids(result)
      aleph_id = ''
      alma_id = ''
      unless result.notes['processinfo'].blank?
        notes = result.notes['processinfo'][0]
        label = notes.dig('label') || ''
        if label == 'Aleph ID'
          aleph_id = notes['note_text']
        elsif label.downcase == 'alma id'
          alma_id =  notes['note_text']
        else notes['subnotes'].each do |sub|
            label = sub['_inline_label'] || ''
            if  label == 'Aleph ID'
              aleph_id = sub['_text']
            elsif label.downcase == 'alma id'
              alma_id = sub['_text']
            end
          end
        end
        if ALEPH_REGEXP.match(aleph_id)
          @aleph_id = aleph_id
        end
        if ALMA_REGEXP.match(alma_id)
          @alma_id = alma_id
        end
      end
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
      long_nm = request['repo_name'] || request['name'] if long_nm.blank?
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
