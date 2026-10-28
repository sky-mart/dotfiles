#include <X11/XKBlib.h>
#include <X11/Xlib.h>
#include <stdio.h>
#include <string.h>

int main(int argc, char **argv) {
    if (argc != 2) return 2;

    Display *dpy = XOpenDisplay(NULL);
    if (!dpy) {
        fprintf(stderr, "Cannot open X display\n");
        return 1;
    }
    XkbStateRec state;

    if (XkbGetState(dpy, XkbUseCoreKbd, &state) != Success) {
        fprintf(stderr, "Cannot query XKB group state\n");
        XCloseDisplay(dpy);
        return 1;
    }

    if (strcmp(argv[1], "watch") == 0) {
        int opcode, event_base, error_base;
        int major = XkbMajorVersion, minor = XkbMinorVersion;
        unsigned int events = XkbStateNotifyMask | XkbNamesNotifyMask | XkbNewKeyboardNotifyMask;
        if (!XkbQueryExtension(dpy, &opcode, &event_base, &error_base, &major, &minor) ||
            !XkbSelectEvents(dpy, XkbUseCoreKbd, events, events) ||
            !XkbSelectEventDetails(dpy, XkbUseCoreKbd, XkbStateNotify,
                                  XkbAllStateComponentsMask, XkbGroupStateMask) ||
            !XkbSelectEventDetails(dpy, XkbUseCoreKbd, XkbNamesNotify,
                                  XkbAllNamesMask, XkbGroupNamesMask)) {
            fprintf(stderr, "Cannot subscribe to XKB layout changes\n");
            XCloseDisplay(dpy);
            return 1;
        }
        XSync(dpy, False);
        for (;;) {
            if (puts("changed") == EOF || fflush(stdout) == EOF) {
                perror("Cannot write XKB layout change");
                XCloseDisplay(dpy);
                return 1;
            }
            XEvent event;
            do {
                XNextEvent(dpy, &event);
            } while (event.type != event_base);
        }
    }

    if (strcmp(argv[1], "next") == 0 || strcmp(argv[1], "first") == 0) {
        unsigned int group = strcmp(argv[1], "first") == 0 ? 0 : (state.group + 1) % 2;
        int result = XkbLockGroup(dpy, XkbUseCoreKbd, group);
        if (!result) fprintf(stderr, "Cannot select XKB group %u\n", group);
        XSync(dpy, False);
        XCloseDisplay(dpy);
        return result ? 0 : 1;
    }

    if (strcmp(argv[1], "name") == 0) {
        XkbDescPtr keyboard = XkbAllocKeyboard();
        if (!keyboard) {
            fprintf(stderr, "Cannot allocate XKB keyboard description\n");
            XCloseDisplay(dpy);
            return 1;
        }
        keyboard->device_spec = XkbUseCoreKbd;
        if (XkbGetNames(dpy, XkbGroupNamesMask, keyboard) != Success ||
            keyboard->names->groups[state.group] == None) {
            fprintf(stderr, "Cannot query active XKB group name\n");
            XkbFreeKeyboard(keyboard, XkbAllComponentsMask, True);
            XCloseDisplay(dpy);
            return 1;
        }
        char *name = XGetAtomName(dpy, keyboard->names->groups[state.group]);
        if (!name) {
            fprintf(stderr, "Cannot read active XKB group name\n");
            XkbFreeKeyboard(keyboard, XkbAllComponentsMask, True);
            XCloseDisplay(dpy);
            return 1;
        }
        printf("%s\n", name);
        XFree(name);
        XkbFreeKeyboard(keyboard, XkbAllComponentsMask, True);
        XCloseDisplay(dpy);
        return 0;
    }

    XCloseDisplay(dpy);
    return 2;
}
