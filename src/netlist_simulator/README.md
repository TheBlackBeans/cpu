# Simulateur de netlist

## Utilisation

Pour compiler, utiliser `make`. Pour exécuter une série de tests, exécuter
`make check`.

Pour utiliser le simulateur, il faut appeler
`dune exec -- ./netlist_simulator.exe` suivi des options et du nom du netlist à
simuler.

Un petit résumé (sans description) de certaines options disponibles :

- `-h`/`--help` (affiche l'aide complète intégrée)
- `--no-random-init` / `--random-init` (défaut)
- `--no-color` / `--default-colors` (défaut)
- `--inputs filename`
- `--rom filename`
