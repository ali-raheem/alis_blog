jekyll build
git add .
git commit -m "$@"
git push mint master
git push origin master
rsync _site/ ali@theraheemfamily.co.uk:~/public_html -r