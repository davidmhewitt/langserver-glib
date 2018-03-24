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

public abstract class Server : Object {
    public bool supports_document_formatting { get; construct; default = false; }

    public signal void exit (int return_code);
    protected abstract void did_open (Types.TextDocumentItem document);
    protected abstract void did_change (Types.DidChangeTextDocumentParams params);
    protected abstract void initialize (Types.InitializeParams init_params);
    protected virtual Gee.ArrayList<Types.TextEdit>? format_document (Types.DocumentFormattingParams format_params) { return null; }
    protected virtual Types.Position? get_definition (Types.TextDocumentPositionParams definition_params) {return null; }
    protected abstract void cleanup ();

    private Jsonrpc.Server server;
    private Jsonrpc.Client client;
    private bool shutdown_requested = false;
    private bool initialized = false;

    private const string[] KNOWN_METHODS = {
        "initialize",
        "textDocument/formatting",
        "shutdown"
    };

    construct {
        Log.set_default_handler (Logger.log_handler);

        server = new Jsonrpc.Server ();
        var stdin = new UnixInputStream (Posix.STDIN_FILENO, false);
        var stdout = new UnixOutputStream (Posix.STDOUT_FILENO, false);
        server.accept_io_stream (new SimpleIOStream (stdin, stdout));

        server.notification.connect (handle_notification);
        server.handle_call.connect (handle_method);
    }

    private void handle_initialize (Jsonrpc.Client client, Variant id, Variant params) {
        var data = Json.gvariant_serialize (params);
        var init_params = Json.gobject_deserialize (typeof (Types.InitializeParams), data) as Types.InitializeParams;

        debug (Json.to_string (data, true));

        initialize (init_params);

        var caps = new Types.InitializeResult () {
            capabilities = new Types.ServerCapabilities () {
                textDocumentSync = new Types.TextDocumentSyncOptions () {
                    openClose = true,
                    // TODO: Implement incremental syncs
                    change = Types.TextDocumentSyncKind.Full,
                    willSave = false,
                    willSaveWaitUntil = false,
                    save = new Types.SaveOptions () {
                        includeText = false
                    }
                },
                documentFormattingProvider = supports_document_formatting
            }
        };

        var node = Json.gobject_serialize (caps);
        debug (Json.to_string (node, true));

        var result = Json.gvariant_deserialize (node, null);
        client.reply (id, result, null);

        initialized = true;
    }

    protected void publish_diagnostics (Types.PublishDiagnosticsParams params) {
        debug ("sending diagnostics");

        var node = Json.gobject_serialize (params);
        debug (Json.to_string (node, true));
        var diags = Json.gvariant_deserialize (node, null);

        client.send_notification ("textDocument/publishDiagnostics", diags, null);
    }

    protected virtual void handle_shutdown (Jsonrpc.Client client, Variant id) {
        shutdown_requested = true;
        cleanup ();
        client.reply (id, null, null);
    }

    private bool handle_method (Jsonrpc.Client client, string method, Variant id, Variant params) {
        this.client = client;

        debug (@"Got method call: $method");

        if (!initialized && method in KNOWN_METHODS && method != "initialize") {
            client.reply_error_async.begin (id, -32002, "Server not yet initialized", null);
        }

        switch (method) {
            case "shutdown":
                handle_shutdown (client, id);
                return true;
            case "initialize":
                handle_initialize (client, id, params);
                return true;
            case "textDocument/formatting":
                var data = Json.gvariant_serialize (params);
                var format_params = Json.gobject_deserialize (typeof (Types.DocumentFormattingParams), data)
                                    as Types.DocumentFormattingParams;

                var result = format_document (format_params);
                if (result == null) {
                    client.reply (id, null, null);
                    return true;
                }

                var array = new Json.Array.sized (result.size);

                foreach (var item in result) {
                    array.add_element (Json.gobject_serialize (item));
                }

                var node = new Json.Node (Json.NodeType.ARRAY);
                node.set_array (array);

                client.reply (id, Json.gvariant_deserialize (node, null), null);
                return true;
            case "textDocument/definition":
                var data = Json.gvariant_serialize (params);
                var definition_params = Json.gobject_deserialize (typeof (Types.TextDocumentPositionParams), data)
                                        as Types.TextDocumentPositionParams;

                var result = get_definition (definition_params);
                if (result == null) {
                    client.reply (id, null, null);
                    return true;
                }

                var node = Json.gobject_serialize (result);
                client.reply (id, Json.gvariant_deserialize (node, null), null);
                return true;
            default:
                return false;
        }
    }

    private void handle_notification (Jsonrpc.Client client, string method, Variant params) {
        this.client = client;

        debug (@"Got notification: $method");

        if (!initialized && method != "exit") {
            debug ("Server not initialized yet, ignoring notification");
            return;
        }

        switch (method) {
            case "exit":
                exit (shutdown_requested ? 0 : 1);
                break;
            case "textDocument/didOpen":
                var data = Json.gvariant_serialize (params);
                var item = Json.gobject_deserialize (typeof (Types.DidOpenTextDocumentParams), data)
                           as Types.DidOpenTextDocumentParams;

                did_open (item.textDocument);
                break;
            case "textDocument/didChange":
                var data = Json.gvariant_serialize (params);
                debug (Json.to_string (data, true));
                var item = Json.gobject_deserialize (typeof (Types.DidChangeTextDocumentParams), data)
                           as Types.DidChangeTextDocumentParams;

                did_change (item);
                break;
            default:
                debug (@"No handler for: $method");
                break;
        }
    }
}
}
