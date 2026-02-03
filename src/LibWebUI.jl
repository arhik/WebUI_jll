module LibWebUI

using WebUI_jll
export WebUI_jll

using CEnum: CEnum, @cenum

using Libdl
using Pkg
using Pkg.Artifacts

const SIZE_MAX = 2^32
const UINT16_MAX = 0xffff
const UINT32_MAX = 0xffffffff
const UINT64_MAX = 0xffffffffffffffff

artifact_toml = joinpath(@__DIR__, "..", "Artifacts.toml")

webui_hash = artifact_hash("WebUI", artifact_toml)

webuilibpath = artifact_path(webui_hash)
resourceName = "webui-2"
const libWebUI = "$webuilibpath/lib/$resourceName.$(Libdl.dlext)" |> normpath


@cenum webui_browser::UInt32 begin
    NoBrowser = 0
    AnyBrowser = 1
    Chrome = 2
    Firefox = 3
    Edge = 4
    Safari = 5
    Chromium = 6
    Opera = 7
    Brave = 8
    Vivaldi = 9
    Epic = 10
    Yandex = 11
    ChromiumBased = 12
    Webview = 13
end

@cenum webui_runtime::UInt32 begin
    None = 0
    Deno = 1
    NodeJS = 2
    Bun = 3
end

@cenum webui_event::UInt32 begin
    WEBUI_EVENT_DISCONNECTED = 0
    WEBUI_EVENT_CONNECTED = 1
    WEBUI_EVENT_MOUSE_CLICK = 2
    WEBUI_EVENT_NAVIGATION = 3
    WEBUI_EVENT_CALLBACK = 4
end

@cenum webui_config::UInt32 begin
    show_wait_connection = 0
    ui_event_blocking = 1
    folder_monitor = 2
    multi_client = 3
    use_cookies = 4
    asynchronous_response = 5
end

struct webui_event_t
    window::Csize_t
    event_type::Csize_t
    element::Ptr{Cchar}
    event_number::Csize_t
    bind_id::Csize_t
    client_id::Csize_t
    connection_id::Csize_t
    cookies::Ptr{Cchar}
end

@cenum webui_logger_level::UInt32 begin
    WEBUI_LOGGER_LEVEL_DEBUG = 0
    WEBUI_LOGGER_LEVEL_INFO = 1
    WEBUI_LOGGER_LEVEL_ERROR = 2
end

function webui_new_window()
    @ccall WebUI.webui_new_window()::Csize_t
end

function webui_new_window_id(window_number)
    @ccall WebUI.webui_new_window_id(window_number::Csize_t)::Csize_t
end

function webui_get_new_window_id()
    @ccall WebUI.webui_get_new_window_id()::Csize_t
end

function webui_bind(window, element, func)
    @ccall WebUI.webui_bind(window::Csize_t, element::Ptr{Cchar}, func::Ptr{Cvoid})::Csize_t
end

function webui_set_context(window, element, context)
    @ccall WebUI.webui_set_context(window::Csize_t, element::Ptr{Cchar}, context::Ptr{Cvoid})::Cvoid
end

function webui_get_context(e)
    @ccall WebUI.webui_get_context(e::Ptr{webui_event_t})::Ptr{Cvoid}
end

function webui_get_best_browser(window)
    @ccall WebUI.webui_get_best_browser(window::Csize_t)::Csize_t
end

function webui_show(window, content)
    @ccall WebUI.webui_show(window::Csize_t, content::Ptr{Cchar})::Bool
end

function webui_show_client(e, content)
    @ccall WebUI.webui_show_client(e::Ptr{webui_event_t}, content::Ptr{Cchar})::Bool
end

function webui_show_browser(window, content, browser)
    @ccall WebUI.webui_show_browser(window::Csize_t, content::Ptr{Cchar}, browser::Csize_t)::Bool
end

function webui_start_server(window, content)
    @ccall WebUI.webui_start_server(window::Csize_t, content::Ptr{Cchar})::Ptr{Cchar}
end

function webui_show_wv(window, content)
    @ccall WebUI.webui_show_wv(window::Csize_t, content::Ptr{Cchar})::Bool
end

function webui_set_kiosk(window, status)
    @ccall WebUI.webui_set_kiosk(window::Csize_t, status::Bool)::Cvoid
end

function webui_set_custom_parameters(window, params)
    @ccall WebUI.webui_set_custom_parameters(window::Csize_t, params::Ptr{Cchar})::Cvoid
end

function webui_set_high_contrast(window, status)
    @ccall WebUI.webui_set_high_contrast(window::Csize_t, status::Bool)::Cvoid
end

function webui_set_resizable(window, status)
    @ccall WebUI.webui_set_resizable(window::Csize_t, status::Bool)::Cvoid
end

function webui_is_high_contrast()
    @ccall WebUI.webui_is_high_contrast()::Bool
end

function webui_browser_exist(browser)
    @ccall WebUI.webui_browser_exist(browser::Csize_t)::Bool
end

function webui_wait()
    @ccall WebUI.webui_wait()::Cvoid
end

function webui_wait_async()
    @ccall WebUI.webui_wait_async()::Bool
end

function webui_close(window)
    @ccall WebUI.webui_close(window::Csize_t)::Cvoid
end

function webui_minimize(window)
    @ccall WebUI.webui_minimize(window::Csize_t)::Cvoid
end

function webui_maximize(window)
    @ccall WebUI.webui_maximize(window::Csize_t)::Cvoid
end

function webui_close_client(e)
    @ccall WebUI.webui_close_client(e::Ptr{webui_event_t})::Cvoid
end

function webui_destroy(window)
    @ccall WebUI.webui_destroy(window::Csize_t)::Cvoid
end

function webui_exit()
    @ccall WebUI.webui_exit()::Cvoid
end

function webui_set_root_folder(window, path)
    @ccall WebUI.webui_set_root_folder(window::Csize_t, path::Ptr{Cchar})::Bool
end

function webui_set_browser_folder(path)
    @ccall WebUI.webui_set_browser_folder(path::Ptr{Cchar})::Cvoid
end

function webui_set_default_root_folder(path)
    @ccall WebUI.webui_set_default_root_folder(path::Ptr{Cchar})::Bool
end

function webui_set_close_handler_wv(window, close_handler)
    @ccall WebUI.webui_set_close_handler_wv(window::Csize_t, close_handler::Ptr{Cvoid})::Cvoid
end

function webui_set_file_handler(window, handler)
    @ccall WebUI.webui_set_file_handler(window::Csize_t, handler::Ptr{Cvoid})::Cvoid
end

function webui_set_file_handler_window(window, handler)
    @ccall WebUI.webui_set_file_handler_window(window::Csize_t, handler::Ptr{Cvoid})::Cvoid
end

function webui_interface_set_response_file_handler(window, response, length)
    @ccall WebUI.webui_interface_set_response_file_handler(window::Csize_t, response::Ptr{Cvoid}, length::Cint)::Cvoid
end

function webui_is_shown(window)
    @ccall WebUI.webui_is_shown(window::Csize_t)::Bool
end

function webui_set_timeout(second)
    @ccall WebUI.webui_set_timeout(second::Csize_t)::Cvoid
end

function webui_set_icon(window, icon, icon_type)
    @ccall WebUI.webui_set_icon(window::Csize_t, icon::Ptr{Cchar}, icon_type::Ptr{Cchar})::Cvoid
end

function webui_encode(str)
    @ccall WebUI.webui_encode(str::Ptr{Cchar})::Ptr{Cchar}
end

function webui_decode(str)
    @ccall WebUI.webui_decode(str::Ptr{Cchar})::Ptr{Cchar}
end

function webui_free(ptr)
    @ccall WebUI.webui_free(ptr::Ptr{Cvoid})::Cvoid
end

function webui_malloc(size)
    @ccall WebUI.webui_malloc(size::Csize_t)::Ptr{Cvoid}
end

function webui_memcpy(dest, src, count)
    @ccall WebUI.webui_memcpy(dest::Ptr{Cvoid}, src::Ptr{Cvoid}, count::Csize_t)::Cvoid
end

function webui_send_raw(window, _function, raw, size)
    @ccall WebUI.webui_send_raw(window::Csize_t, _function::Ptr{Cchar}, raw::Ptr{Cvoid}, size::Csize_t)::Cvoid
end

function webui_send_raw_client(e, _function, raw, size)
    @ccall WebUI.webui_send_raw_client(e::Ptr{webui_event_t}, _function::Ptr{Cchar}, raw::Ptr{Cvoid}, size::Csize_t)::Cvoid
end

function webui_set_hide(window, status)
    @ccall WebUI.webui_set_hide(window::Csize_t, status::Bool)::Cvoid
end

function webui_set_size(window, width, height)
    @ccall WebUI.webui_set_size(window::Csize_t, width::Cuint, height::Cuint)::Cvoid
end

function webui_set_minimum_size(window, width, height)
    @ccall WebUI.webui_set_minimum_size(window::Csize_t, width::Cuint, height::Cuint)::Cvoid
end

function webui_set_position(window, x, y)
    @ccall WebUI.webui_set_position(window::Csize_t, x::Cuint, y::Cuint)::Cvoid
end

function webui_set_center(window)
    @ccall WebUI.webui_set_center(window::Csize_t)::Cvoid
end

function webui_set_profile(window, name, path)
    @ccall WebUI.webui_set_profile(window::Csize_t, name::Ptr{Cchar}, path::Ptr{Cchar})::Cvoid
end

function webui_set_proxy(window, proxy_server)
    @ccall WebUI.webui_set_proxy(window::Csize_t, proxy_server::Ptr{Cchar})::Cvoid
end

function webui_get_url(window)
    @ccall WebUI.webui_get_url(window::Csize_t)::Ptr{Cchar}
end

function webui_open_url(url)
    @ccall WebUI.webui_open_url(url::Ptr{Cchar})::Cvoid
end

function webui_set_public(window, status)
    @ccall WebUI.webui_set_public(window::Csize_t, status::Bool)::Cvoid
end

function webui_navigate(window, url)
    @ccall WebUI.webui_navigate(window::Csize_t, url::Ptr{Cchar})::Cvoid
end

function webui_navigate_client(e, url)
    @ccall WebUI.webui_navigate_client(e::Ptr{webui_event_t}, url::Ptr{Cchar})::Cvoid
end

function webui_clean()
    @ccall WebUI.webui_clean()::Cvoid
end

function webui_delete_all_profiles()
    @ccall WebUI.webui_delete_all_profiles()::Cvoid
end

function webui_delete_profile(window)
    @ccall WebUI.webui_delete_profile(window::Csize_t)::Cvoid
end

function webui_get_parent_process_id(window)
    @ccall WebUI.webui_get_parent_process_id(window::Csize_t)::Csize_t
end

function webui_get_child_process_id(window)
    @ccall WebUI.webui_get_child_process_id(window::Csize_t)::Csize_t
end

function webui_win32_get_hwnd(window)
    @ccall WebUI.webui_win32_get_hwnd(window::Csize_t)::Ptr{Cvoid}
end

function webui_get_hwnd(window)
    @ccall WebUI.webui_get_hwnd(window::Csize_t)::Ptr{Cvoid}
end

function webui_get_port(window)
    @ccall WebUI.webui_get_port(window::Csize_t)::Csize_t
end

function webui_set_port(window, port)
    @ccall WebUI.webui_set_port(window::Csize_t, port::Csize_t)::Bool
end

function webui_get_free_port()
    @ccall WebUI.webui_get_free_port()::Csize_t
end

function webui_set_logger(func, user_data)
    @ccall WebUI.webui_set_logger(func::Ptr{Cvoid}, user_data::Ptr{Cvoid})::Cvoid
end

function webui_set_config(option, status)
    @ccall WebUI.webui_set_config(option::webui_config, status::Bool)::Cvoid
end

function webui_set_event_blocking(window, status)
    @ccall WebUI.webui_set_event_blocking(window::Csize_t, status::Bool)::Cvoid
end

function webui_set_frameless(window, status)
    @ccall WebUI.webui_set_frameless(window::Csize_t, status::Bool)::Cvoid
end

function webui_set_transparent(window, status)
    @ccall WebUI.webui_set_transparent(window::Csize_t, status::Bool)::Cvoid
end

function webui_get_mime_type(file)
    @ccall WebUI.webui_get_mime_type(file::Ptr{Cchar})::Ptr{Cchar}
end

function webui_set_tls_certificate(certificate_pem, private_key_pem)
    @ccall WebUI.webui_set_tls_certificate(certificate_pem::Ptr{Cchar}, private_key_pem::Ptr{Cchar})::Bool
end

function webui_run(window, script)
    @ccall WebUI.webui_run(window::Csize_t, script::Ptr{Cchar})::Cvoid
end

function webui_run_client(e, script)
    @ccall WebUI.webui_run_client(e::Ptr{webui_event_t}, script::Ptr{Cchar})::Cvoid
end

function webui_script(window, script, timeout, buffer, buffer_length)
    @ccall WebUI.webui_script(window::Csize_t, script::Ptr{Cchar}, timeout::Csize_t, buffer::Ptr{Cchar}, buffer_length::Csize_t)::Bool
end

function webui_script_client(e, script, timeout, buffer, buffer_length)
    @ccall WebUI.webui_script_client(e::Ptr{webui_event_t}, script::Ptr{Cchar}, timeout::Csize_t, buffer::Ptr{Cchar}, buffer_length::Csize_t)::Bool
end

function webui_set_runtime(window, runtime)
    @ccall WebUI.webui_set_runtime(window::Csize_t, runtime::Csize_t)::Cvoid
end

function webui_get_count(e)
    @ccall WebUI.webui_get_count(e::Ptr{webui_event_t})::Csize_t
end

function webui_get_int_at(e, index)
    @ccall WebUI.webui_get_int_at(e::Ptr{webui_event_t}, index::Csize_t)::Clonglong
end

function webui_get_int(e)
    @ccall WebUI.webui_get_int(e::Ptr{webui_event_t})::Clonglong
end

function webui_get_float_at(e, index)
    @ccall WebUI.webui_get_float_at(e::Ptr{webui_event_t}, index::Csize_t)::Cdouble
end

function webui_get_float(e)
    @ccall WebUI.webui_get_float(e::Ptr{webui_event_t})::Cdouble
end

function webui_get_string_at(e, index)
    @ccall WebUI.webui_get_string_at(e::Ptr{webui_event_t}, index::Csize_t)::Ptr{Cchar}
end

function webui_get_string(e)
    @ccall WebUI.webui_get_string(e::Ptr{webui_event_t})::Ptr{Cchar}
end

function webui_get_bool_at(e, index)
    @ccall WebUI.webui_get_bool_at(e::Ptr{webui_event_t}, index::Csize_t)::Bool
end

function webui_get_bool(e)
    @ccall WebUI.webui_get_bool(e::Ptr{webui_event_t})::Bool
end

function webui_get_size_at(e, index)
    @ccall WebUI.webui_get_size_at(e::Ptr{webui_event_t}, index::Csize_t)::Csize_t
end

function webui_get_size(e)
    @ccall WebUI.webui_get_size(e::Ptr{webui_event_t})::Csize_t
end

function webui_return_int(e, n)
    @ccall WebUI.webui_return_int(e::Ptr{webui_event_t}, n::Clonglong)::Cvoid
end

function webui_return_float(e, f)
    @ccall WebUI.webui_return_float(e::Ptr{webui_event_t}, f::Cdouble)::Cvoid
end

function webui_return_string(e, s)
    @ccall WebUI.webui_return_string(e::Ptr{webui_event_t}, s::Ptr{Cchar})::Cvoid
end

function webui_return_bool(e, b)
    @ccall WebUI.webui_return_bool(e::Ptr{webui_event_t}, b::Bool)::Cvoid
end

# no prototype is found for this function at webui.h:1271:21, please use with caution
function webui_get_last_error_number()
    @ccall WebUI.webui_get_last_error_number()::Csize_t
end

# no prototype is found for this function at webui.h:1278:26, please use with caution
function webui_get_last_error_message()
    @ccall WebUI.webui_get_last_error_message()::Ptr{Cchar}
end

function webui_interface_bind(window, element, func)
    @ccall WebUI.webui_interface_bind(window::Csize_t, element::Ptr{Cchar}, func::Ptr{Cvoid})::Csize_t
end

function webui_interface_set_response(window, event_number, response)
    @ccall WebUI.webui_interface_set_response(window::Csize_t, event_number::Csize_t, response::Ptr{Cchar})::Cvoid
end

function webui_interface_is_app_running()
    @ccall WebUI.webui_interface_is_app_running()::Bool
end

function webui_interface_get_window_id(window)
    @ccall WebUI.webui_interface_get_window_id(window::Csize_t)::Csize_t
end

function webui_interface_get_string_at(window, event_number, index)
    @ccall WebUI.webui_interface_get_string_at(window::Csize_t, event_number::Csize_t, index::Csize_t)::Ptr{Cchar}
end

function webui_interface_get_int_at(window, event_number, index)
    @ccall WebUI.webui_interface_get_int_at(window::Csize_t, event_number::Csize_t, index::Csize_t)::Clonglong
end

function webui_interface_get_float_at(window, event_number, index)
    @ccall WebUI.webui_interface_get_float_at(window::Csize_t, event_number::Csize_t, index::Csize_t)::Cdouble
end

function webui_interface_get_bool_at(window, event_number, index)
    @ccall WebUI.webui_interface_get_bool_at(window::Csize_t, event_number::Csize_t, index::Csize_t)::Bool
end

function webui_interface_get_size_at(window, event_number, index)
    @ccall WebUI.webui_interface_get_size_at(window::Csize_t, event_number::Csize_t, index::Csize_t)::Csize_t
end

function webui_interface_show_client(window, event_number, content)
    @ccall WebUI.webui_interface_show_client(window::Csize_t, event_number::Csize_t, content::Ptr{Cchar})::Bool
end

function webui_interface_close_client(window, event_number)
    @ccall WebUI.webui_interface_close_client(window::Csize_t, event_number::Csize_t)::Cvoid
end

function webui_interface_send_raw_client(window, event_number, _function, raw, size)
    @ccall WebUI.webui_interface_send_raw_client(window::Csize_t, event_number::Csize_t, _function::Ptr{Cchar}, raw::Ptr{Cvoid}, size::Csize_t)::Cvoid
end

function webui_interface_navigate_client(window, event_number, url)
    @ccall WebUI.webui_interface_navigate_client(window::Csize_t, event_number::Csize_t, url::Ptr{Cchar})::Cvoid
end

function webui_interface_run_client(window, event_number, script)
    @ccall WebUI.webui_interface_run_client(window::Csize_t, event_number::Csize_t, script::Ptr{Cchar})::Cvoid
end

function webui_interface_script_client(window, event_number, script, timeout, buffer, buffer_length)
    @ccall WebUI.webui_interface_script_client(window::Csize_t, event_number::Csize_t, script::Ptr{Cchar}, timeout::Csize_t, buffer::Ptr{Cchar}, buffer_length::Csize_t)::Bool
end

const WEBUI_VERSION = "2.5.0-beta.4"

const WEBUI_MAX_IDS = UINT16_MAX

const WEBUI_MAX_ARG = 16

# Skipping MacroDefinition: WEBUI_EXPORT extern

const WEBUI_GET_CURRENT_DIR = _getcwd

const WEBUI_FILE_EXIST = _access

const WEBUI_POPEN = _popen

const WEBUI_PCLOSE = _pclose

const WEBUI_MAX_PATH = MAX_PATH

end # module
