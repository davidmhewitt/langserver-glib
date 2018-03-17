project('langserver-glib', 'vala', 'c')

posix_dep = meson.get_compiler('vala').find_library('posix')

dependencies = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gio-unix-2.0'),
    dependency('gee-0.8'),
    dependency('json-glib-1.0'),
    dependency('jsonrpc-glib-1.0'),
    posix_dep,
]

subdir ('lib')
subdir ('test')
