#include <iostream>
#include <fstream>
#include "ASTNodes.h"
#include "CodeGen.h"
#include "ObjGen.h"

using namespace std;

extern shared_ptr<NBlock> programBlock;
extern int yyparse();

int main(int argc, char **argv) {
    yyparse();

    programBlock->print("--");

    CodeGenContext context;

    context.generateCode(*programBlock);
    ObjGen(context);

    return 0;
}