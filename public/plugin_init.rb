# sets up the AppConfig to conform to Harvard's needs
AppConfig[:pui_hide][:accessions] = true
AppConfig[:pui_hide][:classifications] = true
AppConfig[:pui_branding_img] = '/assets/hl_logo_alt.png'
AppConfig[:pui_hide][:classification_badge] = true
# AppConfig[:pui_branding_img] = 'Aspace-logo-transparent.png'
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

## override the resources#index facetting
Rails.application.config.after_initialize do

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
end 

