var delete_user_id;
var change_password_user_id;
var dialog_username;

$(document).ready(function(){

    function changePassword() {

        var new_password = $('input#new_password').val();

        $.post(dancer_base_url + "/api/v1/admin/list_user/update_password/"+change_password_user_id,
            {"password" : new_password },
            function(data){
                set_error_msg("changed password : " + dialog_username );
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
        dialog_username = $('#td_username-id'+change_password_user_id).text();
        $('div#dialog-password-error').text('');
        dialog_password.dialog( "open" );
        $("span.ui-dialog-title").text("Change Password : "+dialog_username);
      })
    });

    $("button.listrooms").click( function() {
      run_func_on_db_id($(this), function(jThis, h_id, db_id){
          console.log(h_id + " listrooms was clicked . db_id = "+db_id );
          $(location).attr('href',dancer_base_url+'/admin/list_user_rooms?user_id='+db_id);
      });
    });

    $("button.update").click( function() {
      run_func_on_db_id($(this), function(jThis, h_id, db_id){
          console.log(h_id + " update was clicked . db_id = "+db_id );
          $(location).attr('href',dancer_base_url+'/admin/update_user/'+db_id);
      });
    });


    var dialog_confirm_user_delete = $( "#dialog-confirm" ).dialog({
        resizable: false,
        height: "auto",
        width: 400,
        modal: true,
        buttons: {
          "Delete User": function() {
              $.post(dancer_base_url + "/admin/delete_user",
                  {"user_id" : delete_user_id},
                  function(data){
                      var str = JSON.stringify(data);
                      set_error_msg("Deleted User : " + dialog_username );
                      $('#tr_user-id'+delete_user_id).remove();
                  }
              )
              .fail(
                  function(data){
                      set_error_msg("FAIL : " + data.responseText );
                  }
              );
              $( this ).dialog( "close" );
          },
          Cancel: function() {
            $( this ).dialog( "close" );
          }
        }
    });

    dialog_confirm_user_delete.dialog("close");

    $("button.delete").click( function() {
        run_func_on_db_id($(this), function(jThis, h_id, db_id){
            console.log(h_id + " delete was clicked . db_id = "+db_id );
            delete_user_id = db_id;
            dialog_username = $('#td_username-id'+delete_user_id).text();
            dialog_confirm_user_delete.dialog( "open" );
            $("span.ui-dialog-title").text("Delete User : "+dialog_username);
        });
    });
});
