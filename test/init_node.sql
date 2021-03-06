-- create extension if not exists plpgsql with schema pg_catalog;
create extension if not exists plpythonu with schema pg_catalog;

create type id_name as (
    id integer,
    name text
);

create type state as enum (
    'idle',
    'start',
    'done'
);

create type complex as (
    id_names id_name[],
    data json,
    states state[]
);

create table if not exists person (id integer primary key, name text);

create or replace function get_person_name(anode_id integer, aid integer)
returns text
    language plpgsql
    as $$
begin
    return (select name from person where id = aid);
end;
$$;

create or replace function get_persons(anode_id integer)
returns table(id integer, name text)
    language plpgsql
    as $$
begin
    return query select person.id, person.name from person;
end;
$$;

create or replace function set_person(anode_id integer, aid integer, aname text)
returns void
    language plpgsql
    as $$
begin
    if aname is null then
      delete from person where id = aid;
    elsif exists (select * from person where id = aid) then
        update person set name = aname where id = aid;
    else
        insert into person (id, name) values (aid, aname);
    end if;
end;
$$;

create or replace function clear_person(anode_id integer)
returns void
    language plpgsql
    as $$
begin
    delete from person;
end;
$$;

create function get_node_number()
returns integer
    language plpgsql
    as $$
begin
    return {{node}};
end;
$$;

create function return_integer_value(anode_id integer, value integer)
returns integer
    language plpgsql
    as $$
begin
    return value;
end;
$$;

create function return_integer_array(anode_id integer, value integer)
returns integer[]
    language plpgsql
    as $$
begin
    return array[anode_id,value];
end;
$$;

create or replace function overload_function(anode_id integer)
returns integer
    language plpgsql
    as $$
begin
    return {{node}};
end;
$$;

create or replace function overload_function(anode_id integer, avalue integer)
returns integer
    language plpgsql
    as $$
begin
    return avalue;
end;
$$;

create or replace function overload_function(anode_id integer, avalue text)
returns text
    language plpgsql
    as $$
begin
    return avalue;
end;
$$;

create function get_null(anode_id integer)
returns integer
    language plpgsql
    as $$
begin
    return null;
end;
$$;

create or replace function get_null_in_setof(anode_id integer)
returns setof integer
    language plpgsql
    as $$
begin
    return next 1;
    return next 2;
    return next null;
    return next 4;
end;
$$;

create or replace function get_null_in_typed_record(anode_id integer, out id integer, out name text)
returns setof record
    language plpythonu
    as $$
return [{'id': None, 'name': 'yes'},
        {'id': 1, 'name': None}]
$$;

create function get_idle_enum(anode_id integer)
returns state
    language plpgsql
    as $$
begin
    return 'idle'::state;
end;
$$;

create function get_agg_enum(anode_id integer)
returns table(id integer, states state[])
    language plpgsql
    as $$
begin
    return query
      select i, enum_range(null::state)
        from generate_series(1, 5) as i;
end;
$$;

create function get_enum_array(anode_id integer)
returns state[]
    language plpgsql
    as $$
begin
    return '{idle, start}'::state[];
end;
$$;

create function get_complex(anode_id integer)
returns complex[]
    language plpgsql
    as $$
declare
    res complex[] := '{}';
    t complex;
begin
    t.id_names := '{"(1,yes)", "(2,no)"}';
    t.data := '{"id": 42}';
    t.states := '{idle,start}';
    res := res || t;
    res := res || t;
    return res;
end;
$$;

create function get_composite(anode_id integer)
returns id_name
    language plpgsql
    as $$
begin
    return '(1, yes)'::id_name;
end;
$$;

create function get_typed_record(anode_id integer, out id integer, out name text, out dep text)
returns record
    language plpythonu
    as $$
return {'id': 1, 'name': 'yes', 'dep': 'dev'}
$$;

create function get_untyped_record(anode_id integer)
returns record
    language plpythonu
    as $$
return {'id': 1, 'name': 'yes'}
$$;

create function get_set_of_record(anode_id integer)
returns table(id integer, name text)
    language plpgsql
    as $$
begin
    return query
      select i, format('customer_%s', i)
        from generate_series(1, 5) as i;
end;
$$;

create function get_retset(anode_id integer)
returns setof integer
    language plpgsql
    as $$
begin
    return query
      select i from generate_series(1, 5) as i;
end;
$$;

create or replace function two_args_hash_function(anode_id integer)
returns integer
    language plpgsql
    as $$
begin
    return get_node_number();
end;
$$;

create or replace
function test_run_on_all(n integer) returns setof integer as $$
begin
  return query
    select i
      from generate_series(1, n) as i;
end;
$$ language plpgsql;

create or replace
function test_all_coalesce_on_records(
  out a text,
  out b text
) returns record as $$
begin
  {% if node == 0 %}
  return;
  {% else %}
  a := 'node{{ node }}';
  b := '';
  {% endif %}
end;
$$ language plpgsql;


create table t (
  id integer not null,
  constraint uni_id unique(id) deferrable initially deferred
);

create or replace
function diferred_error() returns void as $$
begin
  insert into t(id)
    values (1), (1);
end;
$$ language plpgsql;

create or replace
function get_jsonb(
  anode_id integer
) returns jsonb as $$
begin
  return jsonb_build_object('node_id', anode_id);
end;
$$ language plpgsql;
