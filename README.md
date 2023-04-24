# aspace-hvd-pui
The customizations needed for Harvard's ArchivesSpace PUI

## **DEPRECATED** 
The current version of this plugin is maintained at https://github.com/harvard-lts/aspace-hvd-pui

*NOTE*: Version 1.0.7+ has a temporary patch in public/plugin_init.rb to handle a bug that is fixed in a subsequent 
release of ArchivesSpace.  It will be removed when we upgrade to that version.

## List of Customizations

- Styling
  - Use Harvard Logo
  - Replace default colors with Harvard-specified colors (see [discussion of overriding scss](scss/README.md) )
  - ~~Use sans-serif throughout~~
  - hide logos in the listing of repositories
  - breadcrumbs and "Found in" restyling
  - over-ride the *public/app/views/welcome/show.html.erb* page, moving the text below the search bar and adding special links, with concommitant entries in the en.yml file
  - For "ordered lists" that have no enumeration field (the case where the default EAD list is unordered), a "disk" will appear, instead of numbers.
  - **Restyle to match the new Harvard Library Portal styling**
    - color changes
    - "pill box" style changes, and is being moved to someplace else in the layout
  - move the sidebar to the left.
  - change the Page Action tabs to be buttons with small icons.
  

- Functionality
  - in any search results list: if a result has a primary type of **digital_object**, get the archival_object it links to instead
  - add a **Creators** facet to display of Collections within a Repository
  - over-ride *public/app/views/shared/_record_innards.html.erb* to favor the abstract over the Scope and Contents, and create a "Scope & Contents" Accordion fold; also remove duplicate Physical Description from accordion
  - over-ride *public/app/views/shared/_childern_tree.html.erb* so that, if the link of a branch is clicked, the children under it will become visible
  - over-ride the *public/app/views/shared/_navigation.html.erb* to remove the repository stickiness of the magnifying glass (submitted, and rejected,  as a Pull Request to the main body of code)
  -  used a later version of public/app/views/shared/_results.html.erb to solve a formatting issue. Subsequently have modified it to:
     -  isolated the context piece ("Found in") from the _results.html.erb to a separate partial view (*_context.html.erb*) so it could be more easily moved around
 - added the level information (e.g.: "Series") in the "Found in" breadcrumbs
 - added a count of digital objects within a resource for display on the "show" page
 - over-ride default Bootstrap printing of URLs when a page is printed from the browser
 - Make the pagination look "more like Amazon" rather than "like Google" by having page one always be available (over-ride *public/app/views/shared/_pagination.html.erb*)
 - In results, indicate that an archival object has an associated digital object
 - In collection display, add a "Digital Only" tab to the "pill tabs". 
   - If the collection contains archival objects with associated digital objects, their count will be display in parentheses
   - if the collection does not contain such archival objects, the tab will not be actionable
 - Display a paging, ordered list of archival objects that have associated digital objects (including the thumbnail) if "Digital Only" is selected. Selecting on an item in that list will resolve to display the full archival object.
 - Over-ride the Request popup
 - Over-ride *public/app/views/resources/_finding_aid.html.erb* to display the EAD ID
 - Make the Aleph ID a clickable link to Hollis TODO: make it a clickable link to the new Alma
 - Add configurable "Ask a Librarian/Archivist" to resource and object pages
 - Completely substitute the model, controller, and views for PDF generation with a Harvard-custom view; this includes the "View PDF" 'button' being a GET rather than a POST.
 - Add CSV download functionality, with a button on the Page actions menu
 - Added "permalink" routes: *id/resource/{ead_id}* for a resource, *id/object/{ref_id}* for an archival object, *id/digital{ref_id}* for a digital object
 - Support a Repository "long name" that will be used for Repository display page, pdf, and citations only
 - Change citation to 1) link to our permalinks (id.lib.harvard.edu) and 2) use the Repository "long name"

## Changes that I want to add as pull requests to the ArchivesSpace repo:

  - used process_mixed_content against titles in *public/views/digital_objects/_linked_instances.html.erb*

## Configuration issues

For the most part, configuration values that need to be set are in [public/plugin_init.rb](https://github.com/harvard-library/aspace-hvd-pui/blob/master/public/plugin_init.rb) .

  - I have found that the **sendmail** settings need to be set in the general config file, although the properties specific to the 'request' properties, such as the default "from" and "to" can be set in plugin_init  [FIXME: default fallback should be in **config.rb**]

 - **config.rb** also requires the addition of two keys to enable support of some of enhanced "digital materials" functionality:
   - AppConfig[:pui_solr_host] = {the host name, plus any port}
   - AppConfig[:pui_solr_select] = {the path down to the **/select**; e.g.: __"/collection1/select"__ }
 - **config.rb** requires the addition of a key to enable support of our "permalink" system:
   - AppConfig[:pui_perma] = {domain and port(if any)} of the perma link system
 - **config.rb** requires the addition of keys to support linking to PUI feedback and help:
   - AppConfig[:pui_feedback_url]
   - AppConfig[:pui_help_url] 
