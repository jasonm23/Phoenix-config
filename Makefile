install:
	rm -f ~/.phoenix.js
	rm -f ~/.phoenix.debug.js
	bin/mdlit README.js.md > ~/.phoenix.js
	ln -s ~/.phoenix.js ~/.phoenix.debug.js
