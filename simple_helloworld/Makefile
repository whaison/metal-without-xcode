clangoptions:=-fobjc-arc -fmodules

run : hello-world
	./$<

hello-world : hello-world.m
	clang -o $@ $(clangoptions) -framework Foundation $<

clean : 
	$(RM) ./hello-world