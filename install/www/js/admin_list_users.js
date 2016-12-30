// FIXME TODO dancer base could change
var dancer_base_url = '/dancer';

$(document).ready(function(){

    var old_values = [];
    var change_password_user_id;
    var change_password_username;

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

    function changePassword() {

        var new_password = $('input#new_password').val();

        $.post(dancer_base_url + "/api/v1/admin/list_user/update_password/"+change_password_user_id,
            {"password" : new_password },
            function(data){
//                var str = JSON.stringify(data);
//                update_output("Success : " + str );
                update_output("changed password : " + change_password_username );
                $('div#dialog-password-error').text('');
                dialog_password.dialog( "close" );
            }
        )
        .fail(
            function(data){
                $('div#dialog-password-error').text( data.responseText );
            }
        );
    };

    var dialog_password = $( "#dialog-password" ).dialog({
        height: 250,
        width: 350,
        modal: true,
        buttons: {
            "Change Password": function() {
                changePassword();
            },
            Cancel: function() {
                $( this ).dialog( "close" );
            }
        }
    });

    dialog_password.dialog("close");

    var form = dialog_password.find( "form" ).on( "submit", function( event ) {
      event.preventDefault();
      changePassword();
    });

    $("button.change_password").click( function() {
        id = $(this).attr('id') ;

        var extractFieldNUserId = /^(.*)-user_id(\d+)$/g;
        var match = extractFieldNUserId.exec( id );

        change_password_user_id  = match[2];
        change_password_username = $('#username-user_id'+change_password_user_id).val();
        $('div#dialog-password-error').text('');

        dialog_password.dialog( "open" );
        $("span.ui-dialog-title").text("Change Password : "+change_password_username);
    });

    $("button.list-rooms").click( function() {

        id = $(this).attr('id') ;
        console.log(id + " list rooms was clicked");
        update_output("List Rooms. Not yet implemented : TODO");

//        var extractFieldNUserId = /^(.*)-user_id(\d+)$/g;
//        var match = extractFieldNUserId.exec( id );
//
//        change_password_user_id  = match[2];
//        change_password_username = $('#username-user_id'+change_password_user_id).val();
//        $('div#dialog-password-error').text('');
//
//        dialog_password.dialog( "open" );
//        $("span.ui-dialog-title").text("Change Password : "+change_password_username);

    });

    $("button.edit").click( function() {
        var id = $(this).attr('id');
        console.log(id + " edit was clicked");
        update_output("Edit. Not yet implemented : TODO");
    });

    $("button.delete").click( function() {
        var id = $(this).attr('id');
        console.log(id + " delete was clicked");
        update_output("Not yet implemented : TODO");
    });

    function update_output(msg){ $('#update-output').text(msg); };

});
