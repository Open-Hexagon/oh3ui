#!/bin/bash

# recursive symlinks cause luadepgraph to descend endlessly
luadepgraph -m ohui/ui --dot | ./tools/adjmat > depmat.csv
