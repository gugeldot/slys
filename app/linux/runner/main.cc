#include <gdk/gdk.h>

#include "my_application.h"

int main(int argc, char** argv) {
  // Flutter's Wayland path paints the UI at the wrong scale on some desktops (seen on KDE Plasma
  // with scaled monitors: the window is full size but the content fills only a quarter of it).
  // Prefer X11/XWayland, which renders correctly everywhere; GDK_BACKEND=wayland still overrides.
  if (g_getenv("GDK_BACKEND") == nullptr) {
    gdk_set_allowed_backends("x11,wayland");
  }
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
