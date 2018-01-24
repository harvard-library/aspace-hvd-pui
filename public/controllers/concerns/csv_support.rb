module CsvSupport

  extend ActiveSupport::Concern

  def csv_data
   lines = []
   uri = "/repositories/#{params[:rid]}/resources/#{params[:id]}"
   begin
     ordered_records = archivesspace.get_record("#{uri}/ordered_records").json.fetch('uris')
#     ordered_list = ordered_records.map {|u| "#{u.fetch('ref')}#pui" }
#     ordered_hash = ordered_list.each_with_index.to_h
#     Pry::ColorPrinter.pp ordered_hash
     depths = ordered_records.map { |u| u.fetch('depth')}
     @levels = depths.uniq.sort.last.to_i
     Pry::ColorPrinter.pp "Levels: #{@levels}"
     @criteria = {}
     @criteria['resolve[]']  = ['repository:id', 'resource:id@compact_resource', 'top_container_uri_u_sstr:id' ]
     result =  archivesspace.get_record(uri, @criteria)
     lines.concat(collection_header(result))
     lines.concat(get_csv_details(ordered_records))
   rescue RecordNotFound
     @type = I18n.t('resource._singular')
      @page_title = I18n.t('errors.error_404', :type => @type)
      @uri = uri
      @back_url = request.referer || ''
      render  'shared/not_found', :status => 404
    end

  end
  def collection_header(result)
    lines = []
    lines << [I18n.t('csv.resource_title'),strip_mixed_content(result.display_string)]
    lines << [I18n.t('csv.resource_dates'), get_dates_string(result.dates)]
    lines << [I18n.t('csv.resource_creator'), get_creator_string(result.agents)]
    lines << [I18n.t('csv.resource_ref_id'), result.identifier]
    lines << [I18n.t('csv.ead_id'), result.ead_id]
    lines << []
    lines << []
    lines
  end
end
