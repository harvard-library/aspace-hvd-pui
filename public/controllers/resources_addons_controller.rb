class ResourcesAddonsController < ApplicationController

 # supporting digital object detection
 def digital_object_count
    repo_id = params.require(:rid)
    res_id = "/repositories/#{repo_id}/resources/#{params.require(:id)}"
#    search_opts['fq'] = ["resource:\"#{res_id}\""]
    search_opts= {'type[]' => 'pui_archival_object', 'page_size' => 1}
    q = "resource:\"#{res_id}\" AND digital_object_uris:[\"\" TO *]"
   results = archivesspace.search(q,1,search_opts)
#    Pry::ColorPrinter.pp results['total_hits']
    render(partial: 'resources/digital_count', locals: {:count => results['total_hits']})
  end

end
