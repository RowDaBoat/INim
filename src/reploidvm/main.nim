import compiler
import state

let nimCompiler = createCompiler("nim")
var stateLoader = createStateLoader(nimCompiler)

stateLoader.addVariable(VariableDeclaration(declarer: "var", name: "x", typ: "int"))
discard stateLoader.updateState()
#stateLoader.addVariable(VariableDeclaration(declarer: "var", name: "value2", typ: "float32"))
#echo stateLoader.updateState()
#stateLoader.addVariable(VariableDeclaration(declarer: "var", name: "value3", typ: "string"))
#echo stateLoader.updateState()

for i in 0 ..< 2:
  stateLoader.runCommand("""
x += 1
echo "Counting x:", x
"""
  )

stateLoader.addVariable(VariableDeclaration(declarer: "var", name: "y", typ: "int"))
discard stateLoader.updateState()

for i in 0 ..< 8:
  stateLoader.runCommand("""
x += 1
y += 1
echo "Counting x: ", x
echo "Counting y: ", y
"""
    )
