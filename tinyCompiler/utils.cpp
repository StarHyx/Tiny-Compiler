#include <iostream>
#include "CodeGen.h"
#include "ASTNodes.h"

using namespace std;

extern int yyparse();
extern NBlock* programBlock;