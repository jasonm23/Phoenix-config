/* JavaScript API documentation.

   (Yes, it's not written in JavaScript. But this pseudo-code conveys more information, so yeah.) */

class api

  static Hotkey bind(String key, Array<String> mods, Fn()->boolean callback);
                /* valid mods: "cmd", "alt", "ctrl", "shift"; case insensitive
                   valid keys: single case insensitive character.
                               OR, special keys (F-keys, numpad, etc) are listed here:
                               https://github.com/sdegutis/Phoenix/blob/master/Phoenix/PHHotKey.m#L75-L131 */

  static void reload(String path);
  static void launch(String appName);
  static void alert(String msg, double durationSeconds);
  static void runCommand(String comamndPath, Array args); // Uses NSTask to run commands
  static void setTint(Array red, Array green, Array blue);

end


class Window

  static Window focusedWindow();
  static Array<Window> allWindows();
  static Array<Window> visibleWindows();
  static Array<Window> visibleWindowsMostRecentFirst();

  Array<Window> otherWindowsOnSameScreen();
  Array<Window> otherWindowsOnAllScreens();

  /* Every screen (aka monitor or display) combines to form a giant rectangle. Every window lives in this
     rectangle. So this is why window positions and sizes don't have a "screen" parameter. It's already
     taken into account by the coordinates you give it. To figure out coordinates on a given screen, use
     the Screen methods. */

  Rect frame();
  Point topLeft();
  Size size();

  void setFrame(Rect frame);
  void setTopLeft(Point thePoint);
  void setSize(Size theSize);

  void maximize();
  void minimize();
  void unMinimize();

  Screen screen();
  App app();

  boolean isNormalWindow();
  boolean focusWindow();

  void focusWindowLeft();
  void focusWindowRight();
  void focusWindowUp();
  void focusWindowDown();

  Array<Window> windowsToWest();
  Array<Window> windowsToEast();
  Array<Window> windowsToNorth();
  Array<Window> windowsToSouth();

  String title();
  boolean isWindowMinimized();

end


class App

  static Array<App> runningApps();

  Array<Window> allWindows();
  Array<Window> visibleWindows();

  String title();
  boolean isHidden();
  void show();
  void hide();

  int pid();

  void kill();
  void kill9();

end


class Screen

  Rect frameIncludingDockAndMenu();
  Rect frameWithoutDockOrMenu();

  Screen nextScreen();
  Screen previousScreen();

end


class Hotkey

  boolean enable();
  void disable();

  String key();
  Array<String> mods();

end


class MousePosition
  static Point capture();
  static void  restore(Point mousePoint);
end


class Point
  property double x
  property double y
end


class Size
  property double width
  property double height
end


class Rect
  property double x
  property double y
  property double width
  property double height
end
