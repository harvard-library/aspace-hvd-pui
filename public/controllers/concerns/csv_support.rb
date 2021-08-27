module CsvSupport

  extend ActiveSupport::Concern

  def csv_data
   lines = []
   uri = "/repositories/#{params[:rid]}/resources/#{params[:id]}"
   begin
     ordered_records = archivesspace.get_record("#{uri}/ordered_records").json.fetch('uris')
     depths = ordered_records.map { |u| u.fetch('depth')}
     levels = depths.uniq.sort.last.to_i
     @criteria = {}
     @criteria['resolve[]']  = ['repository:id', 'resource:id@compact_resource', 'top_container_uri_u_sstr:id' ]
     result =  archivesspace.get_record(uri, @criteria)
     lines.concat(collection_header(result))
     lines.concat(get_objects_header(levels))
     lines.concat(get_objects(ordered_records,levels)) if levels > 0
     lines
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
    lines << [I18n.t('csv.resource_creator'), get_creator_string(result.agents)] unless get_creator_string(result.agents).blank?
    lines << [I18n.t('csv.resource_ref_id'), result.identifier]
    lines << [I18n.t('csv.ead_id'), result.ead_id]
    lines << [I18n.t('csv.restrict'), get_access_note(result.notes)] unless get_access_note(result.notes).blank?
    lines << []
    lines
  end

 def get_objects_header(levels = 2)
   head = []
   %w{ref_id title date s_year e_year id container type creator urn restrict phys}.each do |k|
     head << I18n.t("csv.#{k}")
   end
   (1..(levels - 1)).each do |i|
     head << I18n.t('csv.parent', :i => i)
   end
   [head]
 end
 def get_objects(ordered_recs, levels = 2)
   lines = []
   if levels > 0
     list = ordered_recs.map {|u| "#{u.fetch('ref')}#pui" }
     @levels = Array.new(levels - 1,'')
     # get recs 20 at at time
     (1..(list.length-1)).step(20) do |start|
       stop = start + 19

       res = archivesspace.search_and_sort_records(list.slice(start,20).compact, { 'page_size' => (stop - start + 1)})
       res.records.each_index do |i|
         result = res.records[i]
#Rails.logger.debug(result.json.pretty_inspect) if i < 3 && start == 1
         if result.json['publish']
           level = ordered_recs[start + i]['depth']
           @levels[level] =  strip_mixed_content(result.json['title'])
           @levels.fill('', (level+1)..(@levels.length - 1))
           line = []
           line << result.json['ref_id']
           line << strip_mixed_content(result.json['title']) || ''
           line.concat(get_date_subset(result.json))
           line << result.identifier || ''
           line << result.container_summary_for_badge || ''
           line << result.json['level'] ||''
           line << get_creator_string(result.agents)
           line << get_digital_urn(result.json)
           line << get_access_note(result.json)
           line << get_phys_desc(result.json)
           line.concat(compute_levels(level))
           lines << line
         end
       end
     end
   end
   lines
 end
 
 def compute_levels(depth)
   compute = Array.new(@levels)
   compute.fill(' ', depth..(@levels.length - 1))
   compute.slice!(0)
   compute = compute.slice(0,@levels.length - 1)
   compute
 end

 def get_access_note(json)
   access = ''
   unless json['notes'].blank?
     json['notes'].each do |note|
       if note['type'] == 'accessrestrict' && note['_inherited'].blank?
         if note.has_key?('subnotes')
           note['subnotes'].each do |subnote|
             if subnote['publish'] && subnote['jsonmodel_type'] == 'note_text'
               access << subnote['content'] + '  '
             end
           end
         else
           access << note['note_text'] if note['publish']
         end
       end
     end
   end
   strip_mixed_content(access)
 end

 def get_creator_string(agents)
   creators = []
   unless agents['creator'].blank? 
     agents['creator'].each do |agent|
       unless agent['_resolved'].blank? || !agent['_inherited'].blank? 
         creators << agent['_resolved']['title'] || nil
       end
     end
     strip_mixed_content(creators.compact.join(", "))
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


 def get_date_subset(json)
   exp = []
   beg = []
   en = []
   unless json['dates'].blank?
     json['dates'].each do |date|
       exp << date['expression'] || ''
       beg << date['begin'] || ''
       en <<  date['end'] || ''
     end
   end
   [exp.join(' '), beg.join(' '), en.join(' ')]
 end

 def get_digital_urn(json)
   urn = ''
   unless json['instances'].blank?
     json['instances'].each do |inst|
       if inst.dig('digital_object', '_resolved', 'publish')
         file_vers = inst.dig('digital_object', '_resolved', 'file_versions') || []
         file_vers.each do |ver |
           if ver['publish']
             urn = ver['file_uri'] if ver['xlink_actuate_attribute'] == 'onRequest'
             break if !urn.blank?
           end
         end
       end
     end
   end
   urn
 end

 def get_phys_desc(json)
   type = ''
   unless json['extents'].blank?
     json['extents'].each do |ext|
       type << ' ' << (ext['number'] || '') << ' ' << (ext['extent_type'] || '') if ext['jsonmodel_type'] == 'extent' && ext['_inherited'].blank?
     end
   end
   type.strip
 end

end
