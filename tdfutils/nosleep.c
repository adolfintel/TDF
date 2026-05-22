#include <dbus/dbus.h>
#include <stdio.h>
#include <unistd.h>

int main(void) {
    DBusError err;
    dbus_error_init(&err);

    DBusConnection *bus = dbus_bus_get(DBUS_BUS_SESSION, &err);
    if (!bus) {
        return 1;
    }

    DBusMessage *msg = dbus_message_new_method_call(
        "org.freedesktop.ScreenSaver",
        "/org/freedesktop/ScreenSaver",
        "org.freedesktop.ScreenSaver",
        "Inhibit");

    DBusMessageIter iter;
    dbus_message_iter_init_append(msg, &iter);

    const char *app = "TDF";
    const char *why = "Wine";
    dbus_message_iter_append_basic(&iter, DBUS_TYPE_STRING, &app);
    dbus_message_iter_append_basic(&iter, DBUS_TYPE_STRING, &why);

    dbus_connection_send_with_reply_and_block(bus, msg, -1, &err);
    dbus_message_unref(msg);

    if (err.message) {
        return 2;
    }

    while (1) {
        sleep(1);
    }
}
