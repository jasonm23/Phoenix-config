# Phoenix.app config

## Prologue

This is a nice, fairly comprehensive, relatively self-documenting,
configuration for [Phoenix.app](https://github.com/sdegutis/Phoenix),
a lightweight scriptable OS X window manager.

## [Jump straight to the bindings](#bindings)

## Usage

Install Phoenix.app, and convert this file (`.phoenix.litcoffee`) to
plain JS, for use with Phoenix.app using:

```shell
coffee --bare --literate --compile .phoenix.litcoffee
```

(Or use the `./compile` script included in this gist)

### Install CoffeeScript

If you don't have CoffeeScript installed, you'll need to [install
node/npm](https://github.com/joyent/node/wiki/installation) (or use
`brew install node --with-npm`) first, and then:

```shell
npm install -g coffee-script
```

## Basic Settings

    MARGIN_X    = 3
    MARGIN_Y    = 3
    GRID_WIDTH  = 3

## Application config

    EDITOR      = "Emacs"
    BROWSER     = "Google Chrome"
    TERMINAL    = "iTerm"
    MUSIC       = "iTunes"
    FINDER      = "Finder"

## Layout config

A few helpful app layouts. **note:** The last app in a layout array
will get focus.

    layouts =
      "Editor and Browser":
        0: app: BROWSER,  whereTo: "toRightHalf"
        1: app: EDITOR,   whereTo: "toLeftHalf"

      "Editor and Terminal":
        0: app: TERMINAL, whereTo: "toRightHalf"
        1: app: EDITOR,   whereTo: "toLeftHalf"

      "Terminal and Browser":
        0: app: TERMINAL, whereTo: "toLeftHalf"
        1: app: BROWSER,  whereTo: "toRightHalf"

      "Finder and Terminal":
        0: app: TERMINAL, whereTo: "toRightHalf"
        1: app: FINDER,   whereTo: "toLeftHalf"

      "Finder and Browser":
        0: app: BROWSER,  whereTo: "toRightHalf"
        1: app: FINDER,   whereTo: "toLeftHalf"

## Methods

### Grid

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

### Applications

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

### Window moving and sizing

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

## Transpose windows

**Work In Progress** : Transpose 2 horizontal windows, check the window to the left, or right, and
swap position. Left window takes presidence. Optionally exchange frame sizes.

Find window to the left...

- Store current window top/left point
- Collect/index top/left points of windows to "West".
- Check for x positions less than current window
- Get closest x position to current window
- Store found (or null)

None found? Find window to the right.

- Store current window top/right point
- Collect/index top/right points of windows to "East"
- Check for x positions greater than current window
- Check for nearest x position to current window
- Store found (or null)

Found? (or exit)

- Get frame of found
- Get frame of current
- Option to exchange sizes?
  - Yes: Exchange frames
  - No: Exchange origins

... TODO: Code this.

Remember and forget frames

    Window::rememberFrame = -> lastFrames[this] = @frame()
    Window::forgetFrame = -> delete lastFrames[this]

Set a window to top / bottom / left / right

    Window::toTopHalf = -> @toGrid 0, 0, 1, 0.5
    Window::toBottomHalf = -> @toGrid 0, 0.5, 1, 0.5
    Window::toLeftHalf = -> @toGrid 0, 0, 0.5, 1
    Window::toRightHalf = -> @toGrid 0.5, 0, 0.5, 1

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

### Manage layouts

Switch to a predefined layout [as above](#layout-config)

    switchLayout = (name)->
      _.each layouts[name], (config)->
        App.focusOrStart config.app
        app = App.byTitle config.app
        app.firstWindow()[config.whereTo]()

### Binding alias

Alias `api.bind` as `key_binding`,

    key_binding = (key, modifier, fn)->
      api.bind key, modifier, fn

## Bindings

Mash is **Cmd** + **Alt/Opt** + **Ctrl** pressed together.

    mash = 'cmd+alt+ctrl'.split '+'

Move the current window to the top / bottom / left / right half of the screen
and fill it.

    key_binding 'up',    mash, -> Window.focusedWindow().toTopHalf()
    key_binding 'down',  mash, -> Window.focusedWindow().toBottomHalf()
    key_binding 'left',  mash, -> Window.focusedWindow().toLeftHalf()
    key_binding 'right', mash, -> Window.focusedWindow().toRightHalf()

Maximize the current window

    key_binding 'M',     mash, -> Window.focusedWindow().toFullScreen()

Switch to or lauch apps, as defined in the [Application config](#application-config)

    key_binding '0',     mash, -> App.focusOrStart EDITOR
    key_binding '9',     mash, -> App.focusOrStart TERMINAL
    key_binding '8',     mash, -> App.focusOrStart BROWSER
    key_binding '7',     mash, -> App.focusOrStart MUSIC
    key_binding '6',     mash, -> App.focusOrStart FINDER

Switch layouts using the predefined [Layout config](#layout-config)

    key_binding '5',     mash, -> switchLayout 'Editor and Browser'
    key_binding '4',     mash, -> switchLayout 'Editor and Terminal'
    key_binding '3',     mash, -> switchLayout 'Terminal and Browser'
    key_binding '2',     mash, -> switchLayout 'Finder and Terminal'
    key_binding '1',     mash, -> switchLayout 'Finder and Browser'

Move window between screens

    key_binding 'N',     mash, -> moveWindowToNextScreen()
    key_binding 'P',     mash, -> moveWindowToPreviousScreen()

Setting the grid size

    key_binding '=',     mash, -> changeGridWidth +1
    key_binding '-',     mash, -> changeGridWidth -1

Snap current window or all windows to the grid

    key_binding ';',     mash, -> Window.focusedWindow().snapToGrid()
    key_binding "'",     mash, -> Window.visibleWindows().map (win)-> win.snapToGrid()

Move the current window around the grid

    key_binding 'H',     mash, -> moveWindowLeftOneColumn()
    key_binding 'K',     mash, -> windowToTopRow()
    key_binding 'J',     mash, -> windowToBottomRow()
    key_binding 'L',     mash, -> moveWindowRightOneColumn()

Size the current window on the grid

    key_binding 'U',     mash, -> windowToFullHeight()
    key_binding 'I',     mash, -> windowShrinkOneGridColumn()
    key_binding 'O',     mash, -> windowGrowOneGridColumn()

That's all folks.
