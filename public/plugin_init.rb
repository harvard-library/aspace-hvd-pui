# sets up the AppConfig to conform to Harvard's needs
AppConfig[:pui_hide][:accessions] = true
AppConfig[:pui_hide][:classifications] = true
AppConfig[:pui_branding_img] = '/assets/hl_logo_alt.png'
AppConfig[:pui_hide][:classification_badge] = true
# AppConfig[:pui_branding_img] = 'Aspace-logo-transparent.png'
AppConfig[:pui_page_custom_actions] << {
   'record_type' => ['resource'], # the jsonmodel type to show for
   'erb_partial' => 'shared/test'
   }
#AppConfig[:pui_email_enabled] = true

AppConfig[:pui_request_email_fallback_to_address] = 'bobbi_fox@harvard.edu'
AppConfig[:pui_request_email_fallback_from_address] = 'bobbi_fox@harvard.edu'
#AppConfig[:pui_email_delivery_method] = :sendmail
#AppConfig[:pui_email_sendmail_settings] = {
#  location: '/usr/sbin/sendmail',
#  arguments: '-i'
# }


