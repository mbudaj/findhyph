TEX = \\documentclass{article}\\usepackage[T1]{fontenc}\\usepackage{textcomp}\\usepackage{a4wide}\\begin{document}\\input{fh.tex}\\end{document}

doc:
	pod2man -c "" ../findhyph > findhyph.1
	pod2text ../findhyph > findhyph.txt
	env echo $(TEX) > findhyph.tex
	pod2latex -out fh.tex ../findhyph
	pdflatex findhyph.tex
	pdflatex findhyph.tex
	rm fh.tex findhyph.aux findhyph.log findhyph.tex
