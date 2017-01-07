$(document).ready(function(){
    $("button.add_control_room").click( function() {
        console.log("add control room was clicked." );

        var control_id_multi = $("#add_control_room-control_id").val();
        var room_id_multi = $("#add_control_room-room_id").val();

        var add_array = [];

        set_error_msg("adding control rooms..." );

        $.each(control_id_multi , function ( index, control_id ) {
            $.each(room_id_multi , function ( index, room_id ) {
                add_array.push({
                    "room_id" : room_id,
                    "control_id" : control_id
                });
            });
        });

        if ($.isEmptyObject(add_array)){
            set_error_msg("Nothing selected to add" );
            return;
        }


        $.post(dancer_base_url + "/admin/add_control_room",
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

    });

    $("button.delete").click( function() {
        run_func_on_db_id($(this), function(jThis, h_id, db_id){
            console.log(h_id + " delete was clicked . db_id = "+db_id );

            $.post(dancer_base_url + "/admin/delete_control_room",
                {"control_room_id" : db_id },
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
