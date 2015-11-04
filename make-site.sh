jekyll build
rsync _site/ ali@theraheemfamily.co.uk:~/public_html -r
git add .
git commit -m "$*"
git push mint master
git push origin master
