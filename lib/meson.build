code_files = files(
    'Client.vala',
    'Logger.vala',
    'Server.vala',
    'Types.vala',
)

langserver_lib = library(
    meson.project_name (),
    code_files,
    dependencies: dependencies,
    install: true,
    install_dir: [true, true, true]
)

pkg = import('pkgconfig')
libs = langserver_lib
pkg.generate(libraries : libs,
             version : '1.0',
             name : 'liblangserver-glib',
             filebase : 'langserver-glib',
             description : 'A GLib Language Server Implementation')

langserver_include = include_directories('../lib')
langserver_dep = declare_dependency(link_with : langserver_lib, include_directories: langserver_include)
