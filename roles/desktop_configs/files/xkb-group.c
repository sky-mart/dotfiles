#include <X11/XKBlib.h>
#include <X11/Xlib.h>
#include <stdio.h>
#include <string.h>

int main(int argc, char **argv) {
    Display *dpy = XOpenDisplay(NULL);
    if (!dpy) return 1;
    XkbStateRec state;

    if (XkbGetState(dpy, XkbUseCoreKbd, &state) != Success) {
        XCloseDisplay(dpy);
        return 1;
    }

    if (argc == 2 && strcmp(argv[1], "next") == 0) {
        int result = XkbLockGroup(dpy, XkbUseCoreKbd, (state.group + 1) % 2);
        XSync(dpy, False);
        XCloseDisplay(dpy);
        return result ? 0 : 1;
    }

    if (argc != 1) {
        XCloseDisplay(dpy);
        return 2;
    }

    printf("%d\n", state.group);
    XCloseDisplay(dpy);
    return 0;
}
