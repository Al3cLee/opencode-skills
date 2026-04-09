---
name: julia-datafitting
description: This skill should be used when working with Julia for data analysis tasks involving CSV file reading, curve fitting (linear and nonlinear), and plotting with CairoMakie. It covers the full Julia scientific computing workflow for physics experiments.
---

# Julia Datafitting

## Overview

Enable data extraction, fitting, and plotting workflows using the Julia toolchain. This skill covers reading CSV files into DataFrames, fitting data to linear and nonlinear models using CurveFit.jl, and creating publication-quality plots with CairoMakie.jl.

## Reading CSV Files

Read CSV files into a DataFrame using CSV.jl and access columns by their header names:

```julia
using CSV, DataFrames

experiment = DataFrame(CSV.File("data.csv"))

# Access columns by header name (trailing spaces after comma may cause issues)
x = experiment."f / Hz"
y = experiment."Vpp / Volt"
```

If all elements from the second row onward are numeric, the returned values automatically become float-valued vectors.

## Nonlinear Curve Fitting

Fit data to nonlinear functions using CurveFit.jl:

```julia
using CSV, DataFrames
using CurveFit

u = [zeros(2)]  # initialize parameter array

# Define fitting target function
# u and x are POSITIONAL arguments
fn(u, x) = @. u[1] / ((1 + 4 * pi^2 * x^2 * u[2]^2)^(0.5))

# Initial parameters
u0 = [0.5, 0.015]

# Generate sample data
experiment = DataFrame(CSV.File("experiment/f-V.csv"))

x = experiment."f / Hz"
y = experiment."Vpp / Volt"

# Create problem with initial guess for parameters
prob = NonlinearCurveFitProblem(fn, u0, x, y)
sol = solve(prob)

# Optionally produce related data
mean_sq_err = mse(sol)
conf_int = confint(sol)

println("Fitted parameters: ", sol.u)
println("mean square error: ", mean_sq_err)
println("confidence interval of 95%: ", conf_int)
```

## Linear Fitting

Fit data to linear functions using CurveFit.jl:

```julia
using CurveFit

# Generate sample data: y = 2.5 * x + 3.0
x = collect(0:0.1:10)
y = @. 2.5 * x + 3.0

# Create the problem and solve
prob = CurveFitProblem(x, y)
sol = solve(prob, LinearCurveFitAlgorithm())

# Access the coefficients: sol.u = (a, b)
println("Slope (a): ", sol.u[1])
println("Intercept (b): ", sol.u[2])

# Evaluate the solution at a point
println("Prediction at x=5: ", sol(5.0))
```

## Plotting with CairoMakie

Create plots using CairoMakie.jl with a 3-level structure (fig - axis - line):

```julia
using CSV, DataFrames
using CairoMakie

x = range(0, 10, length = 100)

# Create the wrapper `fig`
fig = Figure()

# Create an axis with title and labels
ax = Axis(fig[1, 1], title = "Line Plots", xlabel = "X", ylabel = "Y")

# Create a line plot, set color and label
lines!(ax, x, sin.(x), color = :red, label = "sin")

# Add another line plot to the same axis
lines!(ax, x, cos.(x), color = :blue, label = "cos")

# Add a legend at the bottom right with label size 15
# ALWAYS remember to add legends!
axislegend(ax; position = :rb, labelsize = 15)

save("plot_lines6.pdf", fig)
println("sin plot generation success!")
fig
```

Use the `autolimitaspect` argument of `Axis` to tune the ratio between x and y axes when instructed. Always include an axis legend. After plotting, always save to a .pdf file with filename identical to the source .csv name.

## Julia CLI Usage

Execute Julia scripts and commands via CLI:

```bash
# Run a Julia script with the current project
julia --project=. FILE.jl

# Execute code directly in CLI mode using -e flag
julia --project=. -e 'using Pkg; Pkg.add(["CSV","DataFrames","CairoMakie","CurveFit"])'
```

The syntax for non-REPL mode (direct CLI mode) passes a string after the `-e` flag.

## Required Packages

Install necessary packages for data fitting workflows:

```bash
julia --project=. -e 'using Pkg; Pkg.add(["CSV","DataFrames","CairoMakie","CurveFit"])'
```