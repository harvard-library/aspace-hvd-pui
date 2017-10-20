# aspace-hvd-pui
The customizations needed for Harvard's ArchivesSpace PUI

## Configuration issues

For the most part, configuration values that need to be set are in [public/plugin_init.rb](https://github.com/harvard-library/aspace-hvd-pui/blob/master/public/plugin_init.rb) .

However, I have found that the **sendmail** settings need to be set in the general config file, although the properties specific to the 'request' properties, such as the default "from" and "to" can be set in plugin_init.
