package main
import "core:fmt"
import "base:runtime"
import "core:reflect"
import "core:strings"
import sql "../odin-postgresql"

My_Type :: struct {
	name: string,
	looks_like: string,
	talks_like: string,
	is_a_vampire: bool,
	fear_factor: f64 `(5, 2)`,
}

get_sql_data_type :: proc(type_info: ^runtime.Type_Info) -> (result: string, ok: bool) {
	b: strings.Builder
	base_type_info := runtime.type_info_base(type_info)
	#partial switch type in type_info.variant {
	case runtime.Type_Info_Integer:
		strings.write_string(&b, "INT")
	case runtime.Type_Info_Boolean:
		strings.write_string(&b, "BOOL")
	case runtime.Type_Info_String:
		strings.write_string(&b, "NVARCHAR")
	case runtime.Type_Info_Float:
		strings.write_string(&b, "DECIMAL")
	}
	ok = true
	result = strings.to_string(b)
	return
}

command_to_create_table_for_struct :: proc(conn: sql.Conn, name: string, type: typeid) -> (result: cstring, ok: bool) {
	b: strings.Builder
	fmt.sbprintf(&b, "CREATE TABLE {:s} (", name)
	struct_info := runtime.type_info_base(type_info_of(type)).variant.(runtime.Type_Info_Struct) or_return
	for i in 0..<struct_info.field_count {
		if i > 0 {
			strings.write_byte(&b, ',')
		}
		strings.write_string(&b, struct_info.names[i])
		strings.write_byte(&b, ' ')
		strings.write_string(&b, get_sql_data_type(struct_info.types[i]) or_continue)
	}
	ok = true
	result = strings.to_cstring(&b)
	return
}

populate_array_with_results :: proc(result: sql.Result, data: []$T) {

}

insert_into_table :: proc(conn: sql.Conn, table: string, data: []$T) {

}

main :: proc() {
	conn := sql.connectdb("postgresql://crypt_owner:Os4FzS1gJRUf@ep-twilight-grass-a5phs3hk.us-east-2.aws.neon.tech/crypt?sslmode=require")
	defer sql.finish(conn)

	conn_status := sql.status(conn)
	if conn_status != .Ok {
		fmt.println(conn_status)
		return
	}

	result := sql.exec(conn, "SELECT * FROM public.playing_with_neon ORDER BY value ASC;")
	if sql.result_status(result) == .Tuples_OK {
		field_count := sql.n_fields(result)
		for i in 0..<field_count {
			fmt.printf("{},\t", sql.f_name(result, i))
		}
		fmt.print("\n")
		for i in 0..<sql.n_tuples(result) {
			for j in 0..<field_count {
				fmt.printf("{},\t", cstring(sql.get_value(result, i, j)))
			}
			fmt.print("\n")
		}
	} else {
		fmt.println(sql.result_status(result))
	}
}