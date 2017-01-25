var control_state = [];
var control_change_count = [];
var control_request_time = [];
var keep_change_count   = 45;
var refresh_screen      = 333;
var animate_time        = 2400;

// TODO dynamically change the refresh screen to slightly longer than the last get status request took.

$(document).ready(function(){

    function refresh_data(){
        $.get(dancer_base_url + "/api/v1/statusall", function(data, http_status){

            for(var i=0;i<data.length;i++){
                var data_row = data[i];
                for(var key in data_row){
                    var control_name    = data_row['control_name'].toString();

                    var current_state       = data_row['current_state'];
                    if (current_state == null ){ current_state = '' }

                    var current_state_trans = data_row['current_state_trans'].toString();
                    var good_state          = data_row['good_state'].toString();

                    var current_request_time = data_row['request_time'].toString();

                    var old_state_value;
                    var old_request_time;

                    if(control_state[control_name] === undefined){
                        control_change_count[control_name] = 0;
                        control_state[control_name] = current_state;
                        control_request_time[control_name] = current_request_time;
                        old_state_value = "";
                        old_request_time = "";
                    } else {
                        old_state_value  = control_state[control_name];
                        old_request_time = control_request_time[control_name];
                    }

                    $("#" + control_name + '-request_time' ).text(current_request_time);
                    $("#" + control_name + '-state_trans' ).text(current_state_trans);

                    if (data_row['therm_lower'] != null && data_row['therm_higher'] != null){

                        therm_sel = $("#" + control_name + '-state_trans' );
                        current_state_float = parseFloat(current_state);
                        therm_lower_float   = parseFloat(data_row['therm_lower']);
                        therm_higher_float  = parseFloat(data_row['therm_higher']);

                        therm_sel.attr("title", "Lower = " + therm_lower_float + " : higher = " + therm_higher_float );
                        if (current_state_float < therm_lower_float ) {
                            switch_class( therm_sel, "value_too_hot value_correct","value_too_cold");
                        } else if (current_state_float > therm_higher_float ) {
                            switch_class( therm_sel, "value_too_cold value_correct","value_too_hot");
                        } else {
                            switch_class( therm_sel, "value_too_cold value_too_hot","value_correct");
                        }
                    }

                    if ( current_state != old_state_value || current_request_time != old_request_time){

                        if ( good_state == 'on' || good_state == 'off' ){
                            if ((current_state == 'off' && good_state == 'on')
                                || (current_state == 'on' && good_state == 'off')
                            ){
                                // The bad (red) state is 'on'
                                switch_class( $("#" + control_name + '-state_trans' ), "state_off","state_on");
                            }
                            if ((current_state == 'off' && good_state == 'off')
                                || (current_state == 'on' && good_state == 'on')
                            ){ // The good (green) state is 'off'
                                switch_class( $("#" + control_name + '-state_trans' ), "state_on","state_off");
                            }
                        } else {

                        }
                        control_change_count[control_name] = keep_change_count;
                        $("#" + control_name + '-name' ).addClass("change");
                    } else {

                        if ( control_change_count[control_name] > 0 ){
                            control_change_count[control_name] = control_change_count[control_name] - 1 ;
                        } else {
                            $("#" + control_name + '-name' ).removeClass("change");
                        }
                    }

                    control_state[control_name] = current_state;
                    control_request_time[control_name] = current_request_time;
                }
            }
        }).fail(
            function(data){
                // dunno, do something. TODO
            }
        );
    }

    function switch_class ( selector, from_class, to_class ){
        selector.removeClass(from_class);
        selector.addClass(to_class);
    }

    $("button.operate-control").click(function(){
        var control_name = $(this).attr('id');
        var action       = $(this).attr('value');
        //console.log("pressed " + control_name + " " + action );

        $.post(dancer_base_url + "/api/v1/operate/"+control_name+"/"+action,
            { },
            function(data, http_status){
                // alert("Data: " + data + "\nStatus: " + status);
            }
        )
        .fail(
            function(data){
                set_error_msg("FAIL " + data.responseText );
            }
        );
    });

    $("select#show_room").change(function(){
        $(location).attr('href',dancer_base_url+'/rooms?room_id='+$(this).val());
    });

    $("button#listcontrols").click( function() {
        $(location).attr('href',dancer_base_url+'/admin/list_control_rooms?room_id='+$("select#show_room").val() );
    });

    setInterval(function(){
        refresh_data()
    }, refresh_screen);
});

