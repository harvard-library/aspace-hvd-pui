// create a down caret that we can use throughout for dropdown menus
let $downCaret = '<span class="float-right search-down-caret hidden">&nbsp&nbsp&nbsp&#9662</span>'

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
  var keyword, limit;	
  keyword = $("select.search-keyword").children("option:selected")
  if (keyword == null) {
	  keyword = $("select.search-keyword").children().first();
  }
  $($downCaret).appendTo(keyword);

  limit = $("select.limit-field").children("option:selected")
  if (limit == null) {
	  limit = $("select.limit-field").children().first();
  }
  $($downCaret).appendTo(limit);
	
//Not sure what this code actually does so I'm not touching it
  $(document).ready(function(){
    var observer = new MutationObserver(function(mutations) {
      // For the sake of...observation...let's output the mutation to console to see how this all works
      
      mutations.forEach(function(mutation) {
        $new_keyword = $(mutation.addedNodes[0]).find($('select[id^="field"]')).children().first();
        $new_limit = $(mutation.addedNodes[0]).find($('.limit-field')).children().first();
        // I don't know why I can't do this on one line but it breaks the plusminus fcnality when I do so.
        $($downCaret).appendTo($new_keyword);
        $($downCaret).appendTo($new_limit)
      });

      // making additional limit fields invisible and uninteractable instead of removing them to keep consistent formatting
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
    // This is listening to a property in harvard.css that toggles at 767px using css media queries.
    // JQuery's $(window).width() was out of alignment with it on some devices, so we're explicitly tying the two together
    // We use borderTopRightRadius because Firefox doesn't like jQuery looking at border-radius
    if($(".search-keyword.repeats.form-control").css("borderTopRightRadius") === "4px"){
      if($('#mobile-submit').find($search_button).length)
      {
        // do nothing
      }
      else {
        $("#mobile-submit").append($search_button);
      }
    }
    if($(".search-keyword.repeats.form-control").css("borderTopRightRadius") === "0px"){
      if($('#search_row_0').find('.input-group-btn').find($search_button).length){
        // do nothing
      }
      else {
        $('#search_row_0').find('.input-group-btn').append($search_button);
      }
    }
  });
}

function handleDropdownCarets(event) {
  // get all children of the changed dropdown
  let $targetDropdownOptions = $(event.target).children()
  $targetDropdownOptions.each(function() {
    if ($(this)[0].selected) {
      // If the option is selected, we add a down-caret to the end
      $($downCaret).appendTo($(this));
    } else {
      // If the option is not selected, we make sure there is no down-caret on it
      if ($(this).find("span.search-down-caret").length > 0) {
        $(this).find("span.search-down-caret").remove();
      }
    }
  })
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

// Keyboard controls for more/less buttons in the facet component
function toggleMoreFacets(event) {
  if (event.which === 13 || event.which === 32) {
    event.preventDefault();
    const currentElement = $(event.currentTarget)
    if (currentElement.hasClass("more")) {
      currentElement.siblings('.below-the-fold').show();
      currentElement.siblings('.below-the-fold').first().find("dd > a").first().focus()
      currentElement.hide();
    } else if (currentElement.hasClass("less")) {
      currentElement.parent().hide();
      currentElement.parent().parent().find('.more').show();
      currentElement.parent().prev("span").focus()
    }
  }
}

// Add listeners
$(window).on('load', function() {
  $("body").on('keydown', '.dropdown-toggle, .dropdown > .dropdown-menu > li > a', function(event) {
    toggleDropdown(event)
  });

  $("body").on('keydown', '.more.btn.refine, .less.btn.refine', function(event) {
    toggleMoreFacets(event)
  })

  $("body").on('change', 'select.search-keyword, select.limit-field', function(event) {
    handleDropdownCarets(event)
  })
})
