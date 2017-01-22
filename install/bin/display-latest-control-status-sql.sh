#!/bin/bash

psql -U khaospy_write -d khaospy -h localhost -p $1  < "select control_name, request_time, current_state   from control_status where id in ( select max(id) from control_status where control_name like '%' group by control_name ) order by control_name";
