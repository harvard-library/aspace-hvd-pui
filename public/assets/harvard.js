function HarvardSidebar($sidebar) {
    this.$sidebar = $sidebar;
    this.$row = $sidebar.closest('.row');
    this.$content_pane = this.$row.find('> .col-sm-9');
    this.$handle = $sidebar.find('.resizable-sidebar-handle');
    this.bind_events();
}
HarvardSidebar.prototype.bind_events = function() {
    var self = this;

    self.$handle.on('mousedown', function (e) {
        self.isResizing = true;
        self.lastDownX = e.clientX;
    });
/* re-jigger the mousemove event when there's a resizing handle */
/* narrow limits:
     sidebar: 200
     contents_pane: 300
*/
    $(document).on('mousemove', function (e) {
        if (!self.isResizing) {
            return;
        }
        var cursor_x = e.clientX;
	var so = self.$sidebar.offset();
	if ((self.$row.width() - cursor_x) < 300) {
	    cursor_x = self.$row.width() - 300;
	}
	var s_w = Math.max(cursor_x - so.left, 200);
	if (s_w === 200) {
	    cursor_x = so.left + 200;
	}
        var new_content_width = self.$row.width() - cursor_x;
	var co = self.$content_pane.offset();
	co.left = cursor_x + 10;
/*console.log('clientX:' + e.clientX + ' so.left: ' + so.left + ' s_w: ' + s_w + ' contentwidth: ' + new_content_width);*/
        self.$sidebar.css('width', 0);
        self.$content_pane.css('width', new_content_width);
	self.$content_pane.offset(co);
	self.$sidebar.offset(so);
        self.$sidebar.css('width', s_w);
      }).on('mouseup', function (e) {
/* console.log('mouseup!'); */
        self.isResizing = false;
      });
};

function toggleModal(){
  $("#filter_button").click(function(){
    $("#filterModal").removeClass("hide");
  });
};

function responsivePagination(){
  $(window).on("load resize",function(e){
    if($(window).width() < 768){
      //move sorter from row to next row
      $(".xs-filter-row").append( $(".filter-form") );
    } else {
      $(".filter-row").append( $(".filter-form") );
    }
  });
};


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

/* supports going through the digital-only pages */
function new_dig_page($form, page) {
    var $p = $form.children("input[name='page']");
    $p.val(page);
    $form.submit();
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
	       if ($(this).hasClass("previous") || $(this).hasClass("next"))  {
		   $non = $("ul.pagination li.active") // get where you're coming from
		   var current = parseInt($non.children("a").html());
		   var newpage = $(this).hasClass("previous") ? current -1: current + 1;
		   new_dig_page($form, newpage);
	       }
	       else {
		    new_dig_page($form, $(this).children("a").html());
	       }
	   });
       }
   }


  if ($('.resizable-sidebar-handle').length > 0) {
      $(document).off('mousemove');
      $(document).off('mouseup');
      $('.resizable-sidebar').each(function() {
	  new HarvardSidebar($(this));
      });
  }
});
function responsive_search(){
  var keyword, down_caret, limit, limit_down_caret;	
  keyword = $("select.search-keyword").children("option:selected")
  if (keyword == null) {
	  keyword = $("select.search-keyword").children().first();
  }
  down_caret = $("#down-caret");
  down_caret.appendTo(keyword);
  $("select.search-keyword").change(function(){
	  $("select.search-keyword").children().remove(down_caret)
	  keyword = $("select.search-keyword").children("option:selected");
	  down_caret.appendTo(keyword);
  });
  
  limit = $("select.limit-field").children("option:selected")
  if (limit == null) {
	  limit = $("select.limit-field").children().first();
  }
  limit_down_caret = down_caret.clone();
  limit_down_caret.appendTo(limit);
  $("select.limit-field").change(function(){
	  $("select.limit-field").children().remove(limit_down_caret)
	  limit = $("select.limit-field").children("option:selected");
	  limit_down_caret.appendTo(limit);
  });
	
//Not sure what this code actually does so I'm not touching it
  $(document).ready(function(){
    var observer = new MutationObserver(function(mutations) {
      // For the sake of...observation...let's output the mutation to console to see how this all works
      mutations.forEach(function(mutation) {
        $new_keyword = $(mutation.addedNodes[0]).find($('select[id^="field"]')).children().first();
        // I don't know why I can't do this on one line but it breaks the plusminus fcnality when I do so.
        $new_down_caret = $down_caret.clone();
        $new_down_caret.appendTo($new_keyword);
      });
    });

    // Notify me of everything!
    var observerConfig = {
      attributes: true,
      childList: true,
      characterData: true
    };

    // Node, config
    // In this case we'll listen to all changes to body and child nodes
    var targetNode = document.body;
    observer.observe(targetNode, observerConfig);

    observer.observe(targetNode, { childList: true, subtree: true });
  });
// $('select[id^="field"]')

  $search_container = $("#submit_search");
  $search_button = $search_container[0];
  // set the default search button behavior for small devices
  if($(window).width() < 768){
    $("#mobile-submit").append($search_button);
  }
  // listen for browser size change and move button accordingly
  $(window).resize(function(){
    if($(window).width() < 768){
      if($('#mobile-submit').find($search_button).length)
      {
        // do nothing
      }
      else {
        $("#mobile-submit").append($search_button);
      }
    }
    if($(window).width() > 767){
      if($('#search_row_0').find('.input-group-btn').find($search_button).length){
        // do nothing
      }
      else {
        $('#search_row_0').find('.input-group-btn').append($search_button);
      }
    }
  });
}

// Keyboard controls for bootstrap dropdown menus
function toggleDropdown(event) {
  let currentElement = $(event.currentTarget);
  if (event.which === 13 && !currentElement.is(".dropdown > .dropdown-menu > li > a")) {
    event.preventDefault();
    currentElement.dropdown("toggle");
    currentElement.next("ul").find("a")[0].focus();
  } else if (event.which === 27) {
    currentElement = currentElement.closest('.dropdown').find('.dropdown-toggle')
    currentElement.dropdown("toggle").focus();
  }
}

$(window).on('load', function() {
  $("body").on('keydown', '.dropdown-toggle, .dropdown > .dropdown-menu > li > a', function(event) {
    toggleDropdown(event)
  });
})
