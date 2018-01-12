class ResourcesAddonsController < ApplicationController
  include ResultInfo
  require 'csv'

  helper_method :process_repo_info
  helper_method :process_subjects
  helper_method :process_agents

  skip_before_filter :verify_authenticity_token



 # produce a CSV
 def csv_out
  # we'll get the stuff later, but for now, hard-setting file name
   collection_id = params[:id]
   file_name = "collection_#{collection_id}"
   lines = data_csv(params)
   @data = CSV.generate do |csv|
     lines.each do |line|
       csv << line
     end
   end
   respond_to do |format|
     format.csv {
       headers['Content-Disposition'] = "attachment; filename=\"#{file_name}.csv\""
       headers['Content-Type'] ||= 'text/csv'
       render plain: @data}
   end
 end

 def data_csv(params)
   lines = []
   uri = "/repositories/#{params[:rid]}/resources/#{params[:id]}"
   begin
      ordered_records = archivesspace.get_record("#{uri}/ordered_records").json.fetch('uris')
     depths = ordered_records.map { |u| u.fetch('depth')}
     @levels = depths.uniq.sort.last.to_i
     Pry::ColorPrinter.pp "Levels: #{@levels}"
     @criteria = {}
     @criteria['resolve[]']  = ['repository:id', 'resource:id@compact_resource', 'top_container_uri_u_sstr:id' ]
     @result =  archivesspace.get_record(uri, @criteria)
     lines << [I18n.t('csv.resource_title'),strip_mixed_content(@result.display_string)]
     lines << [I18n.t('csv.resource_dates'), get_dates_string(@result.dates)]
     lines << [I18n.t('csv.resource_creator'), get_creator_string(@result.agents)]
     lines << [I18n.t('csv.resource_ref_id'), @result.identifier]
     lines << [I18n.t('csv.ead_id'), @result.ead_id]
     lines << []
     lines << []
     lines << get_csv_headers(@levels)
     
   rescue RecordNotFound
     @type = I18n.t('resource._singular')
      @page_title = I18n.t('errors.error_404', :type => @type)
      @uri = uri
      @back_url = request.referer || ''
      render  'shared/not_found', :status => 404
    end
 end


 # supporting digital object detection
 def digital_object_count
   repo_id = params.require(:rid)
    res_id = "/repositories/#{repo_id}/resources/#{params.require(:id)}"
    results = get_digital_archival_results(res_id, 2)
# Pry::ColorPrinter.pp "*********************************"
    render(partial: 'resources/digital_count', locals: {:count => results['numFound']})
  end
 
 # fetch only archival objects that have associated digital objects
 def digital_objects
   repo_id = params.require(:rid)
   res_id = "/repositories/#{repo_id}/resources/#{params.require(:id)}"
   ordered_records = archivesspace.get_record("#{res_id}/ordered_records").json.fetch('uris')
   refs = ordered_records.map { |u| u.fetch('ref') }
Pry::ColorPrinter.pp "Number REFs #{refs.length}"
   @results = get_digital_archival_results(res_id, refs.length)
   if Integer(@results['total_hits']) > 0
     results = get_sorted_arch_digital_objects(@results.records, refs)
   end
 end

 private

 def get_csv_headers(levels = 2)
   headers = []
   %w{ref_id title date s_year e_year id type creator}.each do |k|
     headers << I18n.t("csv.#{k}")
   end
   (1..3).each do |i|
     headers << I18n.t('csv.container', :i => i)
   end
   (1..3).each do |i|
     headers << I18n.t('csv.phys', :i => i)
   end
   %w{loc restrict urn}.each do |k|
     headers << I18n.t("csv.#{k}")
   end
   (1..levels).each do |i|
     headers << I18n.t('csv.parent', :i => i)
   end
   headers
 end


 def get_creator_string(agents)
   creators = []
   unless agents['creator'].blank?
     agents['creator'].each do |agent|
       unless agent['_resolved'].blank?
         creators << agent['_resolved']['title'] || nil
       end
     end
     creators.compact.join(", ")
   end
 end

 def get_dates_string(in_dates)
   dates = []
   unless in_dates.blank?
     in_dates.each do |date|
         dates << date['final_expression'] if date['_inherited'].blank?
     end
   end
   dates.compact.join(", ")
 end

 def get_sorted_arch_digital_objects(records, refs)
   results = []
   results = @results.records.sort_by {|record| refs.index(record.json['uri'])}
 end

end
