(function() {
  // #!coffee -pl
  // # -*- mode: litcoffee -*-

  // # Phoenix.app config

  // ## Prologue

  // This is a nice, fairly comprehensive, relatively self-documenting,
  // configuration for [Phoenix 2.2](https://github.com/kasper/phoenix/tree/2.2.1),
  // a lightweight scriptable OS X window manager.

  // ## [Jump straight to the bindings](#bindings)

  // ## Usage

  // Download .app bundle direct from github https://github.com/kasper/phoenix/releases/tag/2.2.1

  // ### Build from source

  // Build Phoenix.app from [kasper/phoenix 2.2.1 branch](https://github.com/kasper/phoenix/tree/2.2.1)

  // You will need XCode command line tools installed.

  // ```bash
  // git clone https://github.com/kasper/phoenix
  // cd phoenix
  // git checkout 2.2.1
  // xcodebuild clean build
  // ```

  // Now (re)place the Phoenix app into `/Applications/`

  // ```bash
  // cd build/Release/
  // rm -rf /Applications/Phoenix.app
  // mv Phoenix.app /Applications/
  // ```

  // Install this Phoenix config...

  // ```bash
  // cd
  // git clone git@github.com:jasonm23/Phoenix-config
  // cd Phoenix-config
  // make

  // open -a Phoenix
  // ```

  // You'll need to enable the security / accessibility settings (a pop up will
  // tell you this on first start.) Phoenix will then need to be run again.

  // ```bash
  // open -a Phoenix
  // ```

  // Now is a good time to activate **Open at Login** on the Phoenix OS X
  // menu item, if you like.

  // ### Install CoffeeScript

  // If you don't have CoffeeScript installed, you'll need to install
  // node/npm (use [`brew`](http://brew.sh))

  // ```shell
  // brew install node
  // npm install -g coffee-script
  // ```

  // I assume you know what you're doing, if not, I wish you luck on your
  // diligent googling. (let's face it you got this far, you can get a
  // couple of command line tools installed, right?)

  // ... If you need a hint, install `node` and `npm` first.

  // ## The Config proper begins here...
  var CHROME, EMACS, FINDER, GRID_HEIGHT, GRID_WIDTH, ITERM, MARGIN_X, MARGIN_Y, TERMINAL, VIM, changeGridHeight, changeGridWidth, debug, focused, key_binding, keys, lastFrames, mash, moveWindowToNextScreen, moveWindowToPreviousScreen, snapAllToGrid, windowDownOneRow, windowGrowOneGridColumn, windowGrowOneGridRow, windowLeftOneColumn, windowRightOneColumn, windowShrinkOneGridColumn, windowShrinkOneGridRow, windowToFullHeight, windowUpOneRow, windows;

  Phoenix.notify("Phoenix config loading");

  // ## Debugging helpers
  debug = function(o, label = "obj: ") {
    Phoenix.log(`debug: ${label} =>`);
    return Phoenix.log(JSON.stringify(o));
  };

  // ## Basic Settings
  MARGIN_X = 3;

  MARGIN_Y = 3;

  GRID_WIDTH = 20;

  GRID_HEIGHT = 16;

  // ## Methods

  // ### Underscore extensions
  _.mixin({
    flatmap: function(list, iteratee, context) {
      return _.flatten(_.map(list, iteratee, context));
    }
  });

  // ### Helpers
  focused = function() {
    return Window.focused();
  };

  windows = function() {
    return Window.windows({
      visible: true
    });
  };

  Window.prototype.screenRect = function(screen) {
    return (screen != null ? screen.flippedVisibleFrame() : void 0) || this.screen().flippedVisibleFrame();
  };

  Window.prototype.fullGridFrame = function() {
    return this.calculateGrid({
      y: 0,
      x: 0,
      width: 1,
      height: 1
    });
  };

  // ### Window Grid

  // Snap all windows to grid layout
  snapAllToGrid = function() {
    return _.map(visible(), function(win) {
      return win.snapToGrid();
    });
  };

  // Change grid width or height
  changeGridWidth = function(n) {
    GRID_WIDTH = Math.max(1, GRID_WIDTH + n);
    Phoenix.notify(`grid is ${GRID_WIDTH} tiles wide`);
    return snapAllToGrid();
  };

  changeGridHeight = function(n) {
    GRID_HEIGHT = Math.max(1, GRID_HEIGHT + n);
    Phoenix.notify(`grid is ${GRID_HEIGHT} tiles high`);
    return snapAllToGrid();
  };

  // Get the current grid as `{x:, y:, width:, height:}`
  Window.prototype.getGrid = function() {
    var frame, gridHeight, gridWidth;
    frame = this.frame();
    gridWidth = this.screenRect().width / GRID_WIDTH;
    gridHeight = this.screenRect().height / GRID_HEIGHT;
    return {
      y: Math.round((frame.y - this.screenRect().y) / gridHeight),
      x: Math.round((frame.x - this.screenRect().x) / gridWidth),
      width: Math.max(1, Math.round(frame.width / gridWidth)),
      height: Math.max(1, Math.round(frame.height / gridHeight))
    };
  };

  // Set the current grid from an object `{x:, y:, width:, height:}`
  Window.prototype.setGrid = function(grid, screen) {
    var gridHeight, gridWidth;
    screen = screen || focused().screen();
    gridWidth = this.screenRect().width / GRID_WIDTH;
    gridHeight = this.screenRect().height / GRID_HEIGHT;
    return this.setFrame({
      y: ((grid.y * gridHeight) + this.screenRect(screen).y) + MARGIN_Y,
      x: ((grid.x * gridWidth) + this.screenRect(screen).x) + MARGIN_X,
      width: (grid.width * gridWidth) - (MARGIN_X * 2.0),
      height: (grid.height * gridHeight) - (MARGIN_Y * 2.0)
    });
  };

  // Snap the current window to the grid
  Window.prototype.snapToGrid = function() {
    if (this.isNormal()) {
      return this.setGrid(this.getGrid());
    }
  };

  // Calculate the grid based on the parameters, `x`, `y`, `width`, `height`, (returning an object `{x:,y:,width:,height:}`)
  Window.prototype.calculateGrid = function({x, y, width, height}) {
    return {
      y: Math.round(y * this.screenRect().height) + MARGIN_Y + this.screenRect().y,
      x: Math.round(x * this.screenRect().width) + MARGIN_X + this.screenRect().x,
      width: Math.round(width * this.screenRect().width) - 2.0 * MARGIN_X,
      height: Math.round(height * this.screenRect().height) - 2.0 * MARGIN_Y
    };
  };

  // Window left half width
  Window.prototype.proportionWidth = function() {
    var s_w, w_w;
    s_w = this.screenRect().width;
    w_w = this.frame().width;
    return Math.round((w_w / s_w) * 10) / 10;
  };

  // Window to grid
  Window.prototype.toGrid = function({x, y, width, height}) {
    var rect;
    rect = this.calculateGrid({x, y, width, height});
    return this.setFrame(rect);
  };

  // Window top right point
  Window.prototype.topRight = function() {
    return {
      x: this.frame().x + this.frame().width,
      y: this.frame().y
    };
  };

  // Windows on the left
  Window.prototype.toLeft = function() {
    return _.filter(this.neighbors('west'), function(win) {
      return win.topLeft().x < this.topLeft().x - 10;
    });
  };

  // Windows on the right
  Window.prototype.toRight = function() {
    return _.filter(this.neighbors('east'), function(win) {
      return win.topRight().x > this.topRight().x + 10;
    });
  };

  // ### Window information
  Window.prototype.info = function() {
    var f;
    f = this.frame();
    return `[${this.app().processIdentifier()}] ${this.app().name()} : ${this.title()}\n{x:${f.x}, y:${f.y}, width:${f.width}, height:${f.height}}\n`;
  };

  // ### Window moving and sizing

  // Temporary storage for frames
  lastFrames = {};

  // Set a window to full screen
  Window.prototype.toFullScreen = function() {
    if (!_.isEqual(this.frame(), this.fullGridFrame())) {
      this.rememberFrame();
      return this.toGrid({
        y: 0,
        x: 0,
        width: 1,
        height: 1
      });
    } else if (lastFrames[this.uid()]) {
      this.setFrame(lastFrames[this.uid()]);
      return this.forgetFrame();
    }
  };

  // Remember and forget frames
  Window.prototype.uid = function() {
    return `${this.app().name()}::${this.title()}`;
  };

  Window.prototype.rememberFrame = function() {
    return lastFrames[this.uid()] = this.frame();
  };

  Window.prototype.forgetFrame = function() {
    return delete lastFrames[this.uid()];
  };

  // Toggle window width
  Window.prototype.togglingWidth = function() {
    switch (this.proportionWidth()) {
      case 0.8:
        return 0.5;
      case 0.5:
        return 0.3;
      default:
        return 0.8;
    }
  };

  // Set a window to top / bottom / left / right
  Window.prototype.toTopHalf = function() {
    return this.toGrid({
      x: 0,
      y: 0,
      width: 1,
      height: 0.5
    });
  };

  Window.prototype.toBottomHalf = function() {
    return this.toGrid({
      x: 0,
      y: 0.5,
      width: 1,
      height: 0.5
    });
  };

  Window.prototype.toLeftHalf = function() {
    return this.toGrid({
      x: 0,
      y: 0,
      width: 0.5,
      height: 1
    });
  };

  Window.prototype.toRightHalf = function() {
    return this.toGrid({
      x: 0.5,
      y: 0,
      width: 0.5,
      height: 1
    });
  };

  Window.prototype.toLeftToggle = function() {
    return this.toGrid({
      x: 0,
      y: 0,
      width: this.togglingWidth(),
      height: 1
    });
  };

  Window.prototype.toRightToggle = function() {
    return this.toGrid({
      x: 1 - this.togglingWidth(),
      y: 0,
      width: this.togglingWidth(),
      height: 1
    });
  };

  Window.prototype.toTopRight = function() {
    return this.toGrid({
      x: 0.5,
      y: 0,
      width: 0.5,
      height: 0.5
    });
  };

  Window.prototype.toBottomRight = function() {
    return this.toGrid({
      x: 0.5,
      y: 0.5,
      width: 0.5,
      height: 0.5
    });
  };

  Window.prototype.toTopLeft = function() {
    return this.toGrid({
      x: 0,
      y: 0,
      width: 0.5,
      height: 0.5
    });
  };

  Window.prototype.toBottomLeft = function() {
    return this.toGrid({
      x: 0,
      y: 0.5,
      width: 0.5,
      height: 0.5
    });
  };

  // Move the current window to the next / previous screen
  moveWindowToNextScreen = function() {
    return focused().setGrid(focused().getGrid(), focused().screen().next());
  };

  moveWindowToPreviousScreen = function() {
    return focused().setGrid(focused().getGrid(), focused().screen().previous());
  };

  // Move the current window around the grid
  windowLeftOneColumn = function() {
    var frame;
    frame = focused().getGrid();
    frame.x = Math.max(frame.x - 1, 0);
    return focused().setGrid(frame);
  };

  windowDownOneRow = function() {
    var frame;
    frame = focused().getGrid();
    frame.y = Math.min(Math.floor(frame.y + 1), GRID_HEIGHT - 1);
    return focused().setGrid(frame);
  };

  windowUpOneRow = function() {
    var frame;
    frame = focused().getGrid();
    frame.y = Math.max(Math.floor(frame.y - 1), 0);
    return focused().setGrid(frame);
  };

  windowRightOneColumn = function() {
    var frame;
    frame = focused().getGrid();
    frame.x = Math.min(frame.x + 1, GRID_WIDTH - frame.width);
    return focused().setGrid(frame);
  };

  // Resize the current window on the grid
  windowGrowOneGridColumn = function() {
    var frame;
    frame = focused().getGrid();
    frame.width = Math.min(frame.width + 1, GRID_WIDTH - frame.x);
    return focused().setGrid(frame);
  };

  windowShrinkOneGridColumn = function() {
    var frame;
    frame = focused().getGrid();
    frame.width = Math.max(frame.width - 1, 1);
    return focused().setGrid(frame);
  };

  windowGrowOneGridRow = function() {
    var frame;
    frame = focused().getGrid();
    frame.height = Math.min(frame.height + 1, GRID_HEIGHT);
    return focused().setGrid(frame);
  };

  windowShrinkOneGridRow = function() {
    var frame;
    frame = focused().getGrid();
    frame.height = Math.max(frame.height - 1, 1);
    return focused().setGrid(frame);
  };

  // Expand the current window's height to vertically fill the screen
  windowToFullHeight = function() {
    var frame;
    frame = focused().getGrid();
    frame.y = 0;
    frame.height = GRID_HEIGHT;
    return focused().setGrid(frame);
  };

  // ### Applications

  // Select the first window for an app
  App.prototype.firstWindow = function() {
    return this.all({
      visible: true
    })[0];
  };

  // Find an app by it's `name` - this is problematic when the App window
  // has no title bar. Fair warning.

  // Find all apps with `name`
  App.allWithName = function(name) {
    return _.filter(App.all(), function(app) {
      return app.name() === name;
    });
  };

  App.byName = function(name) {
    var app;
    app = _.first(App.allWithName(name));
    app.show();
    return app;
  };

  // Focus or start an app with `name`
  App.focusOrStart = function(name) {
    var activeWindows, apps;
    apps = App.allWithName(name);
    if (_.isEmpty(apps)) {
      Phoenix.notify(`Starting ${name}`);
      App.launch(name);
    } else {
      Phoenix.notify(`Switching to ${name}`);
    }
    windows = _.flatmap(apps, function(x) {
      return x.windows();
    });
    activeWindows = _.reject(windows, function(win) {
      return win.isMinimized();
    });
    if (_.isEmpty(activeWindows)) {
      App.launch(name);
    }
    return _.each(activeWindows, function(win) {
      return win.focus();
    });
  };

  // ### Binding alias

  // Alias `Phoenix.bind` as `key_binding`, to make the binding table extra
  // readable.
  keys = [];

  // The `key_binding` method includes the unused `description` parameter,
  // This is to allow future functionality ie. help mechanisms, describe bindings etc.
  key_binding = function(key, description, modifier, fn) {
    return keys.push(Key.on(key, modifier, fn));
  };

  // ## Bindings

  // Mash is <kbd>Cmd</kbd> + <kbd>Alt/Opt</kbd> + <kbd>Ctrl</kbd> pressed together.
  mash = 'cmd-alt-ctrl'.split('-');

  // Move the current window to the top / bottom / left / right half of the screen
  // and fill it.
  key_binding('up', 'Top Half', mash, function() {
    return focused().toTopHalf();
  });

  key_binding('down', 'Bottom Half', mash, function() {
    return focused().toBottomHalf();
  });

  key_binding('left', 'Left side toggle', mash, function() {
    return focused().toLeftToggle();
  });

  key_binding('right', 'Right side toggle', mash, function() {
    return focused().toRightToggle();
  });

  // Move to the corners of the screen
  key_binding('Q', 'Top Left', mash, function() {
    return focused().toTopLeft();
  });

  key_binding('A', 'Bottom Left', mash, function() {
    return focused().toBottomLeft();
  });

  key_binding('W', 'Top Right', mash, function() {
    return focused().toTopRight();
  });

  key_binding('S', 'Bottom Right', mash, function() {
    return focused().toBottomRight();
  });

  // Toggle maximize for the current window
  key_binding('space', 'Maximize Window', mash, function() {
    return focused().toFullScreen();
  });

  // ## Application config

  // Replace these with apps that you want...
  ITERM = "iTerm2";

  VIM = "MacVim";

  EMACS = "Emacs";

  TERMINAL = "iTerm2";

  FINDER = "Finder";

  // We use an automator app to launch Chrome in remote-debugging-mode (on
  // port 9222). You may not like or want this
  CHROME = "ChromeLauncher";

  // Switch to or lauch apps - fix these up to use whatever Apps you want on speed dial.
  key_binding('E', 'Launch Emacs', mash, function() {
    return App.focusOrStart(EMACS);
  });

  key_binding('V', 'Launch Vim', mash, function() {
    return App.focusOrStart(VIM);
  });

  key_binding('T', 'Launch iTerm2', mash, function() {
    return App.focusOrStart(ITERM);
  });

  key_binding('C', 'Launch Chrome', mash, function() {
    return App.focusOrStart(CHROME);
  });

  key_binding('F', 'Launch Finder', mash, function() {
    return App.focusOrStart(FINDER);
  });

  // Move window between screens
  key_binding('N', 'To Next Screen', mash, function() {
    return moveWindowToNextScreen();
  });

  key_binding('P', 'To Previous Screen', mash, function() {
    return moveWindowToPreviousScreen();
  });

  // Setting the grid size
  key_binding('=', 'Increase Grid Columns', mash, function() {
    return changeGridWidth(+1);
  });

  key_binding('-', 'Reduce Grid Columns', mash, function() {
    return changeGridWidth(-1);
  });

  key_binding('[', 'Increase Grid Rows', mash, function() {
    return changeGridHeight(+1);
  });

  key_binding(']', 'Reduce Grid Rows', mash, function() {
    return changeGridHeight(-1);
  });

  // Snap current window or all windows to the grid
  key_binding(';', 'Snap focused to grid', mash, function() {
    return focused().snapToGrid();
  });

  key_binding("'", 'Snap all to grid', mash, function() {
    return visible().map(function(win) {
      return win.snapToGrid();
    });
  });

  // Move the current window around the grid
  key_binding('H', 'Move Grid Left', mash, function() {
    return windowLeftOneColumn();
  });

  key_binding('J', 'Move Grid Down', mash, function() {
    return windowDownOneRow();
  });

  key_binding('K', 'Move Grid Up', mash, function() {
    return windowUpOneRow();
  });

  key_binding('L', 'Move Grid Right', mash, function() {
    return windowRightOneColumn();
  });

  // Size the current window on the grid
  key_binding('U', 'Window Full Height', mash, function() {
    return windowToFullHeight();
  });

  key_binding('I', 'Shrink by One Column', mash, function() {
    return windowShrinkOneGridColumn();
  });

  key_binding('O', 'Grow by One Column', mash, function() {
    return windowGrowOneGridColumn();
  });

  key_binding(',', 'Shrink by One Row', mash, function() {
    return windowShrinkOneGridRow();
  });

  key_binding('.', 'Grow by One Row', mash, function() {
    return windowGrowOneGridRow();
  });

  // All done...
  Phoenix.notify("Loaded");

}).call(this);
