server_files = files(
    'DummyServer.vala'
)

server_exec = executable(
    'dummy-server',
    server_files,
    dependencies: [langserver_dep, dependencies]
)

code_files = files(
    'ExitTest.vala',
    'InitializeTest.vala',
    'BaseTest.vala'
)

test_exec = executable(
    meson.project_name() + '-test',
    code_files,
    dependencies: [langserver_dep, dependencies]
)

test ('language server tests', test_exec)
