// FIXME TODO dancer base could change
var dancer_base_url = '/dancer';

$(document).ready(function(){

    $("button.listusers").click( function() {
        run_func_on_db_id($(this), function(jThis, h_id, db_id){
            console.log(h_id + " listusers was clicked . db_id = "+db_id );
            $(location).attr('href',dancer_base_url+'/admin/list_user_rooms?room_id='+db_id);
        });
    });

    $("button.listcontrols").click( function() {
        run_func_on_db_id($(this), function(jThis, h_id, db_id){

            console.log(h_id + " listcontrols was clicked . db_id = "+db_id );
            set_error_msg(h_id + "listcontrols. Not yet implemented . db_id = " + db_id );


        });
    });

    $("button.update").click( function() {
        run_func_on_db_id($(this), function(jThis, h_id, db_id){

            console.log(h_id + " update was clicked . db_id = "+db_id );
            set_error_msg(h_id + "update. Not yet implemented . db_id = " + db_id );


        });
    });

    $("button.delete").click( function() {
      run_func_on_db_id($(this), function(jThis, h_id, db_id){

          console.log(h_id + " delete was clicked . db_id = "+db_id );
          set_error_msg(h_id + "delete. Not yet implemented . db_id = " + db_id );


      });
    });


});

//        id = $(this).attr('id') ;
//
//        var extractFieldNUserId = /^(.*)-id(\d+)$/g;
//        var match = extractFieldNUserId.exec( id );
//
//        if ( ! $.isArray(match)){
//            console.log("Can't get room_id for "+id);
//            return;
//        }
//
//        var room_id  = match[2];
//
//        console.log(id + " list users was clicked. room-id="+room_id);
//        set_error_msg("List Users. Not yet implemented . room-id="+room_id);
//
//        change_password_username = $('#username-user_id'+change_password_user_id).val();
//        $('div#dialog-password-error').text('');
//
//        dialog_password.dialog( "open" );
//        $("span.ui-dialog-title").text("Change Password : "+change_password_username);

//        id = $(this).attr('id') ;
//
//        var extractFieldNUserId = /^(.*)-id(\d+)$/g;
//        var match = extractFieldNUserId.exec( id );
//
//        if ( ! $.isArray(match)){
//            console.log("Can't get room_id for "+id);
//            return;
//        }
//
//        var room_id  = match[2];
//
//        console.log(id + " list controls was clicked . room-id="+room_id);
//        set_error_msg("List Controls. Not yet implemented : room-id="+room_id);
//


//        change_password_username = $('#username-user_id'+change_password_user_id).val();
//        $('div#dialog-password-error').text('');
//
//        dialog_password.dialog( "open" );
//        $("span.ui-dialog-title").text("Change Password : "+change_password_username);


//    var old_values = [];
//    var change_password_user_id;
//    var change_password_username;
//
//    $("input[type=text]").focusin( function() {
//        var id = $(this).attr('id');
//        old_values[id] = $(this).val();
//        //console.log(id + " stored old text value " + old_values[id]);
//    });
//
//    $("input[type=checkbox]").focusin( function() {
//        var id = $(this).attr('id');
//        old_values[id] = $(this).is(':checked');
//        //console.log(id + " stored old checkbox value " + old_values[id]);
//    });
//
//    $("input").change( function() {
//        var id = $(this).attr('id');
//
//        var extractFieldNUserId = /^(.*)-user_id(\d+)$/g;
//        var match = extractFieldNUserId.exec(id);
//        var field   = match[1];
//        var user_id = match[2];
//
//        if ( $(this).attr('type') == 'checkbox'){
//            var value = $(this).is(':checked');
//        } else { // all the rest are textboxes :
//            var value = $(this).val();
//        }
//
//        console.log( id + " input changed to " + value );
//
//        $.post(dancer_base_url + "/api/v1/admin/list_user/update/"+user_id+"/"+field,
//            {"value" : value },
//            function(data){
//                var str = JSON.stringify(data);
//                set_error_msg("Success : " + str );
//            }
//        )
//        .fail(
//            function(data){
//                if ( $( "#"+ id ).attr('type') == 'checkbox'){
//                    $( "#"+ id ).prop('checked', old_values[id] );
//                } else { // all the rest are textboxes :
//                    $( "#"+ id ).val( old_values[id] );
//                }
//                set_error_msg("FAIL " + data.responseText + "\n\n old val = " + old_values[id] );
//            }
//        );
//    });
//
//    function changePassword() {
//
//        var new_password = $('input#new_password').val();
//
//        $.post(dancer_base_url + "/api/v1/admin/list_user/update_password/"+change_password_user_id,
//            {"password" : new_password },
//            function(data){
////                var str = JSON.stringify(data);
//                set_error_msg("changed password : " + change_password_username );
//                $('div#dialog-password-error').text('');
//                dialog_password.dialog( "close" );
//            }
//        )
//        .fail(
//            function(data){
//                $('div#dialog-password-error').text( data.responseText );
//            }
//        );
//    };
//
//    var dialog_password = $( "#dialog-password" ).dialog({
//        height: 250,
//        width: 350,
//        modal: true,
//        buttons: {
//            "Change Password": function() {
//                changePassword();
//            },
//            Cancel: function() {
//                $( this ).dialog( "close" );
//            }
//        }
//    });
//
//    dialog_password.dialog("close");
//
//    var form = dialog_password.find( "form" ).on( "submit", function( event ) {
//      event.preventDefault();
//      changePassword();
//    });

