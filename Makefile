all:
	nim c -r ./src/donna_nim.nim

test:
	nim c -r ./tests/all.nim

clean:
	rm ./src/nimcache/*.*
	rm ./tests/nimcache/*.*
	