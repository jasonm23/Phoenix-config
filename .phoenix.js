#!coffee -pl
# -*- mode: litcoffee -*-

# Phoenix.app config

## Prologue

This is a nice, fairly comprehensive, relatively self-documenting,
configuration for [Phoenix 2](https://github.com/kasper/phoenix/tree/2.0),
a lightweight scriptable OS X window manager.

## [Jump straight to the bindings](#bindings)

## Usage

Build Phoenix.app from [kasper/phoenix 2.0 branch](https://github.com/kasper/phoenix/tree/2.0)

You will need XCode command line tools installed.

```bash
git clone https://github.com/kasper/phoenix
cd phoenix
git checkout 2.0
xcodebuild
open build/Release
```

Then Copy this file to `~/.phoenix.js`

Now drab and drop Phoenix into `/Applications/` and start it. You'll
need to enable the security / accessibility settings (a pop up will
tell you this on first start.)

Phoenix will need to be run again.

Also now is a good time to activate **Open at Login** on the Phoenix OS X
menu item, if you like.

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

## Config begins here

    Phoenix.notify "Phoenix config loading"

## Debugging helpers

    debug = (o, label="obj: ")->
      Phoenix.log label
      Phoenix.log JSON.stringify(o)

## Basic Settings

    MARGIN_X     = 3
    MARGIN_Y     = 3
    GRID_WIDTH   = 20
    GRID_HEIGHT  = 16

## Methods

### Helpers

    focused = -> Window.focusedWindow()
    windows = -> Window.visibleWindows()
    Window::screenRect = -> @screen().frameInRectangle()

### Window Grid

Snap all windows to grid layout

    snapAllToGrid = ->
      _.map visible(), (win) -> win.snapToGrid()

Change grid width or height by factor

    changeGridWidth = (factor) ->
      GRID_WIDTH = Math.max 1, GRID_WIDTH + factor
      Phoenix.notify "grid is now " + GRID_WIDTH + " tiles wide"
      snapAllToGrid()

    changeGridHeight = (factor) ->
      GRID_HEIGHT = Math.max 1, GRID_HEIGHT + factor
      Phoenix.notify "grid is now " + GRID_HEIGHT + " tiles high"
      snapAllToGrid()

Get the current grid as `{x:, y:, width:, height:}`

    Window::getGrid = ->
      frame = @frame()
      gridWidth = @screenRect().width / GRID_WIDTH
      gridHeight = @screenRect().height / GRID_HEIGHT

      x: Math.round (frame.x - @screenRect().x) / gridWidth
      y: Math.round (frame.y - @screenRect().y) / gridHeight
      width: Math.max 1, Math.round frame.width / gridWidth
      height: Math.max 1, Math.round frame.height / gridHeight

Set the current grid from an object `{x:, y:, width:, height:}`

    Window::setGrid = (grid, screen) ->
      gridWidth = @screenRect().width / GRID_WIDTH
      gridHeight = @screenRect().height / GRID_HEIGHT

      @setFrame
        x: ((grid.x * gridWidth) + @screenRect().x) + MARGIN_X
        y: ((grid.y * gridHeight) + @screenRect().y) + MARGIN_Y
        width: (grid.width * gridWidth) - (MARGIN_X * 2.0)
        height: (grid.height * gridHeight) - (MARGIN_Y * 2.0)

Snap the current window to the grid

    Window::snapToGrid = ->
      @setGrid @getGrid(), @screen() if @isNormal()

Calculate the grid based on the parameters, `x`, `y`, `width`, `height`, (returning an object `{x:,y:,width:,height:}`)

    Window::calculateGrid = (x, y, width, height) ->
      x: Math.round(x * @screenRect().width) + MARGIN_X + @screenRect().x
      y: Math.round(y * @screenRect().height) + MARGIN_Y + @screenRect().y
      width: Math.round(width * @screenRect().width) - 2.0 * MARGIN_X
      height: Math.round(height * @screenRect().height) - 2.0 * MARGIN_Y

Window to grid

    Window::toGrid = (x, y, width, height) ->
      rect = @calculateGrid x, y, width, height
      @setFrame rect
      @

Window top right point

    Window::topRight = ->
      x: @frame().x + @frame().width
      y: @frame().y

Windows on the left

    Window::toLeft = ->
      _.chain(@windowsToWest())
      .filter (win)-> win.topLeft().x < @topLeft().x - 10
      .value()

Windows on the right

    Window::toRight = ->
      _.chain(@windowsToEast())
      .filter (win) -> win.topRight().x > @topRight().x + 10
      .value()

### Window information

    Window::info = ->
      f = @frame()
      "[#{@app().processIdentifier()}] #{@app().name()} : #{@title()}\n{x:#{f.x}, y:#{f.y}, width:#{f.width}, height:#{f.height}}\n"

Sort any window collection by most recently with focus. We use
`info()` as a way of identifying the windows in place. Not too
performant, but with collections of this size, it's not a problem.

    Window.sortByMostRecent = (windows)->
      allVisible = visibleInOrder()
      _.chain(windows)
      .sortBy (win)-> _.map(allVisible, (w)-> w.info()).indexOf(win.info())
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

    #                                  X    Y    Width Height
    Window::toTopHalf     = -> @toGrid 0,   0,   1,    0.5
    Window::toBottomHalf  = -> @toGrid 0,   0.5, 1,    0.5
    Window::toLeftHalf    = -> @toGrid 0,   0,   0.5,  1
    Window::toRightHalf   = -> @toGrid 0.5, 0,   0.5,  1
    #                                  X    Y    Width Height
    Window::toTopRight    = -> @toGrid 0.5, 0,   0.5,  0.5
    Window::toBottomRight = -> @toGrid 0.5, 0.5, 0.5,  0.5
    Window::toTopLeft     = -> @toGrid 0,   0,   0.5,  0.5
    Window::toBottomLeft  = -> @toGrid 0,   0.5, 0.5,  0.5

Move the current window to the next / previous screen

    moveWindowToNextScreen = ->
      focused().setGrid focused().getGrid(), focused().screen().nextScreen()

    moveWindowToPreviousScreen = ->
      focused().setGrid focused().getGrid(), focused().screen().previousScreen()

Move the current window by one column

    moveWindowLeftOneColumn = ->
      frame = focused().getGrid()
      frame.x = Math.max(frame.x - 1, 0)
      focused().setGrid frame, focused().screen()

    moveWindowRightOneColumn = ->
      frame = focused().getGrid()
      frame.x = Math.min(frame.x + 1, GRID_WIDTH - frame.width)
      focused().setGrid frame, focused().screen()

Grow and shrink the current window by a single grid cell

    windowGrowOneGridColumn = ->
      frame = focused().getGrid()
      frame.width = Math.min(frame.width + 1, GRID_WIDTH - frame.x)
      focused().setGrid frame, focused().screen()

    windowShrinkOneGridColumn = ->
      frame = focused().getGrid()
      frame.width = Math.max(frame.width - 1, 1)
      focused().setGrid frame, focused().screen()

    windowGrowOneGridRow = ->
      frame = focused().getGrid()
      frame.height = Math.min(frame.height + 1, GRID_HEIGHT)
      focused().setGrid frame, focused().screen()

    windowShrinkOneGridRow = ->
      frame = focused().getGrid()
      frame.height = Math.max(frame.height - 1, 1)
      focused().setGrid frame, focused().screen()

Shift the current window to the bottom or top row

    windowDownOneRow = ->
      frame = focused().getGrid()
      frame.y = Math.min(Math.floor(frame.y + 1), GRID_HEIGHT - 1)
      focused().setGrid frame, focused().screen()

    windowUpOneRow = ->
      frame = focused().getGrid()
      frame.y = Math.max(Math.floor(frame.y - 1), 0)
      focused().setGrid frame, focused().screen()

Expand the current window's height to vertically fill the screen

    windowToFullHeight = ->
      frame = focused().getGrid()
      frame.y = 0
      frame.height = GRID_HEIGHT
      focused().setGrid frame, focused().screen()

### Applications

Select the first window for an app

    App::firstWindow = -> @visibleWindows()[0]

Find an app by it's `title` - this is problematic when the App window
has no title bar. Fair warning.

    App.byName = (name) ->
      app = _.first(App.allWithName(name))
      app.show()
      app

Find all apps with `title`

    App.allWithName = (name) ->
      _.filter App.runningApps(), (app) -> app.name() is name

Focus or start an app with `title`

    App.focusOrStart = (name) ->
      apps = App.allWithName(name)
      if _.isEmpty(apps)
        Phoenix.notify "Starting #{name}"
        App.launch name
      else
        Phoenix.notify "Switching to #{name}"

      windows = _.chain apps
      .map (x) -> x.windows()
      .flatten()
      .value()

      activeWindows = _(windows)
      .reject (win) ->
        win.isMinimized()

      if _.isEmpty(activeWindows)
        App.launch name

      activeWindows.forEach (win) ->
        win.focus()

Run the given function `fn` for an app with `name`

    forApp = (name, fn) ->
      app = App.byName(name)
      _.each app.visibleWindows(), fn if app

### Binding alias

Alias `Phoenix.bind` as `key_binding`, to make the binding table extra
readable.

    keys = []

    key_binding = (key, description, modifier, fn)->
      # Description is just to keep the key binding metadata in the
      # method call so we can easily build the keyboard guide without
      # additional metadata elsewhere.  It would also be helpful for
      # doing things like a describe-key command. Of course, this is
      # just speculative at the moment tbc...
      keys.push Phoenix.bind(key, modifier, fn)

## Bindings

Mash is <kbd>Cmd</kbd> + <kbd>Alt/Opt</kbd> + <kbd>Ctrl</kbd> pressed together.

    mash = 'cmd alt ctrl'.split ' '

Move the current window to the top / bottom / left / right half of the screen
and fill it.

    key_binding 'up',    'To Top Half',            mash, -> Window.focusedWindow().toTopHalf()
    key_binding 'down',  'To Bottom Half',         mash, -> Window.focusedWindow().toBottomHalf()
    key_binding 'left',  'To Left Half',           mash, -> Window.focusedWindow().toLeftHalf()
    key_binding 'right', 'To Right Half',          mash, -> Window.focusedWindow().toRightHalf()

Move to the corners of the screen

    key_binding 'Q', 'Top Left',                   mash, -> Window.focusedWindow().toTopLeft()
    key_binding 'A', 'Bottom Left',                mash, -> Window.focusedWindow().toBottomLeft()
    key_binding 'W', 'Top Right',                  mash, -> Window.focusedWindow().toTopRight()
    key_binding 'S', 'Bottom Right',               mash, -> Window.focusedWindow().toBottomRight()

Toggle maximize for the current window

    key_binding 'space', 'Maximize Window',        mash, -> Window.focusedWindow().toFullScreen()

## Application config

    ITERM    = "iTerm2"
    VIM      = "MacVim"
    EMACS    = "Emacs"
    TERMINAL = "iTerm2"
    CHROME   = "ChromeLauncher"
    FINDER   = "Finder"

Switch to or lauch apps

    key_binding 'E', 'Launch Emacs',               mash, -> App.focusOrStart EMACS
    key_binding 'V', 'Launch Vim',                 mash, -> App.focusOrStart VIM
    key_binding 'T', 'Launch iTerm2',              mash, -> App.focusOrStart ITERM
    key_binding 'C', 'Launch Chrome',              mash, -> App.focusOrStart CHROME
    key_binding 'F', 'Launch Finder',              mash, -> App.focusOrStart FINDER

Move window between screens

    key_binding 'N', 'To Next Screen',             mash, -> moveWindowToNextScreen()
    key_binding 'P', 'To Previous Screen',         mash, -> moveWindowToPreviousScreen()

Setting the grid size

    key_binding '=', 'Increase Grid Columns',      mash, -> changeGridWidth +1
    key_binding '-', 'Reduce Grid Columns',        mash, -> changeGridWidth -1
    key_binding '[', 'Increase Grid Rows',         mash, -> changeGridHeight +1
    key_binding ']', 'Reduce Grid Rows',           mash, -> changeGridHeight -1

Snap current window or all windows to the grid

    key_binding ';', 'Snap focused to grid',       mash, -> Window.focusedWindow().snapToGrid()
    key_binding "'", 'Snap all to grid',           mash, -> visible().map (win)-> win.snapToGrid()

Move the current window around the grid

    key_binding 'H', 'Move Grid Left',             mash, -> moveWindowLeftOneColumn()
    key_binding 'J', 'Move Grid Down',             mash, -> windowDownOneRow()
    key_binding 'K', 'Move Grid Up',               mash, -> windowUpOneRow()
    key_binding 'L', 'Move Grid Right',            mash, -> moveWindowRightOneColumn()

Size the current window on the grid

    key_binding 'U', 'Window Full Height',         mash, -> windowToFullHeight()
    key_binding 'I', 'Shrink by One Column',       mash, -> windowShrinkOneGridColumn()
    key_binding 'O', 'Grow by One Column',         mash, -> windowGrowOneGridColumn()
    key_binding ',', 'Shrink by One Row',          mash, -> windowShrinkOneGridRow()
    key_binding '.', 'Grow by One Row',            mash, -> windowGrowOneGridRow()

The end...

    Phoenix.notify "Loaded"
