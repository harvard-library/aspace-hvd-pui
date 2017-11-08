ArchivesSpacePublic::Application.routes.draw do
  match 'repositories/:rid/resources/:id/digct' => 'resources_addons#digital_object_count', :via => [:get]
end
