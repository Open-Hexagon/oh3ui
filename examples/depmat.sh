#!/bin/bash

luadepgraph -m ui --dot | ./tools/adjmat > depmat.csv