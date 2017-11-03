# aspace-hvd-pui
The customizations needed for Harvard's ArchivesSpace PUI

## List of Customizations

- Styling
  - Use Harvard Logo
  - Replace default colors with Harvard-specified colors (see [discussion of overriding scss](scss/README.md) )
  - Use sans-serif throughout
  - hide logos in the listing of repositories

- Functionality
  - add a **Creators** facet to display of Collections within a Repository

- TEMPORARY: used a later version of public/app/views/shared/_results.html.erb to solve a formatting issue.

## Configuration issues

For the most part, configuration values that need to be set are in [public/plugin_init.rb](https://github.com/harvard-library/aspace-hvd-pui/blob/master/public/plugin_init.rb) .

However, I have found that the **sendmail** settings need to be set in the general config file, although the properties specific to the 'request' properties, such as the default "from" and "to" can be set in plugin_init
