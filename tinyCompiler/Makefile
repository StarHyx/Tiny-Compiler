all: tinyCompiler

OBJS = grammar.o token.o  CodeGen.o  main.o ObjGen.o TypeSystem.o
LLVMCONFIG = /usr/local/Cellar/llvm@3.9/3.9.1_1/bin/llvm-config
CPPFLAGS = `$(LLVMCONFIG) --cppflags` -std=c++11 -m64
LDFLAGS = `$(LLVMCONFIG) --ldflags` -lpthread -ldl -lz -lncurses -rdynamic -L/usr/local/lib
LIBS = `$(LLVMCONFIG) --libs`

clean:
	$(RM) -rf grammar.cpp grammar.hpp test tinyCompiler token.cpp *.output output.o $(OBJS)

ObjGen.cpp: ObjGen.h

CodeGen.cpp: CodeGen.h ASTNodes.h

grammar.cpp: grammar.y
	bison -d -o $@ $<

grammar.hpp: grammar.cpp

token.cpp: token.l grammar.hpp
	flex -o $@ $<

%.o: %.cpp
	g++ -c $(CPPFLAGS) -o $@ $<

tinyCompiler: $(OBJS)
	g++ $(CPPFLAGS) -o $@ $(OBJS) $(LIBS) $(LDFLAGS)

test: tinyCompiler test.tc
	cat test.tc | ./tinyCompiler
	clang output.o -o test
	./test
