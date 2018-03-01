code_files = files(
    'ExitTest.vala',
    'InitializeTest.vala',
    'VlsTest.vala'
)

test_exec = executable(
    meson.project_name() + '-test',
    code_files,
    dependencies: [langserver_dep, dependencies]
)

test ('language server tests', test_exec)
