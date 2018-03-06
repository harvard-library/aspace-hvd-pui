function setupRequest(modalId, text) {
    $("#request_modal * .action-btn").hide();
    $('#request_sub').submit(function(e) {
        $("#request_modal").modal('show');
        return false;
	});
}

function new_row_from_template() {
    var num = $as.find(".search_row").size();
    var $row = $template.clone();
    replace_id_ref($row, 'label', 'for', num);
    replace_id_ref($row, 'input', 'id', num);
    replace_id_ref($row, 'select', 'id', num);
    $row.attr("id", "search_row_" + num);
    $row.find("input[type=submit]").remove();
   new_button($row, true);
    return $row;
}


$(function() {
/* this really should be taken care of by a pull request to tack '-label' on to form labels, but... */

/* replace the "To" label with "-- " */

   var $inlines = $(".search form .inline-label");
   $inlines.each(function(){
       var $lbl = $(this); 
       if ($lbl.text() == "TO")
       {$lbl.text(" ")}
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
/* handle the digital only paging */

   if (hrvd_controller === 'resources' && hrvd_action === 'digital_only') {
       var $page_links = $("ul.pagination li:not(.active)")
       if ($page_links.length > 0) {
	   $page_links.not('dots').click(function( event ) {
	       var  $form = $(this).parents("form.digital_page");
	       var page = $(this).children("a").html();
	       var $p = $form.children("input[name='page']");
	       $p.val(page);
	       $form.submit();
	   });
       }
   }

});


