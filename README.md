This repository contains a `Fortran90` code that replicates the steady state model in [*Gross Worker Flows over the Business Cycle*](https://www.aeaweb.org/articles?id=10.1257/aer.20121662) by Per Krusell, Toshihiko Mukoyama, Richard Rogerson, and Ayşegül Şahin. In my machine, this implementation of the model is around 40% *faster* than [the one available in the AER website](https://www.aeaweb.org/content/file?id=5684).

## How to compile
The code can be compiled by any Fortran compiler. Here is one way to do it using [gfortran](https://gcc.gnu.org/wiki/GFortran):
1. Navigate to the folder where the `.f90` files are located.
2. Create an executable file. There is a wide range of [flags](http://faculty.washington.edu/rjl/classes/am583s2013/notes/gfortran_flags.html) one can use with gfortran. Here are the two options I usually use:
  - Less optimised but helpful to find bugs: `gfortran -g -fcheck=all -fbacktrace -Wall -mcmodel=large Globals.f90 Utils.f90 Initialisation.f90 VFiteration.f90 Simulation.f90 Main.f90 -o main.out`
  - Optimised: `gfortran -mcmodel=large Globals.f90 Utils.f90 Initialisation.f90 VFiteration.f90 Simulation.f90 Main.f90 -O3 -o main.out`
3. Execute: `./main`

## Brief description of the code
The code is divided in four main parts:
1. **Initialisation**. Reads the parameters of the model from the outside world, creates global variables (such as asset grids, productivity discretisation, etc.) and model shocks.
2. **Find decision rules**. Uses value function iteration and the golden search method to find the policy functions associated to the Bellman equations described in the paper.
3. **Simulation**. Combines policy functions and shocks in a Monte Carlo simulation to compute aggregate variables and labour market statistics.
4. **Equilibrium**. Iterates over steps 2 and 3 in order to find equilibrium prices.

## Remarks
This code may contain bugs and errors. Pull requests and suggestions are more than welcome.
