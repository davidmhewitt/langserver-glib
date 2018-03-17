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

public class ExitTest : BaseTest {
    public static void add_tests () {
        Test.add_func ("/langserver/server/exit_without_shutdown", () => {
            var client = new LanguageServer.Client (SERVER_PATH);
            var loop = new MainLoop ();
            client.server_closed.connect ((code) => {
                assert (code == 1);
                loop.quit ();
            });

            client.exit ();
            loop.run ();
        });

        Test.add_func ("/langserver/server/exit_with_shutdown", () => {
            var client = new LanguageServer.Client (SERVER_PATH);
            var loop = new MainLoop ();
            client.server_closed.connect ((code) => {
                assert (code == 0);
                loop.quit ();
            });

            client.shutdown.begin ((o, res) => {
                try {
                    client.shutdown.end (res);
                } catch (Error e) { }

                client.exit ();
            });

            loop.run ();
        });
    }
}
