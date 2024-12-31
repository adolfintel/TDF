#include<QtDBus>
#include<unistd.h>

int main(int argc, char *argv[]){
    QDBusInterface interface(
        "org.freedesktop.Notifications",
        "/org/freedesktop/Notifications",
        "org.freedesktop.Notifications",
        QDBusConnection::sessionBus()
    );
    interface.call("Inhibit", "TDF", "", QVariantMap());
    while(1){
        sleep(1);
    }
    return 0;
}
