class ResourcesAddonsController < ApplicationController
  include ResultInfo
  include CsvSupport
  require 'csv'
  require 'pp'  # temporary, she hopes!
  helper_method :process_repo_info
  helper_method :process_subjects
  helper_method :process_agents

  skip_before_filter :verify_authenticity_token

 # produce a CSV
 def csv_out
  # we'll get the stuff later, but for now, hard-setting file name
   collection_id = params[:id]
   file_name = "collection_#{collection_id}"
   lines = csv_data
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


 # supporting digital object detection
 def digital_object_count
   repo_id = params.require(:rid)
    res_id = "/repositories/#{repo_id}/resources/#{params.require(:id)}"
    results = get_digital_archival_results(res_id, 2)
    render(partial: 'resources/digital_count', locals: {:count => results['numFound']})
  end
 
 # fetch only archival objects that have associated digital objects
 def digital_objects
   repo_id = params.require(:rid)
   res_id = "/repositories/#{repo_id}/resources/#{params.require(:id)}"
   ordered_records = archivesspace.get_record("#{res_id}/ordered_records").json.fetch('uris')
   refs = ordered_records.map { |u| u.fetch('ref') }
   @results = get_digital_archival_results(res_id, refs.length)
   if Integer(@results['total_hits']) > 0
     results = get_sorted_arch_digital_objects(@results.records, refs)
   end
 end

 # display a resource given an eadid
 def eadid
#   Rails.logger.debug(env.pretty_inspect)
   results = archivesspace.search("ead_id:#{params[:eadid]}")
   uri = nil
   unless results['total_hits'] == 0
     results = results['results']
     uri = results[0]['uri'] if  results[0]['publish']
   end
   if uri
     redirect_to(uri)
#     archivesspace.internal_request(uri)
   else
     render 'shared/not_found', :status => 404
   end
   
  end

 private

 
 def get_sorted_arch_digital_objects(records, refs)
   results = []
   results = @results.records.sort_by {|record| refs.index(record.json['uri'])}
 end

end
