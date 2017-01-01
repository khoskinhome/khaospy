
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
    var h_id = jThis.attr('id') ;
    var extractFieldNUserId = /^(.*)-id(\d+)$/g;
    var match = extractFieldNUserId.exec( h_id );

    if ( ! $.isArray(match)){
        alert("Can't get field or db-id for : " + h_id);
        return;
    }

    var field  = match[1];
    var db_id  = match[2];
    func(jThis, h_id, db_id, field);
};

function set_error_msg(msg){ $('.error_msg').text(msg); };
