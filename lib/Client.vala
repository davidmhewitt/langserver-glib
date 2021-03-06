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

namespace LanguageServer {
public class Client : Object {
    public string server_path { get; construct; }
    public uint timeout_duration { get; construct; default = 3000; }

    public signal void server_closed (int exit_code);
    public signal void diagnostics_published (string uri, Gee.ArrayList<Types.Diagnostic> diagnostics);

    private Jsonrpc.Client vls_client;
    private Subprocess vls_server;
    private uint exit_timeout_id = 0;
    private bool file_pipes = false;

    public Client (string server_path, uint timeout_duration = 3000) {
        Object (timeout_duration: timeout_duration);

        vls_server = new Subprocess (SubprocessFlags.STDIN_PIPE | SubprocessFlags.STDOUT_PIPE, server_path);
        var stream = new SimpleIOStream (vls_server.get_stdout_pipe (), vls_server.get_stdin_pipe ());

        vls_client = new Jsonrpc.Client (stream);
        vls_client.notification.connect (handle_notification);
        await_process_end.begin ();
    }

    public Client.from_file_pipes (string stdin, string stdout) {
        file_pipes = true;

        var stdout_fd = Posix.open (stdout, Posix.O_NONBLOCK);
        var stdout_is = new UnixInputStream (stdout_fd, false);

        var stdin_fd = Posix.open (stdin, Posix.O_RDWR);
        var stdin_os = new UnixOutputStream (stdin_fd, false);

        var stream = new SimpleIOStream (stdout_is, stdin_os);

        vls_client = new Jsonrpc.Client (stream);
        vls_client.notification.connect (handle_notification);
    }

    private void handle_notification (Jsonrpc.Client client, string method, Variant? params) {
        switch (method) {
            case "textDocument/publishDiagnostics":
                if (params != null) {
                    var data = Json.gvariant_serialize (params);
                    var item = Json.gobject_deserialize (typeof (Types.PublishDiagnosticsParams), data)
                               as Types.PublishDiagnosticsParams;

                    diagnostics_published (item.uri, item.diagnostics);
                }

                break;
            default:
                debug (@"No handler for: $method");
                break;
        }
    }

    private async Variant? call_method (string method, Variant? params, Cancellable? cancellable) throws Error {
        var timeout_id = Timeout.add (timeout_duration, () => {
            warning ("Timeout on %s method call expired", method);

            return false;
        });

        Variant? return_value;

        try {
            yield vls_client.call_async (method, params, cancellable, out return_value);
        } catch (Error e) {
            Source.remove (timeout_id);
            throw e;
        }

        Source.remove (timeout_id);

        return return_value;
    }

    private async void await_process_end () {
        yield vls_server.wait_async ();
        server_closed (vls_server.get_exit_status ());

        if (exit_timeout_id != 0) {
            Source.remove (exit_timeout_id);
        }
    }

    public async void shutdown () throws Error {
        yield call_method ("shutdown", null, null);
    }

    public async Types.ServerCapabilities? initialize (Types.InitializeParams params) throws Error {
        var node = Json.gobject_serialize (params);
        var capabilities = Json.gvariant_deserialize (node, null);

        var result = yield call_method ("initialize", capabilities, null);
        if (result != null) {
            var data = Json.gvariant_serialize (result);
            var item = Json.gobject_deserialize (typeof (Types.InitializeResult), data)
                       as Types.InitializeResult;

            return item.capabilities;
        }

        return null;
    }

    public async Types.Location? locate_definition (Types.TextDocumentPositionParams params) {
        var node = Json.gobject_serialize (params);
        var definition_params = Json.gvariant_deserialize (node, null);

        var result = yield call_method ("textDocument/definition", definition_params, null);
        if (result != null) {
            var data = Json.gvariant_serialize (result);
            var item = Json.gobject_deserialize (typeof (Types.Location), data)
                       as Types.Location;

            return item;
        }

        return null;
    }

    public async void did_open (Types.TextDocumentItem item) {
        var params = new Types.DidOpenTextDocumentParams () {
            textDocument = item
        };

        var node = Json.gobject_serialize (params);
        var didopen_params = Json.gvariant_deserialize (node, null);

        vls_client.send_notification_async.begin ("textDocument/didOpen", didopen_params, null);
    }

    public async void did_change (Types.DidChangeTextDocumentParams params) {
        var node = Json.gobject_serialize (params);
        var didchange_params = Json.gvariant_deserialize (node, null);

        vls_client.send_notification_async.begin ("textDocument/didChange", didchange_params, null);
    }

    public void exit () {
        vls_client.send_notification_async.begin ("exit", null, null);

        if (!file_pipes) {
            exit_timeout_id = Timeout.add (3000, () => {
                warning ("Language server didn't close after exit request, killing the process");
                vls_server.force_exit ();

                exit_timeout_id = 0;
                return false;
            });
        } else {
            server_closed (0);
        }
    }
}
}
