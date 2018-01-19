ArchivesSpacePublic::Application.routes.draw do
  match 'repositories/:rid/resources/:id/aleph' => 'resources_addons#aleph', :via => [:get]
  match 'repositories/:rid/resources/:id/digct' => 'resources_addons#digital_object_count', :via => [:get]
  match 'repositories/:rid/resources/:id/digital_only' => 'resources#digital_only', :via => [:get, :post]
  match 'repositories/:rid/resources/:id/request' => 'resources_addons#request_popup', :via => [:get, :post]
  match 'repositories/:rid/archival_objects/:id/request' => 'resources_addons#request_popup', :via => [:get, :post]
  match 'repositories/:rid/resources/:id/csv' => 'resources_addons#csv_out', :via => [:get], defaults: { format: 'csv' }
end
