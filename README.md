Smart building optimisation problems
=============

This is a collection of mathematical optimisation problems on smart buildings.

Citing
--------------
If you are using this project for a paper or other publication, please cite it as follows:

    @online{Picciau2016,
       Title    = {Smart building optimisation problems},
       Author   = {Andrea Picciau},
       Date     = {2016},
       Url      = {https://github.com/andpic/smart-building-optimisation},
       Note     = {GitHub repository},
    }

If available, also add the DOI number (digital object identifier) of the version used. 
Most of the mathematical formulation of the problems *single_household* and *block_of_flats* is
taken from:

    @article{Zhao2015,
       Title    = {Optimal home energy management system with mixed types of loads},
       Author   = {C. Zhao and S. Dong and F. Li and Y. Song},
       Journal  = {CSEE Journal of Power and Energy Systems},
       Year     = {2015},
       Volume   = {1},
       Number   = {4},
       Pages    = {29--37},
       Doi      = {10.17775/CSEEJPES.2015.00045},
       Month    = dec,
    }

please, cite this article if referring to the theoretical formulation and the online resource if
referring to the implementation.

Generating problems
--------------
To generate problems or change the parameters you need to do the following:

1. Each folder contains a script called `generate_data.sh` and a model file called
   `smart_building.zpl`. Give the same values to the parameters in the script and those in the model
   file (time step, horizon etc.).

2. Run the script (it is a bash script) with `./generate_data.sh`

3. Read the optimisation problem with either [the SCIP optimisation suite](http://scip.zib.de/) or
   [ZIMPL](http://zimpl.zib.de). The latter can be installed with *apt-get* on Ubuntu.

4. To create a problem that can be read on all optimisation solvers, either write it out in some
   standard format (with [the SCIP optimisation suite](http://scip.zib.de/)) or execute one of the
   following commands from the problem folder:
   * `zimpl -t mps smart_building.zpl`
   * `zimpl -t lp  smart_building.zpl`

License
--------------
The content of this project itself is licensed under the Creative Commons Attribution 4.0 license,
and the accompanying source code used is licensed under the MIT license.
