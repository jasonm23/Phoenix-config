install:
	rm -f ~/.phoenix.js
	rm -f ~/.phoenix.debug.js
	bin/mdlit READNE.md > phoenix.js
	cp -f phoenix.js ~/.phoenix.debug.js
	cp -f phoenix.js ~/.phoenix.js
