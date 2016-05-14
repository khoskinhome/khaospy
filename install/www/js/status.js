var control_state_value = [];
var control_state_count = [];
var keep_change_count   = 45;
var refresh_screen      = 1000;
var animate_time        = 1200;

// FIXME TODO dancer base could change
var dancer_base_url = '/dancer';

$(document).ready(function(){

    function refresh_data(){
        $.get(dancer_base_url + "/api/v1/statusall", function(data, http_status){
            //TODO check the http_status

            for(var i=0;i<data.length;i++){
                var data_row = data[i];
                for(var key in data_row){
                    var control_name    = data_row['control_name'].toString();
                    var new_state_value = data_row['current_state_value'].toString();

                    var new_state = data_row['current_state'];
//                    if ( data_row['current_state'] !== null ){
//                        new_state = data_row['current_state'].toString();
//                    }

                    var old_state_value;

                    if(control_state_value[control_name] === undefined){
                        control_state_count[control_name] = 0;
                        control_state_value[control_name] = new_state_value;
                        old_state_value = "";
                    } else {
                        old_state_value = control_state_value[control_name];
                    }

                    $("#" + control_name + '-request_time' ).text(data_row['request_time']);
                    $("#" + control_name + '-state_alias' ).text(new_state_value);


                    if ( new_state_value != old_state_value ){

                        if ( new_state != null ){
                            // only on-off controls should have new_state defined.
                            if (new_state == 'on'){
                                switch_class( $("#" + control_name + '-state_alias' ), "state_off","state_on");
                            }
                            if (new_state == 'off'){
                                switch_class( $("#" + control_name + '-state_alias' ), "state_on","state_off");
                            }
                        } else {
                            console.log(control_name + ' undefined new_state');
                        }

                        $("#" + control_name + '-info' ).text("changed");
                        control_state_count[control_name] = keep_change_count;
                        switch_class( $("#" + control_name + '-info' ), "no_change","change");
                    } else {

                        if ( control_state_count[control_name] > 0 ){
                            control_state_count[control_name] = control_state_count[control_name] - 1 ;
                        } else {
                            $("#" + control_name + '-info' ).text("");
                            switch_class( $("#" + control_name + '-info' ), "change","no_change");
                        }
                    }

                    // console.log(control_name + ' old = ' + old_state_value + ' : new = ' + new_state_value + ' : count = ' + control_state_count[control_name] );
                    control_state_value[control_name] = new_state_value;
                }
            }
        });
    }

    function switch_class ( selector, from_class, to_class ){
        // so I can switch on or off jQuery animations.
        // selector.switchClass(from_class, to_class, animate_time); return;
        selector.removeClass(from_class);
        selector.addClass(to_class);
    }

    $("button").click(function(){
        var control_name = $(this).attr('id');
        var action       = $(this).attr('value');
        // alert("pressed " + control_name + " " + action );

        $.post(dancer_base_url + "/api/v1/operate/"+control_name+"/"+action,
            { },
            function(data, http_status){
                // alert("Data: " + data + "\nStatus: " + status);
                // TODO handle http_status errors.
            }
        );
    });

    setInterval(function(){
        refresh_data()
    }, refresh_screen);
});

