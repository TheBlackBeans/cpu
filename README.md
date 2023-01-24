Ce projet nécessite Verilog et Rust pour l'assembleur. Un flake Nix et un fichier
Makefile sont fournis. Pour compiler soi-même l'assembleur, il faut obtenir [`beans`](https://github.com/jthulhu/beans) et l'installer avec `make && sudo make install`.

La VM se compile avec `make out/vm-clock`. Le programme de l'horloge est
obtenable avec `make out/clock` ou `make out/clock-nostop`.

Pour régler l'horloge, le bouton `a` (appuyer sur `a` pendant que la VM tourne) permet de
multiplier par 2 le champ actuellement modifié, le bouton `z` multiplie par 2 et ajoute 1,
et appuyer sur `a` et `z` en même temps passe au champ suivant. Après cela, l'horloge fonctionne
normalement.