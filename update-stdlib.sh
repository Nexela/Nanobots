git clone https://github.com/Afforess/Factorio-Stdlib.git stdlib_repo
cd stdlib_repo && git checkout data-library && cd ..
rm -rf stdlib/
cp -r stdlib_repo/stdlib/ stdlib/
rm -rf stdlib_repo/
git add stdlib/
git commit -m 'STDLIB Update'
