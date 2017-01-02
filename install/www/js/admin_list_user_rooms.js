var dancer_base_url = '/dancer';
var delete_user_room_id;

$(document).ready(function(){

    $("input[type=checkbox]").change( function() {

        var match = extract_field_id($(this));
        var field = match[1];
        var ur_id = match[2];

        var can_operate = $('#can_operate-id' + ur_id).is(':checked');
        var can_view    = $('#can_view-id' + ur_id).is(':checked');

        if ( field == 'can_operate' && can_operate && ! can_view ) {
            // if can_operate has changed to 'true' then can_view must be 'true'.
            $('#can_view-id' + ur_id).prop('checked', true );
            can_view = true;
        }

        if ( field == 'can_view' && can_operate && ! can_view ) {
            // if can_view has changed to 'false' then can_operate must be 'false'.
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

        var user_id_multi = $("#add_user_room-user_id").val();
        var room_id_multi = $("#add_user_room-room_id").val();

        var add_array = [];

        set_error_msg("adding user rooms..." );

        $.each(user_id_multi , function ( index, user_id ) {
            $.each(room_id_multi , function ( index, room_id ) {
                add_array.push({
                    "room_id" : room_id,
                    "user_id" : user_id
                });
            });
        });

        $.post(dancer_base_url + "/admin/add_user_room",
            { "add_array" : JSON.stringify(add_array) } ,
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

//                $.post(dancer_base_url + "/admin/add_user_room",
//                    {"room_id" : room_id,
//                     "user_id" : user_id
//                    },
//                    function(data){
//                        var str = JSON.stringify(data);
//                        set_error_msg("Success : Added " );
//                    }
//                )
//                .fail(
//                    function(data){
//                        set_error_msg("FAIL " + data.responseText );
//                    }
//                );

    });

    $("button.delete").click( function() {
        run_func_on_db_id($(this), function(jThis, h_id, db_id){
            console.log(h_id + " delete was clicked . db_id = "+db_id );

            $.post(dancer_base_url + "/admin/delete_user_room",
                {"user_room_id" : db_id },
                function(data){
                    var str = JSON.stringify(data);
                    set_error_msg("Success : Deleted " );
                    location.reload();
                }
            )
            .fail(
                function(data){
                    set_error_msg("FAIL " + data.responseText );
                }
            );

        });
    });
});
