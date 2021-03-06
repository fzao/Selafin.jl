# Selafin.jl

Selafin.jl is a package written in the Julia language for the extraction, statistical analysis and interactive visualization of results from the [Telemac](www.opentelemac.org) system. It reads files in Selafin (also called Serafin) format with extensions .slf, .sel, .srf...

The package uses the [GLMakie](https://makie.juliaplots.org/stable/) package as a GPU-powered viewer in 2D and 3D.

This document is divided into three parts:
- description of the list of functions available to the user;
- methodological considerations;
- use cases.

# List of functions

The functions described below are user functions. They can be used in any order with the exception of the user's Selafin result file reading function, which must be called first. This is because this function is responsible for initializing a data structure that must then be passed on to all other functions in subsequent calls.

## Reading files

There is only one function for reading the Telemac result file in Selafin format. This function must be called first, before any other use, because it is an initialization of a basic data structure which will then be used by all other functions.

```julia
Selafin.Read(filename)
```

This function uses only one string variable, giving the path to the user's Selafin file. Some basic information will be displayed before returning a data structure containing all the necessary information about the Telemac case for further function calls.

```julia
# Example of use
data = Selafin.Read("t2d_mersey.slf")
```
```
✓ File data/t2d_mersey.slf of size: 1 MB
✓ Name of the simulation: MERSEY ESTUARY                                                          SERAPHIN
✓ Event start date and time: Unknown
✓ Telemac 2D results with 4 variables
✓ Variables are:
        1  - velocity u      m/s
        2  - velocity v      m/s
        3  - water depth     m
        4  - bottom          m
✓ Unstructured mesh with 4,490 triangles and 2,429 nodes
✓ Number of time steps: 25 with Δt = 1800.0 s
```

## Mesh analysis

This analysis is simple and consists in finding and displaying all the triangles of the mesh that are below a form factor threshold. By default, the threshold value is 0.5 but can be changed when calling the following function:

```julia
meshqual = Selafin.Quality(data, true, "mesh_mersey.png", 0.6)
```

The first parameter is the previously read data structure. The second logical flag parameter stands for displaying the mesh quality results (default: `false`). The third paramter is a string variable indicating whether if the plot should be saved on drive as .png file (default: `nothing`). The last parameter is the threshold value between 0 and 1 for the mesh quality measurement (default: 0.5). All triangles with a form factor above this value will be highlighted in red color when viewing the mesh.

```
✓ Mesh quality (Min: 0.05, Mean: 0.98, Max: 1.0)
        ▪ Triangles
        0.0...0.1: 4
        0.1...0.2: 0
        0.2...0.3: 5
        0.3...0.4: 18
        0.4...0.5: 12
        0.5...0.6: 10
        0.6...0.7: 19
        0.7...0.8: 10
        0.8...0.9: 57
        0.9...1.0: 4355
✓ Study area surface: 136.68 km² and perimeter: 138.3 km
✓ Succeeded!         
```

The return value `meshqual` is an array for the histogram of triangle qualities.

## Plotting results

### 2D

This is the main function for interactively plotting all the results of the Telemac variables on the mesh and according to the time step.

```julia
Selafin.Plot2D(data)
```

It is also possible to save the current visualization (according to the name of the variable, the time step and the layer number) on an image file in .png format.

### 2D field

This function is only for the vector plot of the velocity field in 2D.

```julia
Selafin.PlotField(data)
```

It is also possible to save the current visualization (according to the time step and the layer number) on an image file in .png format.

### 3D

If the bathymetry is present in the data, it is possible to display it in 3D with a possibly user-defined warp coefficient (defaut: `1.`) for a better viewing.

```julia
Selafin.Plot3D(data, 2.)
```

## Getting results

There are three ways to obtain the results: on the whole mesh, on a particular node of the mesh, or from the coordinates of a point. For each of these ways, it is possible to obtain the result(s) for one time step or for all time steps.

### All mesh values

For instance, to get the values for the variable number #1, and for the layer number #3, call the following functions:

```julia
Selafin.Get(data, 1, 2, 3)  # for the time step number #2 only
Selafin.GetAllTime(data, 1, 3)  # for all the time steps
```

### The values of a node

For instance, to get the values on node number #100, and for the variable number #1, call the following functions:

```julia
Selafin.GetNode(data, 100, 1, 2)  # for the time step number #2 only
Selafin.GetAllTime(data, 100, 1)  # for all the time steps
```

### The values of a point

Given the xy-coordinates (50., 60.), in order to get the values for the variable number #1, and for the layer number #3, call the following functions:

```julia
Selafin.GetXY(data, 50., 60., 1, 2, 3)  # for the time step number #2 only
Selafin.GetXYAllTime(data, 50., 60., 1, 3)  # for all the time steps
```

## Analysis

### Basic statistics

The minimum and maximum values as well as the means and medians are provided with the following function:

```julia
Selafin.Statistics(data)
```

### Histogram

It is also possible to interactively visualize the histograms of all variables as a function of time with the command:

```julia
Selafin.Histogram(data)
```

### Extrema

The largest or the smallest values of a single variable can be dynamically selected and displayed. For instance, to show only the top ten values, use the following code:

```julia
Selafin.extrema(data, 10)
```

### Correlation

Time-dependent correlations are computed and plotted by using:

```julia
Selafin.Correlation(data)
```

By saving the image file, a linear regression will also be calculated.

# Appendix

## Mesh quality

The mesh quality is evaluated by calculating an aspect ratio for each 2D triangle:

$\alpha_i = \frac{4  \sqrt(3)  S_i}{l_1^2 + l_2^2 + l_3^2}$

where $S_i$ is the area and $(l_1, l_2, l_3)$ are sides of triangle $i$

An equilateral triangle will have the max aspect ratio of 1