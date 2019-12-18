const toggleDropdown = (event) => {
    if (event.keyCode === 13) {
        event.preventDefault();
        $("#dropdownMenu1").dropdown("toggle");
        if ($('#dropdownMenu1').parent().hasClass('open')) {
            console.log('okkkkk')
            const listItems =  $("#dropdownMenu1 + ul").find(".dropdown-item");
            listItems[0].focus();
        }
    } else if (event.keyCode === 27) {
        $("#dropdownMenu1").dropdown("toggle");
    }
}

$("#dropdownMenu1").bind("keydown", function(event) {
    toggleDropdown(event);
});

$(".dropdown-item").bind("keydown", function(event) {
    if (event.keyCode === 27) {
        toggleDropdown(event);
        $("#dropdownMenu1").focus();
    }
});