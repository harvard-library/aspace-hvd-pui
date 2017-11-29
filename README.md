# aspace-hvd-pui
The customizations needed for Harvard's ArchivesSpace PUI

## List of Customizations

- Styling
  - Use Harvard Logo
  - Replace default colors with Harvard-specified colors (see [discussion of overriding scss](scss/README.md) )
  - Use sans-serif throughout
  - hide logos in the listing of repositories
  - breadcrumbs and "Found in" restyling
  - over-ride the *public/app/views/welcome/show.html.erb* page, moving the text below the search bar and adding special links, with concommitant entries in the en.yml file
  - For "ordered lists" that have no enumeration field (the case where the default EAD list is unordered), a "disk" will appear, instead of numbers.

- Functionality
  - add a **Creators** facet to display of Collections within a Repository
  - over-ride *public/app/views/shared/_record_innards.html.erb* to favor the abstract over the Scope and Contents, and create a "Scope & Contents" Accordion fold
  - over-ride *public/app/views/shared/_childern_tree.html.erb* so that, if the link of a branch is clicked, the children under it will become visible
  - over-ride the *public/app/views/shared/_navigation.html.erb* to remove the repository stickiness of the magnifying glass (submitted, and rejected,  as a Pull Request to the main body of code)
  -  used a later version of public/app/views/shared/_results.html.erb to solve a formatting issue. Subsequently have modified it to:
     -  isolated the context piece ("Found in") from the _results.html.erb to a separate partial view (*_context.html.erb*) so it could be more easily moved around
 - Added the level information (e.g.: "Series") in the "Found in" breadcrumbs
 - added a count of digital objects within a resource for display on the "show" page
## Changes that I want to add as pull requests to the ArchivesSpace repo:

  - used process_mixed_content against titles in *public/views/digital_objects/_linked_instances.html.erb*

## Configuration issues

For the most part, configuration values that need to be set are in [public/plugin_init.rb](https://github.com/harvard-library/aspace-hvd-pui/blob/master/public/plugin_init.rb) .

However, I have found that the **sendmail** settings need to be set in the general config file, although the properties specific to the 'request' properties, such as the default "from" and "to" can be set in plugin_init
