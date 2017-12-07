class ResourcesAddonsController < ApplicationController
  include ResultInfo

  helper_method :process_repo_info
  helper_method :process_subjects
  helper_method :process_agents

  skip_before_filter :verify_authenticity_token

 # supporting digital object detection
 def digital_object_count
   repo_id = params.require(:rid)
    res_id = "/repositories/#{repo_id}/resources/#{params.require(:id)}"
    results = get_digital_archival_results(res_id, 2)
Pry::ColorPrinter.pp "*********************************"
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
#     rec = @results.records[1]
#     Pry::ColorPrinter.pp "REC"
#     Pry::ColorPrinter.pp rec.json
Pry::ColorPrinter.pp refs
Pry::ColorPrinter.pp "*********************************"
@results.records.each {|record| Pry::ColorPrinter.pp record.json['uri'] }
     results = []
     results = @results.records.sort_by {|record| refs.index(record.json['uri'])}
Pry::ColorPrinter.pp "***** after SORT ****"
results.each {|record| Pry::ColorPrinter.pp record.json['uri'] }
   end
     
Pry::ColorPrinter.pp "TOTAL HITS"
Pry::ColorPrinter.pp Integer(@results['total_hits'])
#Pry::ColorPrinter.pp results[1].json
Pry::ColorPrinter.pp "LENGTH: #{results.length}"
#Pry::ColorPrinter.pp results[0].json
#   Pry::ColorPrinter.pp "Compare with fullnotes:false"
 #  records = archivesspace.search_records(refs, search_opts,false)
#   Pry::ColorPrinter.pp "Number of RECORDS: #{records.length}"
#Pry::ColorPrinter.pp records

 end

 private
 def get_digital_archival_results(res_id, size = 1)
   solr_params = {'q' => 'digital_object_uris:[\"\" TO *] AND types:pui_archival_object AND publish:true',
                  'fq' => "resource:\"#{res_id}\"",
                  'rows' => 1000,
                  'fl' => 'id,uri',
                  'wt' => 'json' }
   solr_results = archivesspace.solr(solr_params)
   results = solr_results['response']
#Pry::ColorPrinter.pp "SOLR RESULTS"
#Pry::ColorPrinter.pp solr_results

#Pry::ColorPrinter.pp "Number found: #{solr_results['response']['numFound']}"
 #   search_opts= {'type[]' => 'pui_archival_object', 'page_size' => size, 'fl' => 'id'}
 #   q = "resource:\"#{res_id}\" AND digital_object_uris:[\"\" TO *]"
 #  results = archivesspace.search(q,1,search_opts)

 end

end
