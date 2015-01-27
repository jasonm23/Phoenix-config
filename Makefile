BIN = /usr/local/bin

init:
	rm ~/.phoenix.js
	$(BIN)/coffee --bare --compile --literate -o ~/ Phoenix-config.litcoffee

