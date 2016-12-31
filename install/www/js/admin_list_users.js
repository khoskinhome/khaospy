// FIXME TODO dancer base could change
var dancer_base_url = '/dancer';

$(document).ready(function(){

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
//      run_func_on_db_id($(this), function(jThis, h_id, db_id, field){
//
//        console.log(h_id + "change input. db_id = "+db_id );
//
//        if ( jThis.attr('type') == 'checkbox'){
//            var value = jThis.is(':checked');
//        } else { // all the rest are textboxes :
//            var value = jThis.val();
//        }
//
//        console.log( h_id + " input changed to " + value );
//
//        $.post(dancer_base_url + "/api/v1/admin/list_user/update/"+db_id+"/"+field,
//            {"value" : value },
//            function(data){
//                var str = JSON.stringify(data);
//                update_output("Success : " + str );
//            }
//        )
//        .fail(
//            function(data){
//                if ( jThis.attr('type') == 'checkbox'){
//                    jThis.prop('checked', old_values[h_id] );
//                } else { // all the rest are textboxes :
//                    jThis.val( old_values[h_id] );
//                }
//                update_output("FAIL " + data.responseText + "\n\n old val = " + old_values[h_id] );
//            }
//        );
//      });
//    });

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
      run_func_on_db_id($(this), function(jThis, h_id, db_id){
        change_password_user_id  = db_id;
        change_password_username = $('#td_username-id'+change_password_user_id).text();
        $('div#dialog-password-error').text('');
        dialog_password.dialog( "open" );
        $("span.ui-dialog-title").text("Change Password : "+change_password_username);
      })
    });

    $("button.listrooms").click( function() {
      run_func_on_db_id($(this), function(jThis, h_id, db_id){
          console.log(h_id + " listrooms was clicked . db_id = "+db_id );
          update_output(h_id + "listrooms. Not yet implemented . db_id = " + db_id );


      });
    });

    $("button.update").click( function() {
      run_func_on_db_id($(this), function(jThis, h_id, db_id){
          console.log(h_id + " update was clicked . db_id = "+db_id );
          //update_output(h_id + "update. Not yet implemented . db_id = " + db_id );
          $(location).attr('href',dancer_base_url+'/admin/update_user/'+db_id);
      });
    });

    $("button.delete").click( function() {
      run_func_on_db_id($(this), function(jThis, h_id, db_id){
          console.log(h_id + " delete was clicked . db_id = "+db_id );
          update_output(h_id + "delete. Not yet implemented . db_id = " + db_id );
      });
    });

});
