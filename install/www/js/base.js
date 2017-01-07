// dancer base could change, depending on the Apache Conf.
var dancer_base_url = '/dancer';

$(document).ready(function(){
    $('.error_msg, .td_error').bind('mouseenter', function(){
        var $this = $(this);

        if(this.offsetWidth < this.scrollWidth && !$this.attr('title')){
            $this.attr('title', $this.text());
        }
    });
});

function run_func_on_db_id ( jThis, func ){
    // extracts the field and the db_id number
    // calls "func" if it can get a db_id and field.
    var match = extract_field_id (jThis)
    if ( ! $.isArray(match)){ return; }

    var field  = match[1];
    var db_id  = match[2];
    func(jThis, jThis.attr('id'), db_id, field);
};

function extract_field_id (jThis){
    var h_id = jThis.attr('id') ;
    var extractFieldNUserId = /^(.*)-id(\d+)$/g;
    var match = extractFieldNUserId.exec( h_id );

    if ( ! $.isArray(match)){
        alert("Can't get field or db-id for : " + h_id);
        return;
    }
    return match;
};

function set_error_msg(msg){ $('.error_msg').text(msg); };
