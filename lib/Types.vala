/*
* Copyright (c) 2018 David Hewitt (https://github.com/davidmhewitt)
*
* This file is part of Vala Language Server (VLS).
*
* VLS is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* VLS is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with VLS.  If not, see <http://www.gnu.org/licenses/>.
*/

namespace LanguageServer.Types {

/**
 * Defines how the host (editor) should sync document changes to the language server.
 */
public enum TextDocumentSyncKind {
    Unset = -1,
    /**
     * Documents should not be synced at all.
     */
    None = 0,
    /**
     * Documents are synced by always sending the full content of the document.
     */
    Full = 1,
    /**
     * Documents are synced by sending the full content on open. After that only incremental
     * updates to the document are sent.
     */
     Incremental = 2
}

public class SaveOptions : Object {
    /**
    * The client is supposed to include the content on save.
    */
    public bool includeText { get; set; }
}

public class TextDocumentSyncOptions : Object {
    /**
     * Open and close notifications are sent to the server.
     */
    public bool openClose { get; set; }

    /**
     * Change notifications are sent to the server. See TextDocumentSyncKind.None, TextDocumentSyncKind.Full
     * and TextDocumentSyncKindIncremental.
     */
    public TextDocumentSyncKind change { get; set; default = TextDocumentSyncKind.Unset; }

    /**
     * Will save notifications are sent to the server.
     */
    public bool willSave { get; set; }

    /**
     * Will save wait until requests are sent to the server.
     */
    public bool willSaveWaitUntil { get; set; }

    /**
     * Save notifications are sent to the server.
     */
    public SaveOptions save { get; set; }
}

public class ServerCapabilities : Object {
    /**
     * Defines how text documents are synced. Is either a detailed structure defining each notification or
     * for backwards compatibility the TextDocumentSyncKind number.
     */
    public TextDocumentSyncOptions textDocumentSync { get; set; }

    /**
	 * The server provides document formatting.
	 */
    public bool documentFormattingProvider { get; set; }
}

public class DocumentFormattingParams : Object {
    /**
     * The document to format.
     */
    public string textDocument { get; set; }

    /**
     * The format options.
     */
    public FormattingOptions options { get; set; }
}

public class FormattingOptions : Object {
    /**
     * Size of a tab in spaces.
     */
    public int tabSize { get; set; }

    /**
     * Prefer spaces over tabs.
     */
    public bool insertSpaces { get; set; }
}

public class TextEdit : Object {
    /**
     * The range of the text document to be manipulated. To insert
     * text into a document create a range where start === end.
     */
    public Range range { get; set; }

    /**
     * The string to be inserted. For delete operations use an
     * empty string.
     */
    public string newText { get; set; }
}

public class InitializeResult : Object {
    /**
     * The capabilities the language server provides.
     */
     public ServerCapabilities capabilities { get; set; }
}

public class TextDocumentItem : Object {
    /**
     * The text document's URI.
     */
    public string uri { get; set; }

    /**
     * The text document's language identifier.
     */
    public string languageId { get; set; }

    /**
     * The version number of this document (it will increase after each
     * change, including undo/redo).
     */
    public int number { get; set; }

    /**
     * The content of the opened text document.
     */
    public string text { get; set; }
}

public class DidOpenTextDocumentParams : Object {
    /**
     * The document that was opened.
     */
    public TextDocumentItem textDocument { get; set; }
}

public class DidChangeTextDocumentParams : Object, Json.Serializable {
    /**
	 * The document that did change. The version number points
	 * to the version after all provided content changes have
	 * been applied.
	 */
    public VersionedTextDocumentIdentifier textDocument { get; set; }

	/**
	 * The actual content changes. The content changes describe single state changes
	 * to the document. So if there are two content changes c1 and c2 for a document
	 * in state S10 then c1 move the document to S11 and c2 to S12.
	 */
    public Gee.ArrayList<TextDocumentContentChangeEvent> contentChanges { get; set; }

    public unowned ParamSpec? find_property (string name)
    {
        return ((ObjectClass) get_type ().class_ref ()).find_property (name);
    }

    public Json.Node serialize_property (string property_name, Value @value, ParamSpec pspec) {
        if (@value.type ().is_a (typeof (Gee.ArrayList))) {
            unowned Gee.ArrayList<GLib.Object> arraylist_value = @value as Gee.ArrayList<GLib.Object>;
            if (arraylist_value != null && property_name == "contentChanges") {
                var array = new Json.Array.sized (arraylist_value.size);

                foreach (var item in arraylist_value) {
                    array.add_element (Json.gobject_serialize (item));
                }

                var node = new Json.Node (Json.NodeType.ARRAY);
                node.set_array (array);
                return node;
            }
        }

        return default_serialize_property (property_name, @value, pspec);
    }

    public bool deserialize_property (string property_name, out Value @value, ParamSpec pspec, Json.Node property_node) {
        if (property_name == "contentChanges") {
            var node = property_node.get_array ();
            if (node != null) {
                var arraylist = new Gee.ArrayList<Object> ();
                node.foreach_element ((arr, i, change) => {
                    var new_change = Json.gobject_deserialize (typeof (TextDocumentContentChangeEvent), change);
                    arraylist.add (new_change);
                });

                @value = Value (typeof (Gee.ArrayList<Object>));
                @value.set_object (arraylist);
                return true;
            } else {
                return false;
            }
        }

        if (property_name == "textDocument") {
            @value = Value (typeof (VersionedTextDocumentIdentifier));
            @value.set_object (Json.gobject_deserialize (typeof (VersionedTextDocumentIdentifier), property_node));
            return true;
        }

		return default_deserialize_property (property_name, out @value, pspec, property_node);
    }
}

public class VersionedTextDocumentIdentifier : Object {
    /**
     * The text document's URI.
     */
    public string uri { get; set; }

	/**
	 * The version number of this document. If a versioned text document identifier
	 * is sent from the server to the client and the file is not open in the editor
	 * (the server has not received an open notification before) the server can send
	 * `null` to indicate that the version is known and the content on disk is the
	 * truth (as speced with document content ownership)
	 */
    public int version { get; set; }
}


/**
 * An event describing a change to a text document. If range and rangeLength are omitted
 * the new text is considered to be the full content of the document.
 */
public class TextDocumentContentChangeEvent : Object {
    /**
	 * The range of the document that changed.
	 */
    public Range? range { get; set; }

	/**
	 * The length of the range that got replaced.
	 */
    public int rangeLength { get; set; }

	/**
	 * The new text of the range/document.
	 */
    public string text { get; set; }
}

public class InitializeParams : Object {
    /**
     * The process Id of the parent process that started
     * the server. Is null if the process has not been started by another process.
     * If the parent process is not alive then the server should exit (see exit notification) its process.
     */
    public int processId { get; set; }

    /**
     * The rootPath of the workspace. Is null
     * if no folder is open.
     *
     * @deprecated in favour of rootUri.
     */
    public string rootPath { get; set; }

    /**
     * The rootUri of the workspace. Is null if no
     * folder is open. If both `rootPath` and `rootUri` are set
     * `rootUri` wins.
     */
    public string rootUri { get; set; }

    // TODO: Add capabilities

    /**
     * The initial trace setting. If omitted trace is disabled ('off').
     */
    public string trace { get; set; }
}

public class PublishDiagnosticsParams : Object, Json.Serializable {
    /**
     * The URI for which diagnostic information is reported.
     */
    public string uri { get; set; }

    /**
     * An array of diagnostic information items.
     */
    public Gee.ArrayList<Diagnostic> diagnostics { get; set; }

    public unowned ParamSpec? find_property (string name)
    {
        return ((ObjectClass) get_type ().class_ref ()).find_property (name);
    }

    public Json.Node serialize_property (string property_name, Value @value, ParamSpec pspec) {
        if (@value.type ().is_a (typeof (Gee.ArrayList))) {
            unowned Gee.ArrayList<GLib.Object> arraylist_value = @value as Gee.ArrayList<GLib.Object>;
            if (arraylist_value != null) {
                var array = new Json.Array.sized (arraylist_value.size);

                foreach (var item in arraylist_value) {
                    array.add_element (Json.gobject_serialize (item));
                }

                var node = new Json.Node (Json.NodeType.ARRAY);
                node.set_array (array);
                return node;
            }
        }

        return default_serialize_property (property_name, @value, pspec);
    }

    public bool deserialize_property (string property_name, out Value @value, ParamSpec pspec, Json.Node property_node) {
		return default_deserialize_property (property_name, out @value, pspec, property_node);
    }
}

public class Diagnostic : Object {
    /**
     * The range at which the message applies.
     */
    public Range range { get; set; }

    /**
     * The diagnostic's severity. Can be omitted. If omitted it is up to the
     * client to interpret diagnostics as error, warning, info or hint.
     */
    public DiagnosticSeverity severity { get; set; default = DiagnosticSeverity.Unset; }

    /**
     * A human-readable string describing the source of this
     * diagnostic, e.g. 'typescript' or 'super lint'.
     */
    public string source { get; set; }

    /**
     * The diagnostic's message.
     */
    public string message { get; set; }
}

public class Range : Object {
    /**
     * The range's start position.
     */
    public Position start { get; set; }

    /**
     * The range's end position.
     */
    public Position end { get; set; }
}

public class Position : Object {
    /**
     * Line position in a document (zero-based).
     */
    public int line { get; set; }

    /**
     * Character offset on a line in a document (zero-based). Assuming that the line is
     * represented as a string, the `character` value represents the gap between the
     * `character` and `character + 1`.
     *
     * If the character value is greater than the line length it defaults back to the
     * line length.
     */
    public int character { get; set; }
}

public enum DiagnosticSeverity {
    Unset = -1,

    /**
     * Reports an error.
     */
    Error = 1,
    /**
     * Reports a warning.
     */
    Warning = 2,
    /**
     * Reports an information.
     */
    Information = 3,
    /**
     * Reports a hint.
     */
    Hint = 4
}
}
