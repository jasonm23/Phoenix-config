# Phoenix.app config

## Prologue

This is a nice, fairly comprehensive, relatively self-documenting,
configuration for [Phoenix.app](https://github.com/sdegutis/Phoenix),
a lightweight scriptable OS X window manager.

## Usage

Install Phoenix.app, and convert this file (`.phoenix.litcoffee`) to
plain JS, for use with Phoenix.app using:

`coffee --bare --literate --compile .phoenix.litcoffee`

## Basic Settings

    MARGIN_X    = 5
    MARGIN_Y    = 5
    GRID_WIDTH  = 3

## Application config

    EDITOR      = "Emacs"
    BROWSER     = "Google Chrome"
    TERMINAL    = "iTerm"
    MUSIC       = "iTunes"

## Layout config

Helpful layouts, the last app in a layout will get focus
by these defaults, the `EDITOR` gets preference.

    layouts =
      editorAndBrowser:
        [
          {
            app: BROWSER
            whereTo: "toRightHalf"
          }
          {
            app: EDITOR
            whereTo: "toLeftHalf"
          }
        ]

      editorAndTerminal:
        [
          {
            app: TERMINAL
            whereTo: "toRightHalf"
          }
          {
            app: EDITOR
            whereTo: "toLeftHalf"
          }
        ]

Snap all windows to grid layout

    snapAllToGrid = ->
      Window.visibleWindows().map (win) ->
        win.snapToGrid()
        return
      return

Change grid by a width factor

    changeGridWidth = (by_) ->
      GRID_WIDTH = Math.max(1, GRID_WIDTH + by_)
      api.alert "grid is now " + GRID_WIDTH + " tiles wide", 1
      snapAllToGrid()
      return

Get the current grid as `{x:,y:,w:,h:}`

    Window::getGrid = ->
      winFrame = @frame()
      screenRect = @screen().frameWithoutDockOrMenu()
      thirdScreenWidth = screenRect.width / GRID_WIDTH
      halfScreenHeight = screenRect.height / 2
      x: Math.round((winFrame.x - screenRect.x) / thirdScreenWidth)
      y: Math.round((winFrame.y - screenRect.y) / halfScreenHeight)
      w: Math.max(1, Math.round(winFrame.width / thirdScreenWidth))
      h: Math.max(1, Math.round(winFrame.height / halfScreenHeight))

Set the current grid from an object `{x:,y:,w:,h:}`

    Window::setGrid = (grid, screen) ->
      screenRect = screen.frameWithoutDockOrMenu()
      thirdScreenWidth = screenRect.width / GRID_WIDTH
      halfScreenHeight = screenRect.height / 2
      newFrame =
        x: (grid.x * thirdScreenWidth) + screenRect.x
        y: (grid.y * halfScreenHeight) + screenRect.y
        width: grid.w * thirdScreenWidth
        height: grid.h * halfScreenHeight
      newFrame.x += MARGIN_X
      newFrame.y += MARGIN_Y
      newFrame.width -= (MARGIN_X * 2.0)
      newFrame.height -= (MARGIN_Y * 2.0)
      @setFrame newFrame

Snap the current window to the grid

    Window::snapToGrid = ->
      @setGrid @getGrid(), @screen()  if @isNormalWindow()


Calculate the grid based on the parameters, `x`, `y`, `width`, `height`, (returning an object `{x:,y:,width:,height:}`)

**TODO**: normalize parameters and object keys to `x,y,w,h`

    Window::calculateGrid = (x, y, width, height) ->
      screen = @screen().frameWithoutDockOrMenu()
      x: Math.round(x * screen.width) + MARGIN_X + screen.x
      y: Math.round(y * screen.height) + MARGIN_Y + screen.y
      width: Math.round(width * screen.width) - 2 * MARGIN_X
      height: Math.round(height * screen.height) - 2 * MARGIN_Y

Window to grid

    Window::toGrid = (x, y, width, height) ->
      rect = @calculateGrid(x, y, width, height)
      @setFrame rect
      this

Temporary storage for frames

    lastFrames = {}

Set a window to full screen

    Window::toFullScreen = ->
      fullFrame = @calculateGrid(0, 0, 1, 1)
      unless _.isEqual(@frame(), fullFrame)
        @rememberFrame()
        @toGrid 0, 0, 1, 1
      else if lastFrames[this]
        @setFrame lastFrames[this]
        @forgetFrame()


Remember and forget frames

    Window::rememberFrame = -> lastFrames[this] = @frame()
    Window::forgetFrame = -> delete lastFrames[this]

Set a window to top / bottom / left / right

    Window::toTopHalf = -> @toGrid 0, 0, 1, 0.5
    Window::toBottomHalf = -> @toGrid 0, 0.5, 1, 0.5
    Window::toLeftHalf = -> @toGrid 0, 0, 0.5, 1
    Window::toRightHalf = -> @toGrid 0.5, 0, 0.5, 1

Select the first window for an app

    App::firstWindow = -> @visibleWindows()[0]

Find an app by it's `title`

    App.byTitle = (title) ->
      apps = @runningApps()
      i = 0
      while i < apps.length
        app = apps[i]
        if app.title() is title
          app.show()
          return app
        i++
      return

Find all apps with `title`

    App.allWithTitle = (title) ->
      _(@runningApps()).filter (app) ->
        true  if app.title() is title

Focus or start an app with `title`

    App.focusOrStart = (title) ->
      apps = App.allWithTitle(title)
      if _.isEmpty(apps)
        api.alert "Attempting to start #{title}"
        api.launch title
        return
      windows = _.chain(apps).map((x) ->
        x.allWindows()
      ).flatten().value()
      activeWindows = _(windows).reject((win) ->
        win.isWindowMinimized()
      )
      if _.isEmpty(activeWindows)
        api.alert "All windows minimized for " + title
        return
      activeWindows.forEach (win) ->
        win.focusWindow()
        return
      return

Run the given function `f` for an app with `title`

    forApp = (title, f) ->
      app = App.byTitle(title)
      _.each app.visibleWindows(), f  if app

Move the current window to the next / previous screen

    moveWindowToNextScreen = ->
      win = Window.focusedWindow()
      win.setGrid win.getGrid(), win.screen().nextScreen()

    moveWindowToPreviousScreen = ->
      win = Window.focusedWindow()
      win.setGrid win.getGrid(), win.screen().previousScreen()

Move the current window by one column

    moveWindowLeftOneColumn = ->
      win = Window.focusedWindow()
      frame = win.getGrid()
      frame.x = Math.max(frame.x - 1, 0)
      win.setGrid frame, win.screen()

    moveWindowRightOneColumn = ->
      win = Window.focusedWindow()
      frame = win.getGrid()
      frame.x = Math.min(frame.x + 1, GRID_WIDTH - frame.w)
      win.setGrid frame, win.screen()

Grow and shrink the current window by a single grid column

    windowGrowOneGridColumn = ->
      win = Window.focusedWindow()
      frame = win.getGrid()
      frame.w = Math.min(frame.w + 1, GRID_WIDTH - frame.x)
      win.setGrid frame, win.screen()

    windowShrinkOneGridColumn = ->
      win = Window.focusedWindow()
      frame = win.getGrid()
      frame.w = Math.max(frame.w - 1, 1)
      win.setGrid frame, win.screen()

Shift the current window to the bottom or top row

    windowToBottomRow = ->
      win = Window.focusedWindow()
      frame = win.getGrid()
      frame.y = 1
      frame.h = 1
      win.setGrid frame, win.screen()

    windowToTopRow = ->
      win = Window.focusedWindow()
      frame = win.getGrid()
      frame.y = 0
      frame.h = 1
      win.setGrid frame, win.screen()

Expand the current window's height to vertically fill the screen

    windowToFullHeight = ->
      win = Window.focusedWindow()
      frame = win.getGrid()
      frame.y = 0
      frame.h = 2
      win.setGrid frame, win.screen()

Switch to a predefined layout [as above](#layout-config)

    setupLayout = (name)->
      _.each layouts[name], (config)->
        App.focusOrStart config.app
        app = App.byTitle config.app
        app.firstWindow()[config.whereTo]()

## Bindings

Mash is <kbd>Cmd + Alt/Opt + Ctrl</kbd> pressed together.

    mash = [
      "cmd"
      "alt"
      "ctrl"
    ]

Move the current window to the top / bottom / left / right half of the screen
and fill it.

    api.bind "up",    mash, -> Window.focusedWindow().toTopHalf()
    api.bind "down",  mash, -> Window.focusedWindow().toBottomHalf()
    api.bind "left",  mash, -> Window.focusedWindow().toLeftHalf()
    api.bind "right", mash, -> Window.focusedWindow().toRightHalf()

Maximize the current window

    api.bind "M",     mash, -> Window.focusedWindow().toFullScreen()


Switch to or lauch apps, as defined in the [Application config](#application-config)

    api.bind "0",     mash, -> App.focusOrStart EDITOR
    api.bind "9",     mash, -> App.focusOrStart TERMINAL
    api.bind "8",     mash, -> App.focusOrStart BROWSER
    api.bind "7",     mash, -> App.focusOrStart MUSIC

Switch layouts using the predefined [Layout config](#layout-config)

    api.bind "5",     mash, -> setupLayout "editorAndBrowser"
    api.bind "4",     mash, -> setupLayout "editorAndTerminal"

Move window between screens

    api.bind "N",     mash, -> moveWindowToNextScreen()
    api.bind "P",     mash, -> moveWindowToPreviousScreen()

Setting the grid size

    api.bind "=",     mash, -> changeGridWidth +1
    api.bind "-",     mash, -> changeGridWidth -1

Snap current window or all windows to the grid

    api.bind ";",     mash, -> Window.focusedWindow().snapToGrid()
    api.bind "'",     mash, -> Window.visibleWindows().map (win)-> win.snapToGrid()

Move the current window around the grid

    api.bind "H",     mash, -> moveWindowLeftOneColumn()
    api.bind "K",     mash, -> windowToTopRow()
    api.bind "J",     mash, -> windowToBottomRow()
    api.bind "L",     mash, -> moveWindowRightOneColumn()

Size the current window on the grid

    api.bind "U",     mash, -> windowToFullHeight()
    api.bind "I",     mash, -> windowShrinkOneGridColumn()
    api.bind "O",     mash, -> windowGrowOneGridColumn()

That's all folks.
