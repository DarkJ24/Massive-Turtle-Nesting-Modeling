# Massive Turtle Nesting Modeling

### Files:

* **Massive Turtle Nesting Modeling.pdf** - Article describing the experiment.
* **mediciones-full.csv** - Results for 32 runs with data for each tick.
* **mediciones.csv** - Results for 128 runs with data for the end of the simulation.
* **mediciones** - Folder containing the results for running 16 simulations on each lab PC.
* **Métodos de estimación de arribadas.odt** - A folder containing the explanation for each measuring method.
* **cuadrantes.csv** - A file containing the spots to monitor for the quadrants estimation method.
* **marea.csv** - A file containing tidal movement with height and time for each tide peak.
* **Proyecto Tortuga.nlogo** - The simulation file to run with Net logo.
* **terreno.csv** - A file containing the information of the terrain, with length and altitude for each sector.
* **transectos-berma.csv** - A file containing the spots to monitor for the berm transects estimation method.

### How to run?

The files needed to run are:

* **Proyecto Tortuga.nlogo** - The simulation file to run with Net logo.
* **terreno.csv** - A file containing the information of the terrain, with length and altitude for each sector. Each line indicates measurements for each sector, the first column indicates the length from the beach to the berm, the second column indicates the height at the berm, the third column indicates the length from the berm to the vegetation, and the last column indicates the height at the vegetation.
* **marea.csv** - A file containing tidal movement with height and time for each tide peak. The first row indicates the tidal movement height, usually used for maximums and minimums of tides height, and the second row indicates the time in minutes for each of those heights.
* **cuadrantes.csv** - A file containing the spots to monitor for the quadrants estimation method. Each row indicates a new quadrant to measure, the columns are x coordinate for the bottom left corner, y coordinate for the bottom left corner, x coordinate for the top right corner, and y coordinate for the top right corner.
* **transectos-berma.csv** - A file containing the spots to monitor for the berm transects estimation method. Each row indicates a new transect in berm to measure, the first column idicates the x coordinate for the transect, the second column indicates the y coordinate for the bottom of the transect and the third column indicates the y coordinate for the top of the transect.

When you specify correctly each of the previous files, you need to fill the data correctly in the sliders located in the Net Logo simulation file, the click prepare ("Preparar") to adjust correctly the simulation to be run, and finally click run ("Correr") to run the simulation.

The simulation will stop when all the tidal movements have finished.

### Cretors:

* José Quesada
* William Soto