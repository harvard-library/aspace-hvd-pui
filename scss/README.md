# What this directory is for

Because it is **way** easier to:

-  modify ArchiveSpace's .scss files for large common changes, like common colors, fonts, etc., 
- generate the .css (by starting up the server),
- downloading *assets/application.self.css*, renaming it to **plugins/aspace-hvd-pui/public/assets/harvard_application.css**, 
- then add/modify any additional styling in **plugins/aspace-hvd-pui/public/assets/harvard.css**

this directory is intended to house those modified files, so that any further enhancements can be worked from them.

## Method for modifying the code:

**NOTE**: *This only works if you are using the **developer** version of ArchivesSpace *

- copy the {archivesspace_path}/plugin/aspace-hvd-pui/scss/public/*.scss to {archivesspace_path}/public/app/assets/stylesheets/archivespace

- make the changes to those files

- comment out the line in layout_head.html.erb: ```<link rel="stylesheet" media="all" href="/assets/harvard_application.css" />```

- Start the server.

If you like the changes:
- download the generated css file, 
- save it as {archivesspace_path}/plugin/aspace-hvd-pui/public/assets/harvard_application.css
- copy the changed `{archivesspace_path}/public/app/assets/stylesheets/archivespace/*.scss files` to `{archivesspace_path}/plugin/aspace-hvd-pui/scss/public/*.scss`

