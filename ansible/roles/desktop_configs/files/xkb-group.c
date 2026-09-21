#include <X11/XKBlib.h>
#include <X11/Xlib.h>
#include <stdio.h>

int main(void) {
    Display *dpy = XOpenDisplay(NULL);
    if (!dpy) return 1;
    XkbStateRec state;
    XkbGetState(dpy, XkbUseCoreKbd, &state);
    printf("%d\n", state.group);
    XCloseDisplay(dpy);
    return 0;
}
