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

public class Logger : Object {
    private static Logger? _instance = null;

    FileStream log_file;

    construct {
        log_file = FileStream.open (@"$(Environment.get_tmp_dir())/langserver-glib-$(new DateTime.now_local()).log", "a");
    }

    private void log (string? domain, LogLevelFlags level, string message) {
        log_file.printf ("%s: %s\n", level_to_string (level), message);
        log_file.flush ();
    }

    private string level_to_string (LogLevelFlags level) {
        switch (level) {
            case LogLevelFlags.LEVEL_ERROR:
                return "ERROR";
            case LogLevelFlags.LEVEL_CRITICAL:
                return "CRITICAL";
            case LogLevelFlags.LEVEL_WARNING:
                return "WARNING";
            case LogLevelFlags.LEVEL_MESSAGE:
                return "MESSAGE";
            case LogLevelFlags.LEVEL_INFO:
                return "INFO";
            case LogLevelFlags.LEVEL_DEBUG:
                return "DEBUG";
            default:
                return "UNKNOWN";
        }
    }

    public static Logger get_default () {
        if (_instance == null) {
            _instance = new Logger ();
        }

        return _instance;
    }

    public static void log_handler (string? domain, LogLevelFlags level, string message) {
        Logger.get_default ().log (domain, level, message);
    }
}
}
