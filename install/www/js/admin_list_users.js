// FIXME TODO dancer base could change
var dancer_base_url = '/dancer';

$(document).ready(function(){

    var old_values = [];

    $("input[type=text]").focusin( function() {
        var id = $(this).attr('id');
        old_values[id] = $(this).val();
        //console.log(id + " stored old text value " + old_values[id]);
    });

    $("input[type=checkbox]").focusin( function() {
        var id = $(this).attr('id');
        old_values[id] = $(this).is(':checked');
        //console.log(id + " stored old checkbox value " + old_values[id]);
    });

    $("input").change( function() {
        var id = $(this).attr('id');

        var extractFieldNUserId = /^(.*)-user_id(\d+)$/g;
        var match = extractFieldNUserId.exec(id);
        var field   = match[1];
        var user_id = match[2];

        if ( $(this).attr('type') == 'checkbox'){
            var value = $(this).is(':checked');
        } else { // all the rest are textboxes :
            var value = $(this).val();
        }

        console.log( id + " input changed to " + value );

        $.post(dancer_base_url + "/api/v1/admin/list_user/update/"+user_id+"/"+field,
            {"value" : value },
            function(data){
                var str = JSON.stringify(data);
                update_output("Success : " + str );
            }
        )
        .fail(
            function(data){
                if ( $( "#"+ id ).attr('type') == 'checkbox'){
                    $( "#"+ id ).prop('checked', old_values[id] );
                } else { // all the rest are textboxes :
                    $( "#"+ id ).val( old_values[id] );
                }
                update_output("FAIL " + data.responseText + "\n\n old val = " + old_values[id] );
            }
        );
    });

    $("button.change_password").click( function() {
        var id = $(this).attr('id');
        console.log(id + " change password was clicked");
        update_output("Not yet implemented : TODO");
    });

    $("button.delete").click( function() {
        var id = $(this).attr('id');
        console.log(id + " delete was clicked");
        update_output("Not yet implemented : TODO");
    });

    function update_output(msg){ $('#update-output').text(msg); };

});
