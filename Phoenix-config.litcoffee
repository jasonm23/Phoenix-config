# Phoenix.app config

## Prologue

This is a nice, fairly comprehensive, relatively self-documenting,
configuration for [Phoenix.app](https://github.com/jasonm23/Phoenix),
a lightweight scriptable OS X window manager.

## [Jump straight to the bindings](#bindings)

## Usage

Install Phoenix.app, and convert this file (`Phoenix-config.litcoffee`) to
plain JS, for use with Phoenix.app using:

```bash
coffee --bare --literate --compile Phoenix-config.litcoffee
mv Phoenix-config.js ~/.phoenix.js
```

That's if you want to type all that, and be in full awareness of what
is being done. Alternatively, run:

```bash
make
```

### Install CoffeeScript

If you don't have CoffeeScript installed, you'll need to install
node/npm (use [`brew`](http://brew.sh))

```shell
brew install node
npm install -g coffee-script
```

I assume you know what you're doing, if not, I wish you luck on your
diligent googling. (let's face it you got this far, you can get a
couple of command line tools installed, right?)

## Debugging helpers

    debug = (message)->
      api.alert message, 10

## Basic Settings

    MARGIN_X     = 3
    MARGIN_Y     = 3
    GRID_WIDTH   = 2
    GRID_HEIGHT  = 2

## Application config

    EDITOR       = "Emacs"
    BROWSER      = "Google Chrome"
    TERMINAL     = "iTerm"
    FINDER       = "Finder"
    MUSIC        = "iTunes"
    VIDEO        = "MPlayerX"

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

### Window Grid

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

    changeGridHeight = (by_) ->
      GRID_HEIGHT = Math.max(1, GRID_HEIGHT + by_)
      api.alert "grid is now " + GRID_HEIGHT + " tiles high", 1
      snapAllToGrid()
      return

Get the current grid as `{x:,y:,width:,height:}`

    Window::getGrid = ->
      winFrame = @frame()
      screenRect = @screen().frameWithoutDockOrMenu()
      thirdScreenWidth = screenRect.width / GRID_WIDTH
      halfScreenHeight = screenRect.height / GRID_HEIGHT
      x: Math.round((winFrame.x - screenRect.x) / thirdScreenWidth)
      y: Math.round((winFrame.y - screenRect.y) / halfScreenHeight)
      width: Math.max(1, Math.round(winFrame.width / thirdScreenWidth))
      height: Math.max(1, Math.round(winFrame.height / halfScreenHeight))

Set the current grid from an object `{x:,y:,width:,height:}`

    Window::setGrid = (grid, screen) ->
      screenRect = screen.frameWithoutDockOrMenu()
      thirdScreenWidth = screenRect.width / GRID_WIDTH
      halfScreenHeight = screenRect.height / GRID_HEIGHT
      newFrame =
        x: (grid.x * thirdScreenWidth) + screenRect.x
        y: (grid.y * halfScreenHeight) + screenRect.y
        width: grid.width * thirdScreenWidth
        height: grid.height * halfScreenHeight
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
      width: Math.round(width * screen.width) - 2.0 * MARGIN_X
      height: Math.round(height * screen.height) - 2.0 * MARGIN_Y

Window to grid

    Window::toGrid = (x, y, width, height) ->
      rect = @calculateGrid(x, y, width, height)
      @setFrame rect
      this

Window top right point

    Window::topRight = ->
      f = @frame()
      {
        x: f.x + f.width
        y: f.y
      }

Windows on the left

    Window::toLeft = ->
      p = @topLeft()
      _.chain(@windowsToWest())
      .filter (win)->
        win.topLeft().x < p.x - 10
      .value()

Windows on the right

    Window::toRight = ->
      p = @topRight()
      _.chain(@windowsToEast())
      .filter (win) ->
        win.topRight().x > p.x + 10
      .value()

### Window information

    Window::info = ->
      f = @frame()
      "[#{@app().pid}] #{@app().title()} : #{@title()}\n{x:#{f.x}, y:#{f.y}, width:#{f.width}, height:#{f.height}}\n"

Sort any window collection by most recently with focus. We use
`info()` as a way of identifying the windows in place. Not too
performant, but with collections of this size, it's not a problem.

    Window.sortByMostRecent = (windows)->
      allVisible = Window.visibleWindowsMostRecentFirst()
      _.chain(windows)
      .sortBy (win)->
        _.map(allVisible, (w)-> w.info()).indexOf(win.info())
      .value()

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

Remember and forget frames

    Window::rememberFrame = -> lastFrames[this] = @frame()
    Window::forgetFrame = -> delete lastFrames[this]

Set a window to top / bottom / left / right

    #                                      X     Y     Width  Height
    Window::toTopHalf      =  ->  @toGrid  0,    0,    1,     0.5
    Window::toBottomHalf   =  ->  @toGrid  0,    0.5,  1,     0.5
    Window::toLeftHalf     =  ->  @toGrid  0,    0,    0.5,   1
    Window::toRightHalf    =  ->  @toGrid  0.5,  0,    0.5,   1
    #                                      X     Y     Width  Height
    Window::toTopRight     =  ->  @toGrid  0.5,  0,    0.5,   0.5
    Window::toBottomRight  =  ->  @toGrid  0.5,  0.5,  0.5,   0.5
    Window::toTopLeft      =  ->  @toGrid  0,    0,    0.5,   0.5
    Window::toBottomLeft   =  ->  @toGrid  0,    0.5,  0.5,   0.5

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
      frame.x = Math.min(frame.x + 1, GRID_WIDTH - frame.width)
      win.setGrid frame, win.screen()

Grow and shrink the current window by a single grid cell

    windowGrowOneGridColumn = ->
      win = Window.focusedWindow()
      frame = win.getGrid()
      frame.width = Math.min(frame.width + 1, GRID_WIDTH - frame.x)
      win.setGrid frame, win.screen()

    windowShrinkOneGridColumn = ->
      win = Window.focusedWindow()
      frame = win.getGrid()
      frame.width = Math.max(frame.width - 1, 1)
      win.setGrid frame, win.screen()

    windowGrowOneGridRow = ->
      win = Window.focusedWindow()
      frame = win.getGrid()
      frame.height = Math.min(frame.height + 1, GRID_HEIGHT)
      win.setGrid frame, win.screen()

    windowShrinkOneGridRow = ->
      win = Window.focusedWindow()
      frame = win.getGrid()
      frame.height = Math.max(frame.height - 1, 1)
      win.setGrid frame, win.screen()

Shift the current window to the bottom or top row

    windowDownOneRow = ->
      win = Window.focusedWindow()
      frame = win.getGrid()
      frame.y = Math.min(Math.floor(frame.y + 1), GRID_HEIGHT - 1)
      win.setGrid frame, win.screen()

    windowUpOneRow = ->
      win = Window.focusedWindow()
      frame = win.getGrid()
      frame.y = Math.max(Math.floor(frame.y - 1), 0)
      win.setGrid frame, win.screen()

Expand the current window's height to vertically fill the screen

    windowToFullHeight = ->
      win = Window.focusedWindow()
      frame = win.getGrid()
      frame.y = 0
      frame.height = GRID_HEIGHT
      win.setGrid frame, win.screen()

### Transpose windows

This implementation is somewhat flawed, but this is by nature, due to
it's rather uncommon use.  If it were more frequently executed, I'm
sure it would be more fully formed, and sufficiently functional.
Perhaps, also, I should read less Ambrose Bierce.

    transposeWindows = (swapFrame = true, switchFocus = true)->
      win = Window.focusedWindow()
      left = win.toRight()
      right = win.toLeft()
      targets = if left.length > 0
        left
      else if right.length > 0
        right

      unless targets?.length > 0
        api.alert "Can't see any windows to transpose"
        return

      target = Window.sortByMostRecent(targets)[0]

      t_frame = target.frame()
      w_frame = win.frame()

      if swapFrame
        win.setFrame t_frame
        target.setFrame w_frame
      else
        target.topLeft x:w_frame.x, y:w_frame.y
        win.topLeft    x:t_frame.x, y:t_frame.y

      target.focusWindow() if switchFocus

### Applications

Select the first window for an app

    App::firstWindow = -> @visibleWindows()[0]

Find an app by it's `title` - this is problematic when the App window
has no title bar. Fair warning.

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

      windows = _.chain(apps)
      .map (x) ->
        x.allWindows()
      .flatten()
      .value()

      activeWindows = _(windows)
      .reject (win) ->
        win.isWindowMinimized()

      if _.isEmpty(activeWindows)
        api.launch title

      activeWindows.forEach (win) ->
        win.focusWindow()
        return
      return

Run the given function `fn` for an app with `title`

    forApp = (title, fn) ->
      app = App.byTitle(title)
      _.each app.visibleWindows(), fn  if app

### Manage layouts

Switch to a predefined layout [as above](#layout-config)

    switchLayout = (name)->
      _.each layouts[name], (config)->
        App.focusOrStart config.app
        app = App.byTitle config.app
        app.firstWindow()[config.whereTo]()

### Binding alias

Alias `api.bind` as `key_binding`, to make the binding table extra
readable.

    key_binding = (key, modifier, description, fn)->
      # Description is just to keep the key binding metadata in the
      # method call so we can easily build the keyboard guide without
      # additional metadata elsewhere.  It would also be helpful for
      # doing things like a describe-key command.
      api.bind key, modifier, fn

## Bindings

### Keyboard Guide

![][1]

Mash is <kbd>Cmd</kbd> + <kbd>Alt/Opt</kbd> + <kbd>Ctrl</kbd> pressed together.

    mash = 'cmd+alt+ctrl'.split '+'

Transpose/Swap Windows

    key_binding 'T', 'Transpose windows',                     mash, -> transposeWindows(true, false)
    key_binding 'Y', 'Transpose windows and swap focus',      mash, -> transposeWindows(true, true)

Move the current window to the top / bottom / left / right half of the screen
and fill it.

    key_binding 'up',    'Move window top half',              mash, -> Window.focusedWindow().toTopHalf()
    key_binding 'down',  'Move window bottom half',           mash, -> Window.focusedWindow().toBottomHalf()
    key_binding 'left',  'Move window left half',             mash, -> Window.focusedWindow().toLeftHalf()
    key_binding 'right', 'Move window right half',            mash, -> Window.focusedWindow().toRightHalf()

Move to the corners of the screen

    key_binding 'Q', 'Move window to top left corner',        mash, -> Window.focusedWindow().toTopLeft()
    key_binding 'A', 'Move window to bottom left corner',     mash, -> Window.focusedWindow().toBottomLeft()
    key_binding 'W', 'Move window to top right corner',       mash, -> Window.focusedWindow().toTopRight()
    key_binding 'S', 'Move window to bottom right corner',    mash, -> Window.focusedWindow().toBottomRight()

Focus to direction

    key_binding 'R', 'Shift focus to window above',           mash, -> Window.focusedWindow().focusWindowUp()
    key_binding 'D', 'Shift focus to window left',            mash, -> Window.focusedWindow().focusWindowLeft()
    key_binding 'F', 'Shift focus to window right',           mash, -> Window.focusedWindow().focusWindowRight()
    key_binding 'C', 'Shift focus to window below',           mash, -> Window.focusedWindow().focusWindowDown()

Maximize the current window

    key_binding 'space', 'Maximize (toggle revert size)',     mash, -> Window.focusedWindow().toFullScreen()

Switch to or lauch apps, as defined in the [Application config](#application-config)

    key_binding '0', 'Start/Switch to Editor',                mash, -> App.focusOrStart EDITOR
    key_binding '9', 'Start/Switch to Terminal',              mash, -> App.focusOrStart TERMINAL
    key_binding '8', 'Start/Switch to Browser',               mash, -> App.focusOrStart BROWSER
    key_binding '7', 'Start/Switch to Finder',                mash, -> App.focusOrStart FINDER

    # Entertainment apps...

    key_binding 'V', 'Start/Switch to Video Player',          mash, -> App.focusOrStart VIDEO
    key_binding 'B', 'Start/Switch to Music Player',          mash, -> App.focusOrStart MUSIC

Switch layouts using the predefined [Layout config](#layout-config)

    key_binding '5', 'Change to Editor and Browser layout',   mash, -> switchLayout 'Editor and Browser'
    key_binding '4', 'Change to Editor and Terminal layout',  mash, -> switchLayout 'Editor and Terminal'
    key_binding '3', 'Change to Terminal and Browser layout', mash, -> switchLayout 'Terminal and Browser'
    key_binding '2', 'Change to Finder and Terminal layout',  mash, -> switchLayout 'Finder and Terminal'
    key_binding '1', 'Change to Finder and Browser layout',   mash, -> switchLayout 'Finder and Browser'

Move window between screens

    key_binding 'N', 'Move window to the next screen',        mash, -> moveWindowToNextScreen()
    key_binding 'P', 'Move window to the previous screen',    mash, -> moveWindowToPreviousScreen()

Setting the grid size

    key_binding '=', 'Increase grid width',                   mash, -> changeGridWidth +1
    key_binding '-', 'Reduce grid width',                     mash, -> changeGridWidth -1
    key_binding '[', 'Increase grid height',                  mash, -> changeGridHeight +1
    key_binding ']', 'Reduce grid height',                    mash, -> changeGridHeight -1

Snap current window or all windows to the grid

    key_binding ';', 'Snap to grid',                          mash, -> Window.focusedWindow().snapToGrid()
    key_binding "'", 'Snap all to grid',                      mash, -> Window.visibleWindows().map (win)-> win.snapToGrid()

Move the current window around the grid

    key_binding 'H', 'Move window left',                      mash, -> moveWindowLeftOneColumn()
    key_binding 'J', 'Move window down',                      mash, -> windowDownOneRow()
    key_binding 'K', 'Move window up',                        mash, -> windowUpOneRow()
    key_binding 'L', 'Move window right',                     mash, -> moveWindowRightOneColumn()

Size the current window on the grid

    key_binding 'U', 'Size window to full height',            mash, -> windowToFullHeight()

    key_binding 'I', 'Resize window one grid column smaller', mash, -> windowShrinkOneGridColumn()
    key_binding 'O', 'Resize window one grid column larger',  mash, -> windowGrowOneGridColumn()
    key_binding ',', 'Resize window one grid row smaller',    mash, -> windowShrinkOneGridRow()
    key_binding '.', 'Resize window one grid row larger',     mash, -> windowGrowOneGridRow()

That's all folks.

### Quick reference, open the keyboard cheatsheet in a browser

**Mash + `**

    key_binding "`", 'Open quick reference guide',            mash, -> # mash backtick
      api.runCommand "/usr/bin/open", ["https://gist.githubusercontent.com/jasonm23/4990cc1e02a3c2a8e159/raw/phoenix.keyboard.png"]

Note: `api.runCommand` is undocumented in the API ref, I've included
the method signature in the API ref in this gist.

[1]:https://gist.githubusercontent.com/jasonm23/4990cc1e02a3c2a8e159/raw/phoenix.keyboard.png
