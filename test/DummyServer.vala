/*
* Copyright (c) 2018 David Hewitt (https://github.com/davidmhewitt)
*
* This file is part of GLib Language Server.
*
* GLib Language Server is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* GLib Language Server is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with GLib Language Server.  If not, see <http://www.gnu.org/licenses/>.
*/

public class Application : Object {
    private MainLoop loop;
    private int exit_code = 0;
    private DummyServer server;

    construct {
        loop = new MainLoop ();

        server = new DummyServer ();
        server.exit.connect ((code) => {
            exit_code = code;
            loop.quit ();
        });
    }

    public int run (string[] args) {
        loop.run ();
        return exit_code;
    }

    public static int main (string[] args) {
        var app = new Application ();
        return app.run (args);
    }
}

public class DummyServer : LanguageServer.Server {

    public DummyServer () {
        Object (
            supports_document_formatting: true
        );
    }

    protected override void initialize (LanguageServer.Types.InitializeParams init_params) {}
    protected override void did_open (LanguageServer.Types.TextDocumentItem document) {}
    protected override void did_change (LanguageServer.Types.DidChangeTextDocumentParams params) {}
    protected override Gee.ArrayList<LanguageServer.Types.TextEdit> format_document (LanguageServer.Types.DocumentFormattingParams params) {
        return new Gee.ArrayList<LanguageServer.Types.TextEdit> ();
    }
    protected override void cleanup () {}
}
