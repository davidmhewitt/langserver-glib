code_files = files(
    'Client.vala',
    'Logger.vala',
    'Server.vala',
    'Types.vala',
)

langserver_lib = library(
    meson.project_name (),
    code_files,
    dependencies: dependencies
)

langserver_include = include_directories('../lib')
langserver_dep = declare_dependency(link_with : langserver_lib, include_directories: langserver_include)
