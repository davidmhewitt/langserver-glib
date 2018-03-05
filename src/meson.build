code_files = files(
    'Application.vala',
    'BuildSystemAnalyzer.vala',
    'ProjectManager.vala',
    'Reporter.vala',
    'Server.vala',
    'ValaFormatter.vala'
)

executable(
    meson.project_name(),
    code_files,
    dependencies: [langserver_dep, dependencies],
    install: true,
)
