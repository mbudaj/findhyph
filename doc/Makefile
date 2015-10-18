TEX = '\documentclass{article}\usepackage[a4paper, margin=3cm]{geometry}\usepackage{fontspec}\catcode`\ε=\active\defε{$$\varepsilon$$}\begin{document}\input{fh.tex}\end{document}'

doc:
	pod2man --utf8 -c "" ../findhyph > findhyph.1
	pod2text ../findhyph > findhyph.txt
	env echo $(TEX) > findhyph.tex
	pod2latex -out fh.tex ../findhyph
	sed -i 's/TeX/\\TeX{}/g' fh.tex
	xelatex findhyph.tex
	xelatex findhyph.tex
	rm fh.tex findhyph.aux findhyph.log findhyph.tex
