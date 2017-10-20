$(function() {
/* this really should be taken care of by a pull request to tack '-label' on to form labels, but... */

/* replace the "To" label with "-- " */

   var $inlines = $(".search form .inline-label");
   $inlines.each(function(){
       var $lbl = $(this); 
       if ($lbl.text() == "To")
       {$lbl.text("--")}
   });

});

