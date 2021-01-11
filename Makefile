lamb: lamb.hs
	ghc --make lamb.hs -O2 -optc-O3 -o lamb
zip:
	mkdir lambda
	cp Makefile lamb.hs README lama lamd lambda
	tar -czf lambda.tar.gz lambda
	rm -r lambda
clean:
	rm *.o *.hi lamb
