namespace project01

import System
import System.Collections.Generic

class Document:
	[Property(Path)] path as string
	
	def constructor(path as string):
		self.path = path
		
	def ExtractWords():		
		result = List[of string]()
		text = IO.File.ReadAllText(path)
		for word in /[\s,]/.Split(text):
			word = NormalizeWord(word)
			if word.Length > 0:
				result.Add(word)
		return result
	
	static def NormalizeWord(word as string):
		return word.Trim().ToUpper()

class Mapper[of T]:
"""Maps a set of objects of type T to an integer representation"""
	private mapping = Dictionary[of T, int]()
	private inverseMapping = List[of T]()
	
	def Map(val as T) as int:
		if not mapping.ContainsKey(val):
			mapping[val] = inverseMapping.Count
			inverseMapping.Add(val)
		return mapping[val]
	
	def Unmap(key as int):
		return inverseMapping[key]

class MarkovFSA[of NodeT]:
	private edges = Dictionary[of NodeT, List[of NodeT]]()
	private mapping = Mapper[of NodeT]()
	
	def AddEdge(source as NodeT, target as NodeT):
		if not edges.ContainsKey(source):
			edges[source] = List[of NodeT]()
		if not edges[source].Contains(target):
			edges[source].Add(target)

	def WriteToFile(path as string):
		writer = IO.StreamWriter(path)
		for node in edges.Keys:
			for target in edges[node]:
				writer.WriteLine("${node} ${target}")
		writer.Close()

static class ConsoleUtil:
	def Write(text as string, color as ConsoleColor):
		Console.ForegroundColor = color
		Console.Write(text)
		Console.ResetColor()

	def Write(text as string, color as ConsoleColor, backColor as ConsoleColor):
		Console.ForegroundColor = color
		Console.BackgroundColor = backColor
		Console.Write(text)
		Console.ResetColor()

openFstPath = "openfst/"

// Parse a document and create a FSA for the bigram language model
tokens = Mapper[of string]()
beginToken = tokens.Map("<s>")
endToken = tokens.Map("</s>")

documentName = "data/hamlet.txt"
Console.Write("Parsing document '${documentName}'... ")
doc = Document(documentName)
ConsoleUtil.Write("DONE\n", ConsoleColor.White, ConsoleColor.DarkGreen)

prevToken = beginToken

fsa = MarkovFSA[of int]()

for word as string in doc.ExtractWords():
	if word.EndsWith("."):
		token = tokens.Map(word.Substring(0, word.Length-1))
		fsa.AddEdge(prevToken, endToken)
		prevToken = beginToken
	else:
		token = tokens.Map(word)
	fsa.AddEdge(prevToken, token)
	prevToken = tokens.Map(word)
fsa.AddEdge(prevToken, endToken)

fsaInPath = "test.fst"
fsaOutPath = "binary.fst"
fsa.WriteToFile("test.fst")

Console.Write("Compiling FST... ")
psi = Diagnostics.ProcessStartInfo("${openFstPath}fstcompile", "--acceptor ${fsaInPath} ${fsaOutPath}")
psi.RedirectStandardError = true
psi.RedirectStandardOutput = true
psi.UseShellExecute = false
process = Diagnostics.Process.Start(psi)
process.WaitForExit()
if process.ExitCode != 0:
	ConsoleUtil.Write("FAIL\n", ConsoleColor.White, ConsoleColor.Red)
	ConsoleUtil.Write(process.StandardError.ReadToEnd() + "\n", ConsoleColor.Red)
	Environment.Exit(1)
ConsoleUtil.Write("DONE", ConsoleColor.White, ConsoleColor.DarkGreen)

Console.ReadKey()