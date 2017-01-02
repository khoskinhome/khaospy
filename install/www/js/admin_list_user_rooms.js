var dancer_base_url = '/dancer';
var delete_user_room_id;

$(document).ready(function(){

    $("input[type=checkbox]").change( function() {
//        set_error_msg("checkbox change . Not yet implemented. ");
//        console.log("checkbox change . Not yet implemented." );

        var match = extract_field_id($(this));
        var field = match[1];
        var ur_id = match[2];

        var can_operate = $('#can_operate-id' + ur_id).is(':checked');
        var can_view    = $('#can_view-id' + ur_id).is(':checked');
        // if can_operate is true then can_view must be true.
        // if can_view is false then can_operate must be false.

        if ( field == 'can_operate' && can_operate && ! can_view ) {
            $('#can_view-id' + ur_id).prop('checked', true );
            can_view = true;
        }

        if ( field == 'can_view' && can_operate && ! can_view ) {
            $('#can_operate-id'+ ur_id).prop('checked', false );
            can_operate = false;
        }

        $.post(dancer_base_url + "/admin/update_user_room",
            {"user_room_id" : ur_id,
             "can_operate"  : can_operate,
             "can_view"     : can_view
            },
            function(data){
                var str = JSON.stringify(data);
                set_error_msg("Success : Updated " + ur_id );
            }
        )
        .fail(
            function(data){
                set_error_msg("FAIL " + data.responseText );
            }
        );

    });

    $("button.add_user_room").click( function() {
        console.log("add user room was clicked." );
        set_error_msg("add user room. Not yet implemented." );

        var user_id = $("#add_user_room-user_id").val();
        var room_id = $("#add_user_room-room_id").val();

        $.post(dancer_base_url + "/admin/add_user_room",
            {"room_id" : room_id,
             "user_id" : user_id
            },
            function(data){
                var str = JSON.stringify(data);
                set_error_msg("Success : Added " );
                location.reload();
            }
        )
        .fail(
            function(data){
                set_error_msg("FAIL " + data.responseText );
            }
        );


    });

    $("button.delete").click( function() {
        run_func_on_db_id($(this), function(jThis, h_id, db_id){
            console.log(h_id + " delete was clicked . db_id = "+db_id );
            delete_user_room_id = db_id;


            set_error_msg(h_id + "delete user room. Not yet implemented . db_id = " + db_id );


        });
    });
});
