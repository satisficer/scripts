#!/bin/sh
test $# -ne 0 && echo "usage: pipe text in, to get a latex pdf displayed" && exit 1

cd /tmp
t=`mktemp`
pandoc -s -f markdown -t latex > $t.tex
pdflatex $t.tex >/dev/null
mupdf -r 120 $t.pdf 2>/dev/null

rm ${t}*

