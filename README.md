# Build
```
    cabal sandbox init
    cabal sandbox install --dependencies-only
    cabal build
```

# Create html post.
```
    cabal install pandoc
    pandoc -f latex+lhs -t html -s Main.lhs > kdabhsqml.html
```

# Create PDF
```
    pandoc -f latex+lhs -s Main.lhs -o kdabhsqml.pdf
```
