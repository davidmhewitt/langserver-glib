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

public class InitializeTest : VlsTest {
    public static void add_tests () {
        Test.add_func ("/vls/server/method_without_initialize", () => {
            var client = new LanguageServer.Client (SERVER_PATH);
            var loop = new MainLoop ();

            client.server_closed.connect ((code) => {
                loop.quit ();
            });

            client.shutdown.begin ((o, res) => {
                try {
                    client.shutdown.end (res);
                } catch (Error e) {
                    client.exit ();
                    return;
                }

                assert_not_reached ();
            });

            loop.run ();
        });

        Test.add_func ("/vls/server/initialize_succeeds", () => {
            var client = new LanguageServer.Client (SERVER_PATH);
            var loop = new MainLoop ();

            client.server_closed.connect ((code) => {
                loop.quit ();
            });

            client.initialize.begin (new Variant ("a{sv}"), (o, res) => {
                try {
                    client.initialize.end (res);
                } catch (Error e) {
                    assert_not_reached ();
                } finally {
                    client.exit ();
                }
            });

            loop.run ();
        });

        Test.add_func ("/vls/server/initialize_has_capabilities", () => {
            var client = new LanguageServer.Client (SERVER_PATH);
            var loop = new MainLoop ();

            client.server_closed.connect ((code) => {
                loop.quit ();
            });

            client.initialize.begin (new Variant ("a{sv}"), (o, res) => {
                try {
                    var response = client.initialize.end (res);
                    var caps = response.get_object ().get_object_member ("capabilities");
                    assert (caps != null);
                } catch (Error e) {
                    assert_not_reached ();
                } finally {
                    client.exit ();
                }
            });

            loop.run ();
        });
    }
}
