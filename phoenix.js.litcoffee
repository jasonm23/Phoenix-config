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
xcodebuild clean build
```

Now (re)place the Phoenix app into `/Applications/`

```bash
cd build/Release/
rm -rf /Applications/Phoenix.app
mv Phoenix.app /Applications/
```

Install this Phoenix config...

```bash
cd
git clone git@github.com:opsmanager/Phoenix-config
cd Phoenix-config
make

open -a Phoenix
```

You'll need to enable the security / accessibility settings (a pop up will
tell you this on first start.) Phoenix will then need to be run again.

```bash
open -a Phoenix
```

Now is a good time to activate **Open at Login** on the Phoenix OS X
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

... If you need a hint, install `node` and `npm` first.

## The Config proper begins here...

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

### Underscore extensions

    _.mixin
      flatmap: (list, iteratee, context) ->
        _.flatten _.map list, iteratee, context

### Helpers

    focused = -> Window.focusedWindow()
    windows = -> Window.visibleWindows()

    Window::screenRect = -> @screen().visibleFrameInRectangle()

    Window::fullGridFrame = -> @calculateGrid y: 0, x: 0, width: 1, height: 1

### Window Grid

Snap all windows to grid layout

    snapAllToGrid = ->
      _.map visible(), (win) -> win.snapToGrid()

Change grid width or height

    changeGridWidth = (n) ->
      GRID_WIDTH = Math.max 1, GRID_WIDTH + n
      Phoenix.notify "grid is #{GRID_WIDTH} tiles wide"
      snapAllToGrid()

    changeGridHeight = (n) ->
      GRID_HEIGHT = Math.max 1, GRID_HEIGHT + n
      Phoenix.notify "grid is #{GRID_HEIGHT} tiles high"
      snapAllToGrid()

Get the current grid as `{x:, y:, width:, height:}`

    Window::getGrid = ->
      frame = @frame()
      gridWidth = @screenRect().width / GRID_WIDTH
      gridHeight = @screenRect().height / GRID_HEIGHT

      y: Math.round (frame.y - @screenRect().y) / gridHeight
      x: Math.round (frame.x - @screenRect().x) / gridWidth
      width: Math.max 1, Math.round frame.width / gridWidth
      height: Math.max 1, Math.round frame.height / gridHeight

Set the current grid from an object `{x:, y:, width:, height:}`

    Window::setGrid = (grid, screen) ->
      gridWidth = @screenRect().width / GRID_WIDTH
      gridHeight = @screenRect().height / GRID_HEIGHT

      @setFrame
        y: ((grid.y * gridHeight) + @screenRect().y) + MARGIN_Y
        x: ((grid.x * gridWidth) + @screenRect().x) + MARGIN_X
        width: (grid.width * gridWidth) - (MARGIN_X * 2.0)
        height: (grid.height * gridHeight) - (MARGIN_Y * 2.0)

Snap the current window to the grid

    Window::snapToGrid = ->
      @setGrid @getGrid(), @screen() if @isNormal()

Calculate the grid based on the parameters, `x`, `y`, `width`, `height`, (returning an object `{x:,y:,width:,height:}`)

    Window::calculateGrid = ({x, y, width, height}) ->
      y:      Math.round(y * @screenRect().height) + MARGIN_Y + @screenRect().y
      x:      Math.round(x * @screenRect().width) + MARGIN_X + @screenRect().x
      width:  Math.round(width * @screenRect().width) - 2.0 * MARGIN_X
      height: Math.round(height * @screenRect().height) - 2.0 * MARGIN_Y

Window to grid

    Window::toGrid = ({x, y, width, height}) ->
      rect = @calculateGrid {x, y, width, height}
      @setFrame rect
      @

Window top right point

    Window::topRight = ->
      x: @frame().x + @frame().width
      y: @frame().y

Windows on the left

    Window::toLeft = ->
      _.filter @windowsToWest(), (win)->
        win.topLeft().x < @topLeft().x - 10

Windows on the right

    Window::toRight = ->
      _.filter @windowsToEast(), (win) ->
        win.topRight().x > @topRight().x + 10

### Window information

    Window::info = ->
      f = @frame()
      "[#{@app().processIdentifier()}] #{@app().name()} : #{@title()}\n{x:#{f.x}, y:#{f.y}, width:#{f.width}, height:#{f.height}}\n"

Sort any window collection by most recently with focus. We use
`info()` as a way of identifying the windows in place. Not too
performant, but with collections of this size, it's not a problem.

    Window.sortByMostRecent = (windows)->
      allVisible = visibleInOrder()
      _.sortBy windows, (win)->
        _.map(allVisible, (w)->
          w.info()).indexOf win.info()

### Window moving and sizing

Temporary storage for frames

    lastFrames = {}

Set a window to full screen

    Window::toFullScreen = ->
      unless _.isEqual @frame(), @fullGridFrame()
        @rememberFrame()
        @toGrid
          y: 0
          x: 0
          width: 1
          height: 1
      else if lastFrames[@uid()]
        @setFrame lastFrames[@uid()]
        @forgetFrame()

Remember and forget frames

    Window::uid           = -> "#{@app().name()}::#{@title()}"
    Window::rememberFrame = -> lastFrames[@uid()] = @frame()
    Window::forgetFrame   = -> delete lastFrames[@uid()]

Set a window to top / bottom / left / right

    Window::toTopHalf     = -> @toGrid x:0,   y:0,   width:1,    height:0.5
    Window::toBottomHalf  = -> @toGrid x:0,   y:0.5, width:1,    height:0.5
    Window::toLeftHalf    = -> @toGrid x:0,   y:0,   width:0.5,  height:1
    Window::toRightHalf   = -> @toGrid x:0.5, y:0,   width:0.5,  height:1

    Window::toTopRight    = -> @toGrid x:0.5, y:0,   width:0.5,  height:0.5
    Window::toBottomRight = -> @toGrid x:0.5, y:0.5, width:0.5,  height:0.5
    Window::toTopLeft     = -> @toGrid x:0,   y:0,   width:0.5,  height:0.5
    Window::toBottomLeft  = -> @toGrid x:0,   y:0.5, width:0.5,  height:0.5

Move the current window to the next / previous screen

    moveWindowToNextScreen = ->
      focused().setGrid focused().getGrid(), focused().screen().nextScreen()

    moveWindowToPreviousScreen = ->
      focused().setGrid focused().getGrid(), focused().screen().previousScreen()

Move the current window around the grid

    windowLeftOneColumn = ->
      frame = focused().getGrid()
      frame.x = Math.max(frame.x - 1, 0)
      focused().setGrid frame, focused().screen()

    windowDownOneRow = ->
      frame = focused().getGrid()
      frame.y = Math.min Math.floor(frame.y + 1), GRID_HEIGHT - 1
      focused().setGrid frame, focused().screen()

    windowUpOneRow = ->
      frame = focused().getGrid()
      frame.y = Math.max Math.floor(frame.y - 1), 0
      focused().setGrid frame, focused().screen()

    windowRightOneColumn = ->
      frame = focused().getGrid()
      frame.x = Math.min(frame.x + 1, GRID_WIDTH - frame.width)
      focused().setGrid frame, focused().screen()

Resize the current window on the grid

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
      frame.height = Math.min frame.height + 1, GRID_HEIGHT
      focused().setGrid frame, focused().screen()

    windowShrinkOneGridRow = ->
      frame = focused().getGrid()
      frame.height = Math.max frame.height - 1, 1
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

Find an app by it's `name` - this is problematic when the App window
has no title bar. Fair warning.

Find all apps with `name`

    App.allWithName = (name) ->
      _.filter App.runningApps(), (app) -> app.name() is name

    App.byName = (name) ->
      app = _.first App.allWithName name
      app.show()
      app

Focus or start an app with `name`

    App.focusOrStart = (name) ->
      apps = App.allWithName name
      if _.isEmpty apps
        Phoenix.notify "Starting #{name}"
        App.launch name
      else
        Phoenix.notify "Switching to #{name}"
      windows = _.flatmap apps, (x) -> x.windows()
      activeWindows = _.reject windows, (win) -> win.isMinimized()
      if _.isEmpty(activeWindows)
        App.launch name
      _.each activeWindows, (win) -> win.focus()

### Binding alias

Alias `Phoenix.bind` as `key_binding`, to make the binding table extra
readable.

    keys = []

The `key_binding` method includes the unused `description` parameter,
This is to allow future functionality ie. help mechanisms, describe bindings etc.

    key_binding = (key, description, modifier, fn)-> keys.push Phoenix.bind(key, modifier, fn)

## Bindings

Mash is <kbd>Cmd</kbd> + <kbd>Alt/Opt</kbd> + <kbd>Ctrl</kbd> pressed together.

    mash = 'cmd-alt-ctrl'.split '-'

Move the current window to the top / bottom / left / right half of the screen
and fill it.

    key_binding 'up',    'To Top Half',         mash, -> Window.focusedWindow().toTopHalf()
    key_binding 'down',  'To Bottom Half',      mash, -> Window.focusedWindow().toBottomHalf()
    key_binding 'left',  'To Left Half',        mash, -> Window.focusedWindow().toLeftHalf()
    key_binding 'right', 'To Right Half',       mash, -> Window.focusedWindow().toRightHalf()

Move to the corners of the screen

    key_binding 'Q', 'Top Left',                mash, -> Window.focusedWindow().toTopLeft()
    key_binding 'A', 'Bottom Left',             mash, -> Window.focusedWindow().toBottomLeft()
    key_binding 'W', 'Top Right',               mash, -> Window.focusedWindow().toTopRight()
    key_binding 'S', 'Bottom Right',            mash, -> Window.focusedWindow().toBottomRight()

Toggle maximize for the current window

    key_binding 'space', 'Maximize Window',     mash, -> Window.focusedWindow().toFullScreen()

## Application config

Replace these with apps that you want...

    ITERM    = "iTerm2"
    VIM      = "MacVim"
    EMACS    = "Emacs"
    TERMINAL = "iTerm2"
    FINDER   = "Finder"

We use an automator app to launch Chrome in remote-debugging-mode (on
port 9222). You may not like or want this

    CHROME   = "ChromeLauncher"

Switch to or lauch apps - fix these up to use whatever Apps you want on speed dial.

    key_binding 'E', 'Launch Emacs',            mash, -> App.focusOrStart EMACS
    key_binding 'V', 'Launch Vim',              mash, -> App.focusOrStart VIM
    key_binding 'T', 'Launch iTerm2',           mash, -> App.focusOrStart ITERM
    key_binding 'C', 'Launch Chrome',           mash, -> App.focusOrStart CHROME
    key_binding 'F', 'Launch Finder',           mash, -> App.focusOrStart FINDER

Move window between screens

    key_binding 'N', 'To Next Screen',          mash, -> moveWindowToNextScreen()
    key_binding 'P', 'To Previous Screen',      mash, -> moveWindowToPreviousScreen()

Setting the grid size

    key_binding '=', 'Increase Grid Columns',   mash, -> changeGridWidth +1
    key_binding '-', 'Reduce Grid Columns',     mash, -> changeGridWidth -1
    key_binding '[', 'Increase Grid Rows',      mash, -> changeGridHeight +1
    key_binding ']', 'Reduce Grid Rows',        mash, -> changeGridHeight -1

Snap current window or all windows to the grid

    key_binding ';', 'Snap focused to grid',    mash, -> Window.focusedWindow().snapToGrid()
    key_binding "'", 'Snap all to grid',        mash, -> visible().map (win)-> win.snapToGrid()

Move the current window around the grid

    key_binding 'H', 'Move Grid Left',          mash, -> windowLeftOneColumn()
    key_binding 'J', 'Move Grid Down',          mash, -> windowDownOneRow()
    key_binding 'K', 'Move Grid Up',            mash, -> windowUpOneRow()
    key_binding 'L', 'Move Grid Right',         mash, -> windowRightOneColumn()

Size the current window on the grid

    key_binding 'U', 'Window Full Height',      mash, -> windowToFullHeight()
    key_binding 'I', 'Shrink by One Column',    mash, -> windowShrinkOneGridColumn()
    key_binding 'O', 'Grow by One Column',      mash, -> windowGrowOneGridColumn()
    key_binding ',', 'Shrink by One Row',       mash, -> windowShrinkOneGridRow()
    key_binding '.', 'Grow by One Row',         mash, -> windowGrowOneGridRow()

All done...

    Phoenix.notify "Loaded"
