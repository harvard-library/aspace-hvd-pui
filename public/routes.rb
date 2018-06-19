ArchivesSpacePublic::Application.routes.draw do
  match 'repositories/:rid/resources/:id/digct' => 'resources_addons#digital_object_count', :via => [:get]
  match 'repositories/:rid/resources/:id/digital_only' => 'resources#digital_only', :via => [:get, :post]
  match 'repositories/:rid/resources/:id/request' => 'resources_addons#request_popup', :via => [:get, :post]
  match 'repositories/:rid/archival_objects/:id/request' => 'resources_addons#request_popup', :via => [:get, :post]
  match 'repositories/:rid/resources/:id/csv' => 'resources_addons#csv_out', :via => [:get], defaults: { format: 'csv' }
  match 'repositories/:rid/resources/:id/hvd_pdf' => 'hvd_pdf#resource', :via => [:get, :post], defaults: { format: 'pdf' }
  match 'repositories/:rid/resources/:id/exp' => 'resources_addons#experiment', :via => [:get, :post]
  match 'id/resource/:eadid' => 'resources_addons#eadid', :via => [:get, :post]
  match 'id/object/:refid' => 'resources_addons#refid',  :via => [:get, :post]
end
