
$(document).ready(function(){

    $("button.listusers").click( function() {
        run_func_on_db_id($(this), function(jThis, h_id, db_id){
            $(location).attr('href',dancer_base_url+'/admin/list_user_rooms?room_id='+db_id);
        });
    });

    $("button.listcontrols").click( function() {
        run_func_on_db_id($(this), function(jThis, h_id, db_id){
            $(location).attr('href',dancer_base_url+'/admin/list_control_rooms?room_id='+db_id);
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

