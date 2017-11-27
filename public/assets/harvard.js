$(function() {
/* this really should be taken care of by a pull request to tack '-label' on to form labels, but... */

/* replace the "To" label with "-- " */

   var $inlines = $(".search form .inline-label");
   $inlines.each(function(){
       var $lbl = $(this); 
       if ($lbl.text() == "To")
       {$lbl.text("--")}
   });
/* if showing a resource, get the number of digital objects */
   if (hrvd_controller === 'resources' && hrvd_action === 'show') {
       $.ajax({
	   url: window.location.href + '/digct',
	   type: 'GET',
	   dataType: 'html',
       })
       .done(function (html) {
	   $(".information div.badge-and-identifier div.identifier").after(html);
       });
   }

});

