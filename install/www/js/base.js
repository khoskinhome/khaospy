
/*
$(document).ready(function(){

    $(window).resize(function(){

    $('.center').css({
        position:'absolute',
        left: ($(window).width() - $('.className').outerWidth())/2,
        top: ($(window).height() - $('.className').outerHeight())/2
    });

 });

 // To initially run the function:
 $(window).resize();

});

*/

function run_func_on_db_id ( jThis, func ){
    // extracts the field and the db_id number
    // calls "func" if it can get a db_id and field.
    var h_id = jThis.attr('id') ;
    var extractFieldNUserId = /^(.*)-id(\d+)$/g;
    var match = extractFieldNUserId.exec( h_id );

    if ( ! $.isArray(match)){
        alert("Can't get field or db-id for : " + h_id);
        return;
    }

    var field  = match[1];
    var db_id  = match[2];
    func(jThis, h_id, db_id, field);
};

function update_output(msg){ $('#update-output').text(msg); };
